<?php

namespace App\Application\Expeditions;

use App\Domain\Game\ExpeditionPlanner;
use App\Domain\Game\ExpeditionRepository;
use App\Domain\Game\HunterRepository;
use App\Domain\Game\MapRepository;
use App\Domain\Game\ZooAnimalRepository;
use App\Domain\Players\PlayerRepository;
use App\Models\Expedition;
use Illuminate\Database\ConnectionInterface;

/**
 * Dispatch a Hunter to a Map.
 *
 * This is where the money moves, so the whole thing runs in one
 * transaction over a locked player row: the balance is read, checked, and
 * debited without another dispatch slipping in between.
 *
 * The Hunter is *contracted*, not acquired. Nothing about this use case
 * marks a Hunter as belonging to the player afterwards — the contract
 * exists only as the `hunter_id` + `contract_cost_g` recorded on this one
 * expedition (Game Master v0.3).
 *
 * Costs are sunk at dispatch: whatever happens later, no G comes back.
 */
final class StartExpedition
{
    public function __construct(
        private readonly ConnectionInterface $db,
        private readonly PlayerRepository $players,
        private readonly MapRepository $maps,
        private readonly HunterRepository $hunters,
        private readonly ExpeditionRepository $expeditions,
        private readonly ZooAnimalRepository $zooAnimals,
        private readonly ExpeditionPlanner $planner,
        private readonly DevExpeditionPolicy $devPolicy,
    ) {
    }

    public function __invoke(StartExpeditionInput $input): Expedition
    {
        // Refuse the development shortcut before touching the database:
        // a rejected request must not leave a debited player behind.
        if ($input->devInstantResolve && ! $this->devPolicy->allowsInstantResolve()) {
            throw ExpeditionRejected::because(
                ExpeditionRejected::DEV_RESOLVE_NOT_ALLOWED,
                $this->devPolicy->refusalReason()
            );
        }

        /** @var Expedition $expedition */
        $expedition = $this->db->transaction(function () use ($input): Expedition {
            $player = $this->players->findForUpdate($input->playerId)
                ?? throw ExpeditionRejected::because(
                    ExpeditionRejected::PLAYER_NOT_FOUND,
                    'No such player.'
                );

            $map = $this->maps->find($input->mapId)
                ?? throw ExpeditionRejected::because(
                    ExpeditionRejected::MAP_NOT_FOUND,
                    'No such map.'
                );

            $hunter = $this->hunters->find($input->hunterId)
                ?? throw ExpeditionRejected::because(
                    ExpeditionRejected::HUNTER_NOT_FOUND,
                    'No such hunter.'
                );

            if (! $this->planner->isReleased($map)) {
                throw ExpeditionRejected::because(
                    ExpeditionRejected::MAP_NOT_AVAILABLE,
                    sprintf('%s is not part of the current release.', $map->name_en)
                );
            }

            $zooValue = $this->zooAnimals->zooValue($player->zoo->id);

            if (! $this->planner->isUnlocked($map, $zooValue)) {
                throw ExpeditionRejected::because(
                    ExpeditionRejected::MAP_LOCKED,
                    sprintf(
                        '%s unlocks at Zoo value %d. Your Zoo is worth %d.',
                        $map->name_en,
                        (int) $map->unlock_value,
                        $zooValue
                    )
                );
            }

            $totalCost = $this->planner->totalCostG($map, $hunter);

            if ((int) $player->g_balance < $totalCost) {
                throw ExpeditionRejected::because(
                    ExpeditionRejected::INSUFFICIENT_G,
                    sprintf(
                        'This expedition costs %d G. You have %d G.',
                        $totalCost,
                        (int) $player->g_balance
                    )
                );
            }

            $plannedMinutes = $this->planner->durationMinutes($map, $hunter);

            $startedAt = now();
            // The development shortcut collapses ends_at onto started_at.
            // planned_duration_minutes still records the real timing, so
            // the canonical value is preserved rather than overwritten.
            $endsAt = $input->devInstantResolve
                ? $startedAt->copy()
                : $startedAt->copy()->addMinutes($plannedMinutes);

            $this->players->adjustBalance($player, -$totalCost);

            return $this->expeditions->create([
                'player_id' => $player->id,
                'map_id' => $map->id,
                'hunter_id' => $hunter->id,
                'map_cost_g' => (int) $map->base_cost_g,
                'contract_cost_g' => (int) $hunter->contract_cost_g,
                'total_cost_g' => $totalCost,
                'planned_duration_minutes' => $plannedMinutes,
                'status' => Expedition::STATUS_IN_PROGRESS,
                'dev_instant_resolve' => $input->devInstantResolve,
                'started_at' => $startedAt,
                'ends_at' => $endsAt,
            ]);
        });

        return $expedition;
    }
}
