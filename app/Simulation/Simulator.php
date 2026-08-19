<?php

namespace App\Simulation;

use App\Application\Expeditions\DecideCapturedAnimal;
use App\Application\Expeditions\ExpeditionRejected;
use App\Application\Expeditions\ResolveExpedition;
use App\Application\Expeditions\StartExpedition;
use App\Application\Expeditions\StartExpeditionInput;
use App\Application\Game\ViewGameCatalog;
use App\Application\Players\RegisterPlayer;
use App\Application\Players\RegisterPlayerInput;
use App\Domain\Game\ZooAnimalRepository;
use App\Models\Expedition;
use App\Models\Hunter;
use App\Models\Map;
use App\Simulation\Agents\PlayerAgent;
use App\Simulation\Metrics\RunResult;
use Illuminate\Database\ConnectionInterface;
use Illuminate\Support\Carbon;

/**
 * Plays WildLive without a client.
 *
 * Calls the same Application services the HTTP controllers call —
 * StartExpedition, ResolveExpedition, DecideCapturedAnimal — so what is
 * measured here is the game that ships, not a model of it. No HTTP, no
 * JSON, no UI. Swap the RandomSource for a seeded one and the same seed
 * replays the same playthrough exactly.
 *
 * Time is virtual. `Carbon::setTestNow()` moves the whole application's
 * clock, so an expedition that takes ten real minutes takes no real time
 * here while still being ten minutes as far as every `now()` in the domain
 * is concerned. Nothing about the rules is bypassed: `isDue()` still has to
 * become true before an expedition will resolve.
 *
 * ASSUMPTION, and it matters when reading any number that comes out of
 * this: the agent dispatches again the instant it can. Real players sleep.
 * So elapsed time here is time in the field, and every "how long until X"
 * figure is the optimistic bound — the fastest anyone could reach it while
 * playing perfectly attentively.
 */
final class Simulator
{
    private const MINUTES_PER_DAY = 1440;

    /** Where the virtual clock starts. Fixed, so runs are comparable. */
    private const EPOCH = '2026-01-01 00:00:00';

    public function __construct(
        private readonly ConnectionInterface $db,
        private readonly RegisterPlayer $registerPlayer,
        private readonly ViewGameCatalog $catalog,
        private readonly StartExpedition $startExpedition,
        private readonly ResolveExpedition $resolveExpedition,
        private readonly DecideCapturedAnimal $decideCapture,
        private readonly ZooAnimalRepository $zooAnimals,
    ) {
    }

    /**
     * One agent's playthrough.
     *
     * Everything happens inside a transaction that is always rolled back:
     * a balance run must not leave players, expeditions or zoo animals
     * behind in whatever database it was pointed at.
     */
    public function run(PlayerAgent $agent, int $days, int $seed): RunResult
    {
        $clock = Carbon::parse(self::EPOCH);
        Carbon::setTestNow($clock);

        $this->db->beginTransaction();

        try {
            return $this->play($agent, $days, $seed, $clock);
        } finally {
            $this->db->rollBack();
            Carbon::setTestNow();
        }
    }

    private function play(PlayerAgent $agent, int $days, int $seed, Carbon $clock): RunResult
    {
        $horizon = $days * self::MINUTES_PER_DAY;
        $result = new RunResult($agent->name(), $agent->description(), $seed, $days);

        $registered = ($this->registerPlayer)(new RegisterPlayerInput(
            displayName: sprintf('sim-%s-%d', $agent->name(), $seed),
        ));
        $playerId = $registered->player->id;

        $result->recordBalance(0, (int) $registered->player->g_balance);

        $elapsed = 0;

        while ($elapsed < $horizon) {
            $view = $this->catalogueFor($playerId);
            $balance = $view['balance'];

            $choice = $agent->chooseExpedition($view['maps'], $view['hunters'], $balance);

            if ($choice === null) {
                // Nothing affordable. There is no income in the game yet, so
                // this is terminal rather than a pause — recording it is the
                // whole point of the run.
                $result->recordStuck($elapsed, $balance);
                break;
            }

            try {
                $expedition = ($this->startExpedition)(new StartExpeditionInput(
                    playerId: $playerId,
                    mapId: $choice['map_id'],
                    hunterId: $choice['hunter_id'],
                ));
            } catch (ExpeditionRejected $e) {
                // An agent asked for something the server will not do. That
                // is a finding about the agent or the rules, not a crash.
                $result->recordRejection($e->code());
                break;
            }

            $minutes = (int) $expedition->planned_duration_minutes;
            $elapsed += $minutes;
            $clock = $clock->copy()->addMinutes($minutes)->addSecond();
            Carbon::setTestNow($clock);

            $resolved = ($this->resolveExpedition)($playerId, $expedition->id);
            $result->recordExpedition(
                elapsedMinutes: $elapsed,
                costG: (int) $resolved->total_cost_g,
                mapId: (string) $resolved->map_id,
                durationMinutes: $minutes,
            );

            $this->settle($agent, $playerId, $resolved, $result, $elapsed);

            $result->recordBalance($elapsed, $this->balanceOf($playerId));
            $this->recordProgress($playerId, $result, $elapsed);
        }

        $result->finish(
            elapsedMinutes: min($elapsed, $horizon),
            finalBalance: $this->balanceOf($playerId),
            finalZooValue: $this->zooValueOf($playerId),
        );

        return $result;
    }

    /** Keep or release, if there is anything to decide. */
    private function settle(
        PlayerAgent $agent,
        string $playerId,
        Expedition $resolved,
        RunResult $result,
        int $elapsed,
    ): void {
        if (! $resolved->awaitsDecision()) {
            $result->recordMiss();

            return;
        }

        $animal = $resolved->encounteredAnimal;
        $animal->loadMissing('rarity');
        $species = [
            'id' => $animal->id,
            'name_en' => $animal->name_en,
            'base_zoo_value' => (int) $animal->base_zoo_value,
            'rarity' => [
                'sort_order' => (int) $animal->rarity->sort_order,
                'name_en' => $animal->rarity->name_en,
            ],
        ];

        $result->recordCapture($elapsed, $species);

        $zoo = ['zoo_value' => $this->zooValueOf($playerId)];

        if ($agent->keepsCapture($species, $zoo)) {
            $this->decideCapture->keep($playerId, $resolved->id, null);
            $result->recordKeep($species);
        } else {
            $this->decideCapture->release($playerId, $resolved->id);
            $result->recordRelease($species);
        }
    }

    /**
     * The catalogue as a client would receive it.
     *
     * Only unlocked maps are offered, because a locked one is not a choice
     * a player has. Hunters are re-costed per map, which is what the hunter
     * list does when opened from a map.
     *
     * @return array{balance: int, maps: array<int, array<string, mixed>>, hunters: array<int, array<string, mixed>>}
     */
    private function catalogueFor(string $playerId): array
    {
        $view = $this->catalog->mapsFor($playerId);

        $maps = [];
        $hunters = [];

        foreach ($view['maps'] as $entry) {
            if (! $entry['unlocked']) {
                continue;
            }

            /** @var Map $map */
            $map = $entry['map'];
            $detail = $this->catalog->mapDetailFor($playerId, $map->id);
            $maps[] = $this->shapeMap($detail['map']);

            foreach ($this->catalog->huntersFor($map->id) as $costed) {
                $hunters[] = $this->shapeHunter($costed, $map->id);
            }
        }

        return [
            'balance' => $this->balanceOf($playerId),
            'maps' => $maps,
            'hunters' => $hunters,
        ];
    }

    /** @return array<string, mixed> */
    private function shapeMap(Map $map): array
    {
        $placements = $map->mapAnimals;
        $totalWeight = max(1, (int) $placements->sum('spawn_weight'));

        $spawnTable = $placements->map(fn ($placement) => [
            // The percentage a player reads off the map screen, not the raw
            // weight — an agent must reason from what is shown.
            'spawn_chance_percent' => round(100 * (int) $placement->spawn_weight / $totalWeight, 2),
            'animal' => [
                'id' => $placement->animal->id,
                'base_zoo_value' => (int) $placement->animal->base_zoo_value,
                'rarity' => ['sort_order' => (int) $placement->animal->rarity->sort_order],
            ],
        ])->values()->all();

        return [
            'id' => $map->id,
            'name_en' => $map->name_en,
            'difficulty' => (int) $map->difficulty,
            'expedition_minutes' => (int) $map->expedition_minutes,
            'base_cost_g' => (int) $map->base_cost_g,
            'unlock_value' => (int) $map->unlock_value,
            'spawn_table' => $spawnTable,
        ];
    }

    /**
     * @param  array{hunter: Hunter, biome_affinity: bool, total_cost_g: int|null, duration_minutes: int|null}  $costed
     * @return array<string, mixed>
     */
    private function shapeHunter(array $costed, string $mapId): array
    {
        /** @var Hunter $hunter */
        $hunter = $costed['hunter'];

        return [
            'id' => $hunter->id,
            'name' => $hunter->name,
            'rank' => $hunter->rank,
            'capture_bonus' => (int) $hunter->capture_bonus,
            'rare_find_bonus' => (int) $hunter->rare_find_bonus,
            'speed_bonus' => (int) $hunter->speed_bonus,
            'contract_cost_g' => (int) $hunter->contract_cost_g,
            'for_map' => [
                'map_id' => $mapId,
                'biome_affinity' => $costed['biome_affinity'],
                'total_cost_g' => (int) $costed['total_cost_g'],
                'duration_minutes' => (int) $costed['duration_minutes'],
            ],
        ];
    }

    private function recordProgress(string $playerId, RunResult $result, int $elapsed): void
    {
        $view = $this->catalog->mapsFor($playerId);
        $result->recordZooValue($elapsed, $view['zoo_value']);

        foreach ($view['maps'] as $entry) {
            if ($entry['unlocked']) {
                $result->recordUnlock($entry['map']->id, $entry['map']->name_en, $elapsed);
            }
        }
    }

    private function balanceOf(string $playerId): int
    {
        return (int) $this->db->table('players')->where('id', $playerId)->value('g_balance');
    }

    private function zooValueOf(string $playerId): int
    {
        return $this->catalog->mapsFor($playerId)['zoo_value'];
    }
}
