<?php

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Game\ZooAnimalRepository;
use App\Models\Expedition;
use App\Models\Zoo;
use App\Models\ZooAnimal;
use Illuminate\Support\Collection;

final class EloquentZooAnimalRepository implements ZooAnimalRepository
{
    public function createFromCapture(Zoo $zoo, Expedition $expedition, string $name): ZooAnimal
    {
        $animal = ZooAnimal::create([
            'zoo_id' => $zoo->id,
            'animal_id' => $expedition->encountered_animal_id,
            'name' => $name,
            'expedition_id' => $expedition->id,
            'captured_from_map_id' => $expedition->map_id,
            'captured_by_hunter_id' => $expedition->hunter_id,
            'captured_at' => $expedition->resolved_at ?? now(),
        ]);

        return $animal->load('animal.rarity');
    }

    public function forZoo(string $zooId): Collection
    {
        return ZooAnimal::query()
            ->with('animal.rarity')
            ->where('zoo_id', $zooId)
            ->orderByDesc('captured_at')
            ->orderByDesc('id')
            ->get();
    }

    public function zooValue(string $zooId): int
    {
        return (int) ZooAnimal::query()
            ->where('zoo_animals.zoo_id', $zooId)
            ->join('animals', 'animals.id', '=', 'zoo_animals.animal_id')
            ->sum('animals.base_zoo_value');
    }
}
