<?php

namespace Database\Seeders;

use App\Models\Animal;
use App\Models\Biome;
use App\Models\Hunter;
use App\Models\Map;
use App\Models\MapAnimal;
use App\Models\Rarity;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Loads Game Master v0.3 into PostgreSQL.
 *
 * This is the only writer of the master-data tables, and it reads exactly
 * one file: database/master/game-master-v0.3.json, generated from the
 * canonical Python source by docs/game-design/export_master_json.py.
 *
 * The .xlsx workbook is never opened — not here, not anywhere at runtime.
 * It is a human review artifact built from the same Python source.
 *
 * Idempotent: rows are upserted by their Game Master id, so re-running the
 * seeder after a master-data change updates existing rows in place and
 * leaves players' expeditions and zoo animals (which reference these ids)
 * intact. Nothing is deleted — removing a species that a player already
 * owns is a migration decision, not a seeding one.
 */
class GameMasterSeeder extends Seeder
{
    public function run(): void
    {
        $master = $this->loadMasterData();

        DB::transaction(function () use ($master) {
            $this->seedBiomes($master['biomes']);
            $this->seedRarities($master['rarities']);
            $this->seedAnimals($master['animals']);
            $this->seedHunters($master['hunters']);
            $this->seedMaps($master['maps']);
            $this->seedMapAnimals($master['map_animals']);
        });

        $this->command?->info(sprintf(
            'Game Master %s seeded: %d biomes, %d rarities, %d animals, %d hunters, %d maps, %d spawn rows.',
            $master['master_version'],
            count($master['biomes']),
            count($master['rarities']),
            count($master['animals']),
            count($master['hunters']),
            count($master['maps']),
            count($master['map_animals']),
        ));
    }

    /** @return array<string, mixed> */
    private function loadMasterData(): array
    {
        $path = (string) config('wildlive.master_data_path');

        if (! is_file($path)) {
            throw new RuntimeException(
                "Game Master runtime data not found at {$path}. "
                .'Generate it with: python3 docs/game-design/export_master_json.py'
            );
        }

        $decoded = json_decode((string) file_get_contents($path), true, flags: JSON_THROW_ON_ERROR);

        if (! is_array($decoded)) {
            throw new RuntimeException("Game Master runtime data at {$path} is not a JSON object.");
        }

        foreach (['master_version', 'biomes', 'rarities', 'animals', 'hunters', 'maps', 'map_animals'] as $key) {
            if (! array_key_exists($key, $decoded)) {
                throw new RuntimeException("Game Master runtime data at {$path} is missing '{$key}'.");
            }
        }

        return $decoded;
    }

    /** @param array<int, array<string, mixed>> $rows */
    private function seedBiomes(array $rows): void
    {
        Biome::query()->upsert(
            array_map(fn (array $r) => [
                'id' => $r['biome_id'],
                'name_en' => $r['name_en'],
                'name_ja' => $r['name_ja'],
                'description_en' => $r['description_en'],
                'description_ja' => $r['description_ja'],
            ], $rows),
            ['id'],
            ['name_en', 'name_ja', 'description_en', 'description_ja'],
        );
    }

    /** @param array<int, array<string, mixed>> $rows */
    private function seedRarities(array $rows): void
    {
        Rarity::query()->upsert(
            array_map(fn (array $r) => [
                'id' => $r['rarity_id'],
                'name_en' => $r['name_en'],
                'name_ja' => $r['name_ja'],
                'sort_order' => (int) $r['sort_order'],
                'base_multiplier' => (float) $r['base_multiplier'],
                'description' => $r['description'],
            ], $rows),
            ['id'],
            ['name_en', 'name_ja', 'sort_order', 'base_multiplier', 'description'],
        );
    }

    /** @param array<int, array<string, mixed>> $rows */
    private function seedAnimals(array $rows): void
    {
        Animal::query()->upsert(
            array_map(fn (array $r) => [
                'id' => $r['animal_id'],
                'name_en' => $r['name_en'],
                'name_ja' => $r['name_ja'],
                'category' => $r['category'],
                'rarity_id' => $r['rarity_id'],
                'availability_phase' => $r['availability_phase'],
                'placement_note' => $r['placement_note'],
                'base_zoo_value' => (int) $r['base_zoo_value'],
                'capture_difficulty' => (int) $r['capture_difficulty'],
                'growth_rate' => (int) $r['growth_rate'],
                'visitor_appeal' => (int) $r['visitor_appeal'],
                'habitat_biome_id' => $r['habitat_biome_id'],
                'size' => $r['size'],
                'active_time' => $r['active_time'],
                'description_en' => $r['description_en'],
                'description_ja' => $r['description_ja'],
            ], $rows),
            ['id'],
            [
                'name_en', 'name_ja', 'category', 'rarity_id', 'availability_phase',
                'placement_note', 'base_zoo_value', 'capture_difficulty', 'growth_rate',
                'visitor_appeal', 'habitat_biome_id', 'size', 'active_time',
                'description_en', 'description_ja',
            ],
        );
    }

    /** @param array<int, array<string, mixed>> $rows */
    private function seedHunters(array $rows): void
    {
        Hunter::query()->upsert(
            array_map(fn (array $r) => [
                'id' => $r['hunter_id'],
                'name' => $r['name'],
                'name_ja' => $r['name_ja'],
                'rank' => $r['rank'],
                'level' => (int) $r['level'],
                'specialty' => $r['specialty'],
                'preferred_biome_id' => $r['preferred_biome_id'],
                'capture_bonus' => (int) $r['capture_bonus'],
                'rare_find_bonus' => (int) $r['rare_find_bonus'],
                'speed_bonus' => (int) $r['speed_bonus'],
                'contract_cost_g' => (int) $r['contract_cost_g'],
                'personality' => $r['personality'],
                'description' => $r['description'],
            ], $rows),
            ['id'],
            [
                'name', 'name_ja', 'rank', 'level', 'specialty', 'preferred_biome_id',
                'capture_bonus', 'rare_find_bonus', 'speed_bonus', 'contract_cost_g',
                'personality', 'description',
            ],
        );
    }

    /** @param array<int, array<string, mixed>> $rows */
    private function seedMaps(array $rows): void
    {
        Map::query()->upsert(
            array_map(fn (array $r) => [
                'id' => $r['map_id'],
                'name_en' => $r['name_en'],
                'name_ja' => $r['name_ja'],
                'region' => $r['region'],
                'biome_id' => $r['biome_id'],
                'availability_phase' => $r['availability_phase'],
                'map_role' => $r['map_role'],
                'unlock_rule' => $r['unlock_rule'],
                'unlock_value' => (int) $r['unlock_value'],
                'recommended_hunter_rank' => (int) $r['recommended_hunter_rank'],
                'minimum_hunter_rank_gate' => (int) $r['minimum_hunter_rank_gate'],
                'difficulty' => (int) $r['difficulty'],
                'expedition_minutes' => (int) $r['expedition_minutes'],
                'base_cost_g' => (int) $r['base_cost_g'],
                'risk_level' => (int) $r['risk_level'],
                'description_en' => $r['description_en'],
                'description_ja' => $r['description_ja'],
            ], $rows),
            ['id'],
            [
                'name_en', 'name_ja', 'region', 'biome_id', 'availability_phase',
                'map_role', 'unlock_rule', 'unlock_value', 'recommended_hunter_rank',
                'minimum_hunter_rank_gate', 'difficulty', 'expedition_minutes',
                'base_cost_g', 'risk_level', 'description_en', 'description_ja',
            ],
        );
    }

    /** @param array<int, array<string, mixed>> $rows */
    private function seedMapAnimals(array $rows): void
    {
        MapAnimal::query()->upsert(
            array_map(fn (array $r) => [
                'id' => $r['map_animal_id'],
                'map_id' => $r['map_id'],
                'animal_id' => $r['animal_id'],
                'spawn_weight' => (int) $r['spawn_weight'],
                'capture_modifier' => (int) $r['capture_modifier'],
                'needs_review' => (bool) $r['needs_review'],
                'notes' => $r['notes'],
            ], $rows),
            ['id'],
            ['map_id', 'animal_id', 'spawn_weight', 'capture_modifier', 'needs_review', 'notes'],
        );
    }
}
