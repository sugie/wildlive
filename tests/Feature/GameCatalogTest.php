<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Feature\Concerns\PlaysWildLive;
use Tests\TestCase;

/**
 * The read side of the game: which Maps a player may enter, what lives on
 * them, and who the Guild has.
 *
 * These assert against real Game Master v0.3 values, so they double as a
 * check that the workbook → JSON → seeder → API path is intact.
 */
class GameCatalogTest extends TestCase
{
    use RefreshDatabase;
    use PlaysWildLive;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedGameMaster();
    }

    // -- Maps ----------------------------------------------------------------

    public function test_map_list_returns_the_nine_initial_africa_maps(): void
    {
        $playerId = $this->registerPlayer();

        $response = $this->getJson("/api/players/{$playerId}/maps");

        $response->assertStatus(200);
        $this->assertCount(9, $response->json('maps'), 'Africa-first release ships nine maps');

        foreach ($response->json('maps') as $map) {
            $this->assertSame('initial_africa', $map['availability_phase'],
                'future_expansion maps must never be offered to a player');
        }
    }

    public function test_a_new_player_has_exactly_one_unlocked_map(): void
    {
        $playerId = $this->registerPlayer();

        $response = $this->getJson("/api/players/{$playerId}/maps");

        $unlocked = array_values(array_filter(
            $response->json('maps'),
            fn (array $m) => $m['unlocked']
        ));

        $this->assertCount(1, $unlocked);
        $this->assertSame(self::STARTER_MAP, $unlocked[0]['id']);
        $this->assertSame('always', $unlocked[0]['unlock_rule']);
        $this->assertSame(0, $response->json('zoo_value'));
    }

    public function test_locked_maps_are_still_listed_with_their_requirement(): void
    {
        $playerId = $this->registerPlayer();

        $serengeti = collect($this->getJson("/api/players/{$playerId}/maps")->json('maps'))
            ->firstWhere('id', 'map_serengeti_plains_002');

        $this->assertNotNull($serengeti, 'a player should see what they are working toward');
        $this->assertFalse($serengeti['unlocked']);
        $this->assertSame('zoo_value', $serengeti['unlock_rule']);
        $this->assertSame(100, $serengeti['unlock_value']);
    }

    public function test_map_carries_its_canonical_game_master_values(): void
    {
        $playerId = $this->registerPlayer();

        $map = collect($this->getJson("/api/players/{$playerId}/maps")->json('maps'))
            ->firstWhere('id', self::STARTER_MAP);

        $this->assertSame('Kenyan Savanna', $map['name_en']);
        $this->assertSame('ケニアのサバンナ', $map['name_ja']);
        $this->assertSame('biome_savanna', $map['biome_id']);
        $this->assertSame('starter', $map['map_role']);
        $this->assertSame(1, $map['difficulty']);
        $this->assertSame(10, $map['expedition_minutes'], 'canonical minutes reach the client unmodified');
        $this->assertSame(50, $map['base_cost_g']);
    }

    public function test_unknown_player_is_a_404(): void
    {
        $this->getJson('/api/players/00000000-0000-0000-0000-000000000000/maps')
            ->assertStatus(404)
            ->assertJsonPath('error.code', 'player_not_found');
    }

    // -- Map detail ----------------------------------------------------------

    public function test_map_detail_lists_the_animals_that_can_appear(): void
    {
        $playerId = $this->registerPlayer();

        $response = $this->getJson("/api/players/{$playerId}/maps/".self::STARTER_MAP);

        $response->assertStatus(200);
        $animals = $response->json('map.animals');

        $this->assertCount(16, $animals, 'Kenyan Savanna has 16 spawn rows in Game Master v0.3');

        $names = array_column(array_column($animals, 'animal'), 'name_en');
        $this->assertContains('Impala', $names);
        $this->assertContains('African Lion', $names);
        $this->assertContains('Olive Baboon', $names, 'v0.3 replaced the Chacma proxy in East Africa');
        $this->assertNotContains('Chacma Baboon', $names, 'Chacma is Southern African — Okavango only');
    }

    public function test_map_detail_animals_carry_rarity_and_spawn_weight(): void
    {
        $playerId = $this->registerPlayer();

        $impala = collect($this->getJson("/api/players/{$playerId}/maps/".self::STARTER_MAP)->json('map.animals'))
            ->first(fn (array $row) => $row['animal']['id'] === 'animal_impala_001');

        $this->assertSame(35, $impala['spawn_weight']);
        $this->assertSame('rarity_common', $impala['animal']['rarity']['id']);
        $this->assertSame(1, $impala['animal']['rarity']['sort_order']);
        $this->assertSame(10, $impala['animal']['base_zoo_value']);
    }

    public function test_northern_white_rhinoceros_appears_on_no_map(): void
    {
        // Game Master v0.3: special_event, not a normal spawn. The rule is
        // enforced by the absence of any MapAnimals row, so checking every
        // released map is the honest way to assert it.
        $playerId = $this->registerPlayer();

        foreach ($this->getJson("/api/players/{$playerId}/maps")->json('maps') as $map) {
            $detail = $this->getJson("/api/players/{$playerId}/maps/{$map['id']}");
            $ids = array_column(array_column($detail->json('map.animals'), 'animal'), 'id');

            $this->assertNotContains('animal_northern_white_rhino_039', $ids,
                "Northern White Rhinoceros must not be spawnable on {$map['id']}");
        }
    }

    public function test_future_expansion_map_detail_is_refused(): void
    {
        $playerId = $this->registerPlayer();

        $this->getJson("/api/players/{$playerId}/maps/map_annamite_range_012")
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'map_not_available');
    }

    public function test_unknown_map_is_a_404(): void
    {
        $playerId = $this->registerPlayer();

        $this->getJson("/api/players/{$playerId}/maps/map_does_not_exist")
            ->assertStatus(404)
            ->assertJsonPath('error.code', 'map_not_found');
    }

    // -- Hunters -------------------------------------------------------------

    public function test_hunter_list_returns_the_whole_guild_pool(): void
    {
        $response = $this->getJson('/api/hunters');

        $response->assertStatus(200);
        $this->assertCount(18, $response->json('hunters'), 'Game Master v0.3 has 18 Hunters');
    }

    public function test_hunters_are_contracted_not_owned(): void
    {
        $hunters = $this->getJson('/api/hunters')->json('hunters');

        foreach ($hunters as $hunter) {
            $this->assertArrayNotHasKey('owner_id', $hunter);
            $this->assertArrayNotHasKey('owned', $hunter);
            $this->assertArrayNotHasKey('available', $hunter,
                'availability would imply exclusive possession; v0.3 removed that language');
            $this->assertArrayHasKey('contract_cost_g', $hunter,
                'the only relationship a player has with a Hunter is a per-expedition contract');
        }
    }

    public function test_the_two_v0_3_hunters_are_present_with_their_japanese_names(): void
    {
        $hunters = collect($this->getJson('/api/hunters')->json('hunters'))->keyBy('id');

        $susumu = $hunters->get('hunter_susumu_019');
        $this->assertNotNull($susumu);
        $this->assertSame('Susumu', $susumu['name']);
        $this->assertSame('進', $susumu['name_ja']);
        $this->assertSame('biome_desert', $susumu['preferred_biome_id'],
            'Susumu is the Guild’s only desert specialist');

        $yuto = $hunters->get('hunter_yuto_020');
        $this->assertNotNull($yuto);
        $this->assertSame('Yu-to', $yuto['name']);
        $this->assertSame('雄斗', $yuto['name_ja']);
        $this->assertSame(20, $yuto['speed_bonus']);
    }

    public function test_hunters_can_be_costed_for_a_specific_map(): void
    {
        $response = $this->getJson('/api/hunters?map_id='.self::STARTER_MAP);

        $amara = collect($response->json('hunters'))->firstWhere('id', self::CHEAP_HUNTER);

        $this->assertSame(50, $amara['contract_cost_g']);
        $this->assertSame(100, $amara['for_map']['total_cost_g'], '50 G map + 50 G contract');
        $this->assertSame(10, $amara['for_map']['duration_minutes'], 'no speed bonus, canonical 10 minutes');
        $this->assertTrue($amara['for_map']['biome_affinity'], 'Amara prefers savanna');
    }

    public function test_speed_bonus_shortens_the_quoted_duration(): void
    {
        // Yu-to (+20) on Kilimanjaro Slopes (240 canonical minutes).
        $response = $this->getJson('/api/hunters?map_id=map_kilimanjaro_slopes_008');

        $yuto = collect($response->json('hunters'))->firstWhere('id', 'hunter_yuto_020');

        $this->assertSame(192, $yuto['for_map']['duration_minutes']);
        $this->assertTrue($yuto['for_map']['biome_affinity'], 'Kilimanjaro is a mountain map');
    }

    public function test_hunter_list_without_a_map_omits_the_costing_block(): void
    {
        $hunters = $this->getJson('/api/hunters')->json('hunters');

        foreach ($hunters as $hunter) {
            $this->assertArrayNotHasKey('for_map', $hunter);
        }
    }
}
