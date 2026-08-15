<?php

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Game\MapRepository;
use App\Models\Map;
use Illuminate\Support\Collection;

final class EloquentMapRepository implements MapRepository
{
    public function released(): Collection
    {
        return Map::query()
            ->where('availability_phase', 'initial_africa')
            // Cheapest first, then by unlock threshold: this is the order a
            // player actually progresses through them, so the client can
            // render the list without re-sorting.
            ->orderBy('unlock_value')
            ->orderBy('base_cost_g')
            ->orderBy('id')
            ->get();
    }

    public function find(string $mapId): ?Map
    {
        return Map::query()->find($mapId);
    }

    public function findWithSpawnTable(string $mapId): ?Map
    {
        return Map::query()
            ->with(['mapAnimals' => fn ($q) => $q->orderByDesc('spawn_weight')->orderBy('id'),
                    'mapAnimals.animal.rarity'])
            ->find($mapId);
    }
}
