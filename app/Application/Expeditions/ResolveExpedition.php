<?php

namespace App\Application\Expeditions;

use App\Domain\Game\CaptureResolver;
use App\Domain\Game\EncounterTable;
use App\Domain\Game\ExpeditionRepository;
use App\Domain\Game\HunterRepository;
use App\Domain\Game\MapRepository;
use App\Models\Expedition;
use Illuminate\Database\ConnectionInterface;

/**
 * Compute an expedition's outcome.
 *
 * Two steps, in this order and independent of each other:
 *
 *   1. EncounterTable draws WHAT the Hunter found, from the Map's spawn
 *      table, biased by the Hunter's rare_find_bonus.
 *   2. CaptureResolver decides WHETHER it was caught — a calculation in
 *      which rare_find_bonus plays no part at all.
 *
 * Idempotent by construction: the expedition row is locked, `resolved_at`
 * is the guard, and a second call returns the first call's result without
 * re-rolling. That matters because the client resolves lazily on view as
 * well as through the explicit command, so double resolution is normal
 * traffic, not an edge case.
 *
 * A failed capture still records what was encountered. The player deserves
 * to know the lion was there.
 */
final class ResolveExpedition
{
    public function __construct(
        private readonly ConnectionInterface $db,
        private readonly ExpeditionRepository $expeditions,
        private readonly MapRepository $maps,
        private readonly HunterRepository $hunters,
        private readonly EncounterTable $encounters,
        private readonly CaptureResolver $captures,
    ) {
    }

    /**
     * @param  string  $playerId  owner check — an expedition may only be
     *                            resolved by the player who dispatched it
     */
    public function __invoke(string $playerId, string $expeditionId): Expedition
    {
        /** @var Expedition $resolved */
        $resolved = $this->db->transaction(function () use ($playerId, $expeditionId): Expedition {
            $expedition = $this->expeditions->findForUpdate($expeditionId);

            if ($expedition === null || $expedition->player_id !== $playerId) {
                throw ExpeditionRejected::because(
                    ExpeditionRejected::EXPEDITION_NOT_FOUND,
                    'No such expedition.'
                );
            }

            if ($expedition->isResolved()) {
                return $expedition;
            }

            if (! $expedition->isDue()) {
                throw ExpeditionRejected::because(
                    ExpeditionRejected::NOT_DUE,
                    sprintf(
                        'This expedition is still out. It returns at %s.',
                        $expedition->ends_at->toISOString()
                    )
                );
            }

            $map = $this->maps->findWithSpawnTable($expedition->map_id)
                ?? throw ExpeditionRejected::because(
                    ExpeditionRejected::MAP_NOT_FOUND,
                    'The map this expedition was sent to no longer exists.'
                );

            $hunter = $this->hunters->find($expedition->hunter_id)
                ?? throw ExpeditionRejected::because(
                    ExpeditionRejected::HUNTER_NOT_FOUND,
                    'The hunter this expedition contracted no longer exists.'
                );

            $candidates = $map->mapAnimals
                ->filter(fn ($placement) => (int) $placement->spawn_weight > 0)
                ->values()
                ->all();

            if ($candidates === []) {
                throw ExpeditionRejected::because(
                    ExpeditionRejected::EMPTY_SPAWN_TABLE,
                    sprintf('%s has no animals that can be encountered.', $map->name_en)
                );
            }

            $encounter = $this->encounters->draw($candidates, (int) $hunter->rare_find_bonus);
            $placement = $encounter['candidate'];

            $attempt = $this->captures->attempt($map, $hunter, $placement);

            $expedition->status = Expedition::STATUS_RESOLVED;
            $expedition->outcome = $attempt['captured']
                ? Expedition::OUTCOME_CAPTURED
                : Expedition::OUTCOME_NO_CAPTURE;
            $expedition->encountered_animal_id = $placement->animal_id;
            $expedition->encounter_roll = $encounter['roll'];
            $expedition->capture_chance_percent = $attempt['chance_percent'];
            $expedition->capture_roll = $attempt['roll'];
            $expedition->resolved_at = now();

            return $this->expeditions->save($expedition);
        });

        return $resolved;
    }
}
