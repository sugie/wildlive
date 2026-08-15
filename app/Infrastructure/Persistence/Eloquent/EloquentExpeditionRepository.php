<?php

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Game\ExpeditionRepository;
use App\Models\Expedition;
use Illuminate\Support\Collection;

final class EloquentExpeditionRepository implements ExpeditionRepository
{
    /** Relations every caller needs to render an expedition. */
    private const WITH = ['map', 'hunter', 'encounteredAnimal.rarity', 'zooAnimal'];

    public function create(array $attributes): Expedition
    {
        $expedition = Expedition::create($attributes);

        return $expedition->load(self::WITH);
    }

    public function find(string $expeditionId): ?Expedition
    {
        return Expedition::query()->with(self::WITH)->find($expeditionId);
    }

    public function findForUpdate(string $expeditionId): ?Expedition
    {
        $expedition = Expedition::query()->lockForUpdate()->find($expeditionId);

        return $expedition?->load(self::WITH);
    }

    public function forPlayer(string $playerId, int $limit = 50): Collection
    {
        return Expedition::query()
            ->with(self::WITH)
            ->where('player_id', $playerId)
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->limit($limit)
            ->get();
    }

    public function save(Expedition $expedition): Expedition
    {
        $expedition->save();

        return $expedition->load(self::WITH);
    }
}
