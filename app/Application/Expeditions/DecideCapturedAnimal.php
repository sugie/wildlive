<?php

namespace App\Application\Expeditions;

use App\Domain\Game\ExpeditionRepository;
use App\Domain\Game\ZooAnimalRepository;
use App\Domain\Players\PlayerRepository;
use App\Models\Expedition;
use Illuminate\Database\ConnectionInterface;
use Illuminate\Support\Str;

/**
 * KEEP or RELEASE a captured animal.
 *
 * KEEP names the animal and puts it in the player's Zoo. RELEASE puts it
 * back and pays nothing — Game Master v0.3 fixes the release reward at
 * 0 G, so there is deliberately no balance movement anywhere in this file.
 *
 * The decision is a one-way door guarded by `decided_at` under a row lock,
 * with UNIQUE(zoo_animals.expedition_id) behind that as the structural
 * backstop. Re-sending the same decision is treated as a retry and returns
 * the existing state; sending the *other* decision after the fact is a
 * conflict, because by then the animal is either in a Zoo or gone.
 */
final class DecideCapturedAnimal
{
    public function __construct(
        private readonly ConnectionInterface $db,
        private readonly ExpeditionRepository $expeditions,
        private readonly ZooAnimalRepository $zooAnimals,
        private readonly PlayerRepository $players,
    ) {
    }

    /**
     * @param  string|null  $name  player-chosen nickname; blank falls back
     *                             to the species' English name
     */
    public function keep(string $playerId, string $expeditionId, ?string $name): Expedition
    {
        return $this->decide($playerId, $expeditionId, Expedition::DECISION_KEPT, $name);
    }

    public function release(string $playerId, string $expeditionId): Expedition
    {
        return $this->decide($playerId, $expeditionId, Expedition::DECISION_RELEASED, null);
    }

    private function decide(
        string $playerId,
        string $expeditionId,
        string $decision,
        ?string $name,
    ): Expedition {
        /** @var Expedition $decided */
        $decided = $this->db->transaction(function () use ($playerId, $expeditionId, $decision, $name): Expedition {
            $expedition = $this->expeditions->findForUpdate($expeditionId);

            if ($expedition === null || $expedition->player_id !== $playerId) {
                throw ExpeditionRejected::because(
                    ExpeditionRejected::EXPEDITION_NOT_FOUND,
                    'No such expedition.'
                );
            }

            if (! $expedition->isResolved()) {
                throw ExpeditionRejected::because(
                    ExpeditionRejected::NOT_RESOLVED,
                    'This expedition has not been resolved yet.'
                );
            }

            if ($expedition->outcome !== Expedition::OUTCOME_CAPTURED) {
                throw ExpeditionRejected::because(
                    ExpeditionRejected::NOTHING_TO_DECIDE,
                    'This expedition returned without a capture.'
                );
            }

            if ($expedition->isDecided()) {
                // A retry of the same decision is fine; changing your mind
                // after the fact is not.
                if ($expedition->decision === $decision) {
                    return $expedition;
                }

                throw ExpeditionRejected::because(
                    ExpeditionRejected::ALREADY_DECIDED,
                    sprintf('This capture was already %s.', $expedition->decision)
                );
            }

            if ($decision === Expedition::DECISION_KEPT) {
                $player = $this->players->findForUpdate($playerId)
                    ?? throw ExpeditionRejected::because(
                        ExpeditionRejected::PLAYER_NOT_FOUND,
                        'No such player.'
                    );

                $this->zooAnimals->createFromCapture(
                    $player->zoo,
                    $expedition,
                    $this->resolveName($name, $expedition)
                );
            }

            $expedition->decision = $decision;
            $expedition->decided_at = now();

            return $this->expeditions->save($expedition);
        });

        return $decided;
    }

    /**
     * An animal always ends up with a name. If the player left the field
     * blank, the species' own English name is a better zoo label than an
     * empty string or "(unnamed)".
     */
    private function resolveName(?string $name, Expedition $expedition): string
    {
        $trimmed = trim((string) $name);

        if ($trimmed === '') {
            $trimmed = (string) $expedition->encounteredAnimal?->name_en;
        }

        if ($trimmed === '') {
            $trimmed = 'Unnamed';
        }

        return Str::limit($trimmed, 64, '');
    }
}
