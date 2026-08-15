<?php

namespace App\Application\Expeditions;

use App\Domain\Game\ExpeditionRepository;
use App\Models\Expedition;
use Illuminate\Support\Collection;

/**
 * Read-side view of a player's expeditions.
 *
 * Fetching a single expedition resolves it first when it is due — the
 * lazy resolution docs/ARCHITECTURE.md describes ("resolved on player
 * request"). ResolveExpedition is idempotent, so this stays safe no matter
 * how often the client polls.
 *
 * The list deliberately does NOT resolve: a read of many rows should not
 * fan out into many writes. Expeditions that are due show up as "ready",
 * and opening one settles it.
 */
final class ViewExpeditions
{
    public function __construct(
        private readonly ExpeditionRepository $expeditions,
        private readonly ResolveExpedition $resolve,
    ) {
    }

    /** @return Collection<int, Expedition> */
    public function forPlayer(string $playerId): Collection
    {
        return $this->expeditions->forPlayer($playerId);
    }

    public function one(string $playerId, string $expeditionId): Expedition
    {
        $expedition = $this->expeditions->find($expeditionId);

        if ($expedition === null || $expedition->player_id !== $playerId) {
            throw ExpeditionRejected::because(
                ExpeditionRejected::EXPEDITION_NOT_FOUND,
                'No such expedition.'
            );
        }

        if (! $expedition->isResolved() && $expedition->isDue()) {
            return ($this->resolve)($playerId, $expeditionId);
        }

        return $expedition;
    }
}
