<?php

namespace Tests\Feature;

use App\Models\Animal;
use App\Models\Hunter;
use App\Models\Map;
use App\Models\MapAnimal;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Feature\Concerns\PlaysWildLive;
use Tests\TestCase;

/**
 * Guards the source-to-runtime path for game master data.
 *
 *   build_master_v0_3.py  →  game-master-v0.3.json  →  seeder  →  PostgreSQL
 *
 * The JSON-vs-Python half of that chain is checked in CI by
 * `export_master_json.py --check`. This file checks the second half: that
 * what the seeder puts in PostgreSQL is exactly what the JSON says, and
 * that the Game Master's structural rules survived the trip.
 */
class GameMasterDataTest extends TestCase
{
    use RefreshDatabase;
    use PlaysWildLive;

    /** @var array<string, mixed> */
    private array $master;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedGameMaster();
        $this->master = json_decode(
            (string) file_get_contents((string) config('wildlive.master_data_path')),
            true,
            flags: JSON_THROW_ON_ERROR
        );
    }

    public function test_the_runtime_file_is_the_v0_3_master(): void
    {
        $this->assertSame('v0.3', $this->master['master_version']);
        $this->assertSame('docs/game-design/build_master_v0_3.py', $this->master['generated_from']);
    }

    public function test_every_json_row_reached_postgresql(): void
    {
        $this->assertSame(count($this->master['maps']), Map::query()->count());
        $this->assertSame(count($this->master['animals']), Animal::query()->count());
        $this->assertSame(count($this->master['hunters']), Hunter::query()->count());
        $this->assertSame(count($this->master['map_animals']), MapAnimal::query()->count());
    }

    public function test_seeding_twice_updates_in_place_rather_than_duplicating(): void
    {
        $before = MapAnimal::query()->count();

        $this->seedGameMaster();

        $this->assertSame($before, MapAnimal::query()->count(),
            'the seeder upserts by Game Master id, so it is safe to re-run');
    }

    public function test_ids_are_the_game_master_ids_verbatim(): void
    {
        // The whole point of using the workbook's own identifiers as
        // primary keys: a row can be traced by eye from spreadsheet to
        // database without a lookup table.
        $this->assertNotNull(Map::query()->find('map_kenyan_savanna_001'));
        $this->assertNotNull(Animal::query()->find('animal_impala_001'));
        $this->assertNotNull(Hunter::query()->find('hunter_susumu_019'));
    }

    public function test_africa_first_release_is_nine_maps(): void
    {
        $this->assertSame(9, Map::query()->where('availability_phase', 'initial_africa')->count());
        $this->assertSame(6, Map::query()->where('availability_phase', 'future_expansion')->count());
    }

    public function test_five_rarity_tiers_in_order(): void
    {
        $tiers = \App\Models\Rarity::query()->orderBy('sort_order')->pluck('name_en')->all();

        $this->assertSame(['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'], $tiers);
    }

    public function test_northern_white_rhinoceros_has_no_spawn_row(): void
    {
        // Game Master v0.3 keeps it as a special_event animal. The rule is
        // enforced structurally: with no MapAnimals row it cannot be drawn
        // by EncounterTable on any map, ever.
        $this->assertNotNull(
            Animal::query()->find('animal_northern_white_rhino_039'),
            'the species exists in the master data'
        );
        $this->assertSame(
            0,
            MapAnimal::query()->where('animal_id', 'animal_northern_white_rhino_039')->count(),
            'but it is not spawnable anywhere'
        );
    }

    public function test_no_future_region_animal_is_placed_on_an_african_map(): void
    {
        $offenders = MapAnimal::query()
            ->join('animals', 'animals.id', '=', 'map_animals.animal_id')
            ->join('maps', 'maps.id', '=', 'map_animals.map_id')
            ->where('animals.availability_phase', 'future_region')
            ->where('maps.availability_phase', 'initial_africa')
            ->pluck('map_animals.id')
            ->all();

        $this->assertSame([], $offenders,
            'real-habitat rule: a species may only appear where it really lives');
    }

    public function test_every_released_map_has_something_to_find(): void
    {
        $maps = Map::query()->where('availability_phase', 'initial_africa')->get();

        foreach ($maps as $map) {
            $this->assertGreaterThan(
                0,
                MapAnimal::query()->where('map_id', $map->id)->sum('spawn_weight'),
                "{$map->id} must have at least one animal with positive spawn weight"
            );
        }
    }

    public function test_the_guild_has_a_desert_specialist(): void
    {
        // v0.3 added Susumu specifically because v0.2 had a desert map and
        // no desert Hunter.
        $desert = Hunter::query()->where('preferred_biome_id', 'biome_desert')->get();

        $this->assertGreaterThanOrEqual(1, $desert->count());
        $this->assertTrue($desert->contains('id', 'hunter_susumu_019'));
    }

    public function test_hunter_bonus_ranges_match_the_hunter_skills_sheet(): void
    {
        // HunterSkills bounds every bonus to [-20, +30].
        foreach (Hunter::query()->get() as $hunter) {
            foreach (['capture_bonus', 'rare_find_bonus', 'speed_bonus'] as $field) {
                $this->assertGreaterThanOrEqual(-20, (int) $hunter->{$field}, "{$hunter->id}.{$field}");
                $this->assertLessThanOrEqual(30, (int) $hunter->{$field}, "{$hunter->id}.{$field}");
            }
        }
    }

    public function test_expedition_minutes_stay_within_the_game_master_bounds(): void
    {
        foreach (Map::query()->get() as $map) {
            $this->assertGreaterThanOrEqual(5, (int) $map->expedition_minutes, $map->id);
            $this->assertLessThanOrEqual(1440, (int) $map->expedition_minutes, $map->id);
        }
    }
}
