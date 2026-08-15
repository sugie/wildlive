<?php

namespace Tests\Unit\Domain\Game;

use App\Models\Animal;
use App\Models\Hunter;
use App\Models\Map;
use App\Models\MapAnimal;
use App\Models\Rarity;

/**
 * Hand-built master-data rows for the domain unit tests.
 *
 * Eloquent models are used as plain typed containers here: no connection
 * is ever opened, nothing is saved, and relations are wired by hand with
 * setRelation(). That keeps these tests free of the database while still
 * exercising the exact objects the production code receives.
 *
 * Values default to real Game Master v0.3 rows (Kenyan Savanna, Impala,
 * Amara Koné) so a failing assertion can be checked against the workbook.
 */
trait GameMasterFixtures
{
    protected function rarity(string $id, int $sortOrder): Rarity
    {
        return new Rarity([
            'id' => $id,
            'name_en' => ucfirst(str_replace('rarity_', '', $id)),
            'name_ja' => $id,
            'sort_order' => $sortOrder,
            'base_multiplier' => 1.0,
        ]);
    }

    protected function animal(
        string $id = 'animal_impala_001',
        int $captureDifficulty = 1,
        int $raritySortOrder = 1,
        int $baseZooValue = 10,
    ): Animal {
        $animal = new Animal([
            'id' => $id,
            'name_en' => 'Test Animal',
            'name_ja' => 'テスト',
            'rarity_id' => 'rarity_test_'.$raritySortOrder,
            'availability_phase' => 'initial_africa',
            'base_zoo_value' => $baseZooValue,
            'capture_difficulty' => $captureDifficulty,
            'habitat_biome_id' => 'biome_savanna',
        ]);
        $animal->setRelation('rarity', $this->rarity('rarity_test_'.$raritySortOrder, $raritySortOrder));

        return $animal;
    }

    protected function placement(
        string $id,
        Animal $animal,
        int $spawnWeight,
        int $captureModifier = 0,
    ): MapAnimal {
        $placement = new MapAnimal([
            'id' => $id,
            'map_id' => 'map_test_001',
            'animal_id' => $animal->id,
            'spawn_weight' => $spawnWeight,
            'capture_modifier' => $captureModifier,
        ]);
        $placement->setRelation('animal', $animal);

        return $placement;
    }

    protected function map(
        int $difficulty = 1,
        int $expeditionMinutes = 10,
        int $baseCostG = 50,
        string $biomeId = 'biome_savanna',
        string $unlockRule = 'always',
        int $unlockValue = 0,
        string $availabilityPhase = 'initial_africa',
    ): Map {
        return new Map([
            'id' => 'map_test_001',
            'name_en' => 'Test Map',
            'name_ja' => 'テストマップ',
            'region' => 'East Africa',
            'biome_id' => $biomeId,
            'availability_phase' => $availabilityPhase,
            'map_role' => 'starter',
            'unlock_rule' => $unlockRule,
            'unlock_value' => $unlockValue,
            'difficulty' => $difficulty,
            'expedition_minutes' => $expeditionMinutes,
            'base_cost_g' => $baseCostG,
            'risk_level' => 1,
        ]);
    }

    protected function hunter(
        int $captureBonus = 0,
        int $rareFindBonus = 0,
        int $speedBonus = 0,
        int $contractCostG = 50,
        string $preferredBiomeId = 'biome_savanna',
    ): Hunter {
        return new Hunter([
            'id' => 'hunter_test_001',
            'name' => 'Test Hunter',
            'name_ja' => 'テスト',
            'rank' => 'Bronze',
            'level' => 1,
            'specialty' => 'Test',
            'preferred_biome_id' => $preferredBiomeId,
            'capture_bonus' => $captureBonus,
            'rare_find_bonus' => $rareFindBonus,
            'speed_bonus' => $speedBonus,
            'contract_cost_g' => $contractCostG,
        ]);
    }
}
