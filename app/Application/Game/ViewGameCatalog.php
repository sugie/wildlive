<?php

namespace App\Application\Game;

use App\Application\Expeditions\ExpeditionRejected;
use App\Domain\Game\ExpeditionPlanner;
use App\Domain\Game\HunterRepository;
use App\Domain\Game\MapRepository;
use App\Domain\Game\ZooAnimalRepository;
use App\Domain\Players\PlayerRepository;
use App\Models\Hunter;
use App\Models\Map;
use Illuminate\Support\Collection;

/**
 * Read-side view of the Game Master catalogue: which Maps a player may
 * enter, what lives on them, and who the Guild has available.
 *
 * Map availability is computed here rather than stored, because it is a
 * function of the player's current Zoo value and changes the moment an
 * animal is added.
 *
 * Hunters are returned to everyone, unfiltered: the Guild pool is shared
 * and a Hunter is never owned by a player (Game Master v0.3).
 */
final class ViewGameCatalog
{
    public function __construct(
        private readonly MapRepository $maps,
        private readonly HunterRepository $hunters,
        private readonly PlayerRepository $players,
        private readonly ZooAnimalRepository $zooAnimals,
        private readonly ExpeditionPlanner $planner,
    ) {
    }

    /**
     * Every released Map, each flagged with whether this player has met
     * its unlock condition. Locked maps are returned too — a player should
     * be able to see what they are working toward.
     *
     * @return array{zoo_value: int, maps: array<int, array{map: Map, unlocked: bool}>}
     */
    public function mapsFor(string $playerId): array
    {
        $zooValue = $this->zooValueFor($playerId);

        $maps = $this->maps->released()
            ->map(fn (Map $map) => [
                'map' => $map,
                'unlocked' => $this->planner->isUnlocked($map, $zooValue),
            ])
            ->all();

        return ['zoo_value' => $zooValue, 'maps' => $maps];
    }

    /**
     * One Map with the full list of animals that can appear on it.
     *
     * @return array{map: Map, unlocked: bool, zoo_value: int}
     */
    public function mapDetailFor(string $playerId, string $mapId): array
    {
        $map = $this->maps->findWithSpawnTable($mapId)
            ?? throw ExpeditionRejected::because(
                ExpeditionRejected::MAP_NOT_FOUND,
                'No such map.'
            );

        if (! $this->planner->isReleased($map)) {
            throw ExpeditionRejected::because(
                ExpeditionRejected::MAP_NOT_AVAILABLE,
                sprintf('%s is not part of the current release.', $map->name_en)
            );
        }

        $zooValue = $this->zooValueFor($playerId);

        return [
            'map' => $map,
            'unlocked' => $this->planner->isUnlocked($map, $zooValue),
            'zoo_value' => $zooValue,
        ];
    }

    /**
     * The Guild pool, each Hunter annotated with what they would cost and
     * how long they would take on the given Map (when one is supplied).
     *
     * @return array<int, array{hunter: Hunter, biome_affinity: bool, total_cost_g: int|null, duration_minutes: int|null}>
     */
    public function huntersFor(?string $mapId = null): array
    {
        $map = $mapId === null ? null : $this->maps->find($mapId);

        if ($mapId !== null && $map === null) {
            throw ExpeditionRejected::because(
                ExpeditionRejected::MAP_NOT_FOUND,
                'No such map.'
            );
        }

        return $this->hunters->all()
            ->map(fn (Hunter $hunter) => [
                'hunter' => $hunter,
                'biome_affinity' => $map !== null && $this->planner->hasBiomeAffinity($map, $hunter),
                'total_cost_g' => $map === null ? null : $this->planner->totalCostG($map, $hunter),
                'duration_minutes' => $map === null ? null : $this->planner->durationMinutes($map, $hunter),
            ])
            ->all();
    }

    private function zooValueFor(string $playerId): int
    {
        $player = $this->players->find($playerId)
            ?? throw ExpeditionRejected::because(
                ExpeditionRejected::PLAYER_NOT_FOUND,
                'No such player.'
            );

        return $this->zooAnimals->zooValue($player->zoo->id);
    }
}
