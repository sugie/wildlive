<?php

namespace App\Domain\Game;

use App\Models\Expedition;
use Illuminate\Support\Collection;

interface ExpeditionRepository
{
    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes): Expedition;

    public function find(string $expeditionId): ?Expedition;

    /**
     * Load an expedition with a row lock (SELECT … FOR UPDATE).
     *
     * Required for resolve / keep / release: the transition guards read
     * `resolved_at` and `decided_at` and then write them, so two
     * simultaneous calls must not both observe NULL. Callers must already
     * be inside a transaction.
     */
    public function findForUpdate(string $expeditionId): ?Expedition;

    /**
     * Most recent first.
     *
     * @return Collection<int, Expedition>
     */
    public function forPlayer(string $playerId, int $limit = 50): Collection;

    public function save(Expedition $expedition): Expedition;
}
