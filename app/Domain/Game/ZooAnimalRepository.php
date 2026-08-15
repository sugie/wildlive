<?php

namespace App\Domain\Game;

use App\Models\Expedition;
use App\Models\Zoo;
use App\Models\ZooAnimal;
use Illuminate\Support\Collection;

interface ZooAnimalRepository
{
    /**
     * Add the animal an expedition captured to the player's Zoo.
     *
     * The expedition supplies the species and the provenance (map, hunter,
     * time), so a caller cannot conjure an animal that no expedition
     * produced.
     */
    public function createFromCapture(Zoo $zoo, Expedition $expedition, string $name): ZooAnimal;

    /**
     * Most recent first, with species + rarity eager-loaded.
     *
     * @return Collection<int, ZooAnimal>
     */
    public function forZoo(string $zooId): Collection;

    /**
     * The Zoo's total value: the sum of its animals' Animal.base_zoo_value.
     *
     * This is the number Map.unlock_rule = zoo_value compares against.
     * Rarity.base_multiplier is deliberately NOT applied — base_zoo_value
     * is already rarity-scaled in Game Master v0.3, and stacking the two
     * would be an economy decision the workbook has not made.
     */
    public function zooValue(string $zooId): int;
}
