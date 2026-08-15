<?php

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Game\HunterRepository;
use App\Models\Hunter;
use Illuminate\Support\Collection;

final class EloquentHunterRepository implements HunterRepository
{
    public function all(): Collection
    {
        // Cheapest first: the contract cost is the decision a player is
        // actually making at the Guild.
        return Hunter::query()
            ->orderBy('contract_cost_g')
            ->orderBy('id')
            ->get();
    }

    public function find(string $hunterId): ?Hunter
    {
        return Hunter::query()->find($hunterId);
    }
}
