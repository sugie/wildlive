<?php

namespace Tests\Feature;

use App\Models\Expedition;
use App\Models\Player;
use App\Models\ZooAnimal;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Feature\Concerns\PlaysWildLive;
use Tests\TestCase;

/**
 * The gameplay loop, end to end through the real API and PostgreSQL:
 * dispatch → resolve → keep or release → My Zoo.
 *
 * Every roll is scripted, so each test asserts one exact outcome.
 */
class ExpeditionFlowTest extends TestCase
{
    use RefreshDatabase;
    use PlaysWildLive;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedGameMaster();
    }

    // -- Dispatch ------------------------------------------------------------

    public function test_starting_an_expedition_persists_it_and_debits_the_cost(): void
    {
        $playerId = $this->registerPlayer();

        $response = $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => self::STARTER_MAP,
            'hunter_id' => self::CHEAP_HUNTER,
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('expedition.status', Expedition::STATUS_IN_PROGRESS);
        $response->assertJsonPath('expedition.map.id', self::STARTER_MAP);
        $response->assertJsonPath('expedition.hunter.id', self::CHEAP_HUNTER);
        $response->assertJsonPath('expedition.cost.map_cost_g', 50);
        $response->assertJsonPath('expedition.cost.contract_cost_g', 50);
        $response->assertJsonPath('expedition.cost.total_cost_g', 100);

        $this->assertSame(1, Expedition::query()->count(), 'the expedition is in PostgreSQL');
        $this->assertSame(900, Player::query()->find($playerId)->g_balance, '1000 − 100');
    }

    public function test_expedition_ends_at_follows_the_canonical_map_minutes(): void
    {
        $playerId = $this->registerPlayer();

        $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => self::STARTER_MAP,
            'hunter_id' => self::CHEAP_HUNTER,
        ])->assertStatus(201);

        $expedition = Expedition::query()->firstOrFail();

        $this->assertSame(10, $expedition->planned_duration_minutes,
            'Kenyan Savanna is 10 canonical minutes and Amara has no speed bonus');
        $this->assertSame(
            10,
            (int) round($expedition->started_at->diffInMinutes($expedition->ends_at)),
        );
        $this->assertFalse($expedition->dev_instant_resolve);
    }

    public function test_a_speed_hunter_shortens_ends_at_without_touching_the_map(): void
    {
        $playerId = $this->registerPlayer();

        // Miguel Santos, +30 speed, on the 10-minute starter map → 7 minutes.
        $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => self::STARTER_MAP,
            'hunter_id' => 'hunter_miguel_santos_012',
        ])->assertStatus(201);

        $expedition = Expedition::query()->firstOrFail();

        $this->assertSame(7, $expedition->planned_duration_minutes);
        $this->assertSame(10, (int) $expedition->map->expedition_minutes,
            'the canonical master value is untouched');
    }

    public function test_a_locked_map_is_refused(): void
    {
        $playerId = $this->registerPlayer();

        $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => 'map_serengeti_plains_002',
            'hunter_id' => self::CHEAP_HUNTER,
        ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'map_locked');

        $this->assertSame(0, Expedition::query()->count());
        $this->assertSame(1000, Player::query()->find($playerId)->g_balance,
            'a refused dispatch must not charge the player');
    }

    public function test_a_future_expansion_map_is_refused(): void
    {
        $playerId = $this->registerPlayer();

        $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => 'map_annamite_range_012',
            'hunter_id' => self::CHEAP_HUNTER,
        ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'map_not_available');
    }

    public function test_insufficient_g_is_refused_and_charges_nothing(): void
    {
        $playerId = $this->registerPlayer();

        // Dr. Malik Osei costs 4500 G; a new player has 1000 G.
        $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => self::STARTER_MAP,
            'hunter_id' => 'hunter_dr_malik_osei_018',
        ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'insufficient_g');

        $this->assertSame(1000, Player::query()->find($playerId)->g_balance);
        $this->assertSame(0, Expedition::query()->count());
    }

    public function test_an_unknown_hunter_is_a_404(): void
    {
        $playerId = $this->registerPlayer();

        $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => self::STARTER_MAP,
            'hunter_id' => 'hunter_nobody',
        ])
            ->assertStatus(404)
            ->assertJsonPath('error.code', 'hunter_not_found');
    }

    public function test_map_and_hunter_are_required(): void
    {
        $playerId = $this->registerPlayer();

        $this->postJson("/api/players/{$playerId}/expeditions", [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['map_id', 'hunter_id']);
    }

    public function test_contracting_a_hunter_creates_no_ownership(): void
    {
        // Two players contract the same Hunter for overlapping expeditions.
        // Game Master v0.3 removed the scarce-shared-contract language, so
        // nothing about the first dispatch may block the second.
        $first = $this->registerPlayer('First');
        $second = $this->registerPlayer('Second');

        $this->startInstantExpedition($first);
        $this->startInstantExpedition($second);

        $this->assertSame(2, Expedition::query()->where('hunter_id', self::CHEAP_HUNTER)->count());
        $this->assertFalse(
            \Illuminate\Support\Facades\Schema::hasTable('player_hunters'),
            'a Hunter is contracted per expedition and never owned'
        );
    }

    // -- Development-only instant resolution --------------------------------

    public function test_the_dev_shortcut_makes_an_expedition_immediately_due(): void
    {
        $playerId = $this->registerPlayer();

        $response = $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => self::STARTER_MAP,
            'hunter_id' => self::CHEAP_HUNTER,
            'dev_instant_resolve' => true,
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('expedition.dev_instant_resolve', true);
        $response->assertJsonPath('expedition.is_due', true);
        $response->assertJsonPath('expedition.planned_duration_minutes', 10);

        $expedition = Expedition::query()->firstOrFail();
        $this->assertTrue($expedition->dev_instant_resolve,
            'the shortcut is recorded in PostgreSQL, not just in the response');
        $this->assertSame(10, (int) $expedition->planned_duration_minutes,
            'the real duration is preserved even though ends_at was collapsed');
    }

    public function test_a_normal_expedition_is_not_yet_due(): void
    {
        $playerId = $this->registerPlayer();

        $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => self::STARTER_MAP,
            'hunter_id' => self::CHEAP_HUNTER,
        ])->assertJsonPath('expedition.is_due', false);
    }

    public function test_resolving_before_the_return_time_is_refused(): void
    {
        $playerId = $this->registerPlayer();

        $expeditionId = $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => self::STARTER_MAP,
            'hunter_id' => self::CHEAP_HUNTER,
        ])->json('expedition.id');

        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve")
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'expedition_not_due');
    }

    // -- Resolution ----------------------------------------------------------

    public function test_a_successful_capture_records_the_encounter_and_the_maths(): void
    {
        $this->scriptGuaranteedCapture();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);

        $response = $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");

        $response->assertStatus(200);
        $response->assertJsonPath('expedition.status', Expedition::STATUS_RESOLVED);
        $response->assertJsonPath('expedition.outcome', Expedition::OUTCOME_CAPTURED);
        $response->assertJsonPath('expedition.awaits_decision', true);

        // Roll 1 draws the highest-weighted animal on the map: the Impala.
        $response->assertJsonPath('expedition.resolution.encountered_animal.id', 'animal_impala_001');
        // 60 base + 10 savanna affinity, no difficulty penalties.
        $response->assertJsonPath('expedition.resolution.capture_chance_percent', 70);
        $response->assertJsonPath('expedition.resolution.capture_roll', 1);
    }

    public function test_a_failed_capture_still_reports_what_was_encountered(): void
    {
        $this->scriptGuaranteedMiss();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);

        $response = $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");

        $response->assertJsonPath('expedition.outcome', Expedition::OUTCOME_NO_CAPTURE);
        $response->assertJsonPath('expedition.awaits_decision', false);
        $response->assertJsonPath('expedition.resolution.encountered_animal.id', 'animal_impala_001');
        $response->assertJsonPath('expedition.resolution.capture_roll', 100);
    }

    public function test_a_failed_capture_costs_no_extra_g(): void
    {
        // expedition_rule_failure_penalty_g = 0 — only the sunk dispatch
        // and contract G is lost.
        $this->scriptGuaranteedMiss();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);

        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve")->assertStatus(200);

        $this->assertSame(900, Player::query()->find($playerId)->g_balance);
    }

    public function test_resolution_is_idempotent(): void
    {
        // Only two rolls are scripted. A second resolution that re-rolled
        // would exhaust the sequence and fail loudly.
        $random = $this->scriptRolls([1, 1]);
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);

        $first = $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");
        $second = $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");

        $first->assertStatus(200);
        $second->assertStatus(200);
        $this->assertSame(2, $random->callCount(), 'the second call must not re-roll');
        $this->assertSame(
            $first->json('expedition.resolved_at'),
            $second->json('expedition.resolved_at'),
            'the outcome is fixed at first resolution'
        );
        $this->assertSame(
            $first->json('expedition.resolution.encountered_animal.id'),
            $second->json('expedition.resolution.encountered_animal.id')
        );
    }

    public function test_fetching_a_due_expedition_resolves_it_lazily(): void
    {
        $this->scriptGuaranteedCapture();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);

        $response = $this->getJson("/api/players/{$playerId}/expeditions/{$expeditionId}");

        $response->assertStatus(200);
        $response->assertJsonPath('expedition.status', Expedition::STATUS_RESOLVED);
        $response->assertJsonPath('expedition.outcome', Expedition::OUTCOME_CAPTURED);
    }

    public function test_another_players_expedition_is_not_visible(): void
    {
        $owner = $this->registerPlayer('Owner');
        $intruder = $this->registerPlayer('Intruder');
        $expeditionId = $this->startInstantExpedition($owner);

        $this->getJson("/api/players/{$intruder}/expeditions/{$expeditionId}")
            ->assertStatus(404)
            ->assertJsonPath('error.code', 'expedition_not_found');

        $this->postJson("/api/players/{$intruder}/expeditions/{$expeditionId}/resolve")
            ->assertStatus(404);
    }

    // -- KEEP ----------------------------------------------------------------

    public function test_keeping_a_capture_adds_a_named_animal_to_the_zoo(): void
    {
        $this->scriptGuaranteedCapture();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");

        $response = $this->postJson(
            "/api/players/{$playerId}/expeditions/{$expeditionId}/keep",
            ['name' => 'Blaze']
        );

        $response->assertStatus(200);
        $response->assertJsonPath('expedition.decision', Expedition::DECISION_KEPT);
        $response->assertJsonPath('expedition.awaits_decision', false);
        $response->assertJsonPath('expedition.zoo_animal.name', 'Blaze');
        $response->assertJsonPath('expedition.zoo_animal.species.id', 'animal_impala_001');

        $this->assertSame(1, ZooAnimal::query()->count());
        $animal = ZooAnimal::query()->firstOrFail();
        $this->assertSame('Blaze', $animal->name);
        $this->assertSame($expeditionId, $animal->expedition_id);
        $this->assertSame(self::STARTER_MAP, $animal->captured_from_map_id);
        $this->assertSame(self::CHEAP_HUNTER, $animal->captured_by_hunter_id);
    }

    public function test_an_empty_name_falls_back_to_the_species_name(): void
    {
        $this->scriptGuaranteedCapture();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");

        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/keep", ['name' => '   '])
            ->assertStatus(200)
            ->assertJsonPath('expedition.zoo_animal.name', 'Impala');
    }

    public function test_keeping_is_idempotent_and_never_mints_two_animals(): void
    {
        $this->scriptGuaranteedCapture();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");

        $first = $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/keep", ['name' => 'Blaze']);
        $second = $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/keep", ['name' => 'Blaze']);

        $first->assertStatus(200);
        $second->assertStatus(200);
        $this->assertSame(1, ZooAnimal::query()->count(), 'UNIQUE(expedition_id) plus the decided_at guard');
        $this->assertSame($first->json('expedition.decided_at'), $second->json('expedition.decided_at'));
    }

    public function test_keeping_a_no_capture_expedition_is_refused(): void
    {
        $this->scriptGuaranteedMiss();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");

        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/keep", ['name' => 'Ghost'])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'nothing_to_decide');

        $this->assertSame(0, ZooAnimal::query()->count());
    }

    public function test_keeping_an_unresolved_expedition_is_refused(): void
    {
        $playerId = $this->registerPlayer();
        $expeditionId = $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => self::STARTER_MAP,
            'hunter_id' => self::CHEAP_HUNTER,
        ])->json('expedition.id');

        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/keep", ['name' => 'Early'])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'expedition_not_resolved');
    }

    // -- RELEASE -------------------------------------------------------------

    public function test_releasing_adds_nothing_to_the_zoo_and_pays_nothing(): void
    {
        // expedition_rule_release_reward_ratio = 0.
        $this->scriptGuaranteedCapture();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");

        $response = $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/release");

        $response->assertStatus(200);
        $response->assertJsonPath('expedition.decision', Expedition::DECISION_RELEASED);
        $response->assertJsonPath('expedition.zoo_animal', null);

        $this->assertSame(0, ZooAnimal::query()->count());
        $this->assertSame(900, Player::query()->find($playerId)->g_balance,
            'releasing returns 0 G');
    }

    public function test_releasing_is_idempotent(): void
    {
        $this->scriptGuaranteedCapture();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");

        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/release")->assertStatus(200);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/release")->assertStatus(200);

        $this->assertSame(0, ZooAnimal::query()->count());
    }

    public function test_keeping_after_releasing_is_a_conflict(): void
    {
        $this->scriptGuaranteedCapture();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/release")->assertStatus(200);

        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/keep", ['name' => 'TooLate'])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'already_decided');

        $this->assertSame(0, ZooAnimal::query()->count());
    }

    public function test_releasing_after_keeping_is_a_conflict(): void
    {
        $this->scriptGuaranteedCapture();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/keep", ['name' => 'Mine'])
            ->assertStatus(200);

        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/release")
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'already_decided');

        $this->assertSame(1, ZooAnimal::query()->count(), 'the kept animal stays in the Zoo');
    }

    // -- The whole loop ------------------------------------------------------

    public function test_the_full_loop_from_registration_to_my_zoo(): void
    {
        $this->scriptGuaranteedCapture();

        $playerId = $this->registerPlayer('LoopTester');

        $this->assertSame(1000, $this->getJson("/api/players/{$playerId}")->json('player.g_balance'));

        $expeditionId = $this->startInstantExpedition($playerId);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve")->assertStatus(200);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/keep", ['name' => 'Nala'])
            ->assertStatus(200);

        $zoo = $this->getJson("/api/players/{$playerId}/zoo");
        $zoo->assertStatus(200);
        $zoo->assertJsonPath('zoo.animal_count', 1);
        $zoo->assertJsonPath('zoo.zoo_value', 10);
        $zoo->assertJsonPath('animals.0.name', 'Nala');
        $zoo->assertJsonPath('animals.0.species.name_en', 'Impala');
        $zoo->assertJsonPath('animals.0.species.rarity.name_en', 'Common');

        $overview = $this->getJson("/api/players/{$playerId}");
        $overview->assertJsonPath('player.g_balance', 900);
        $overview->assertJsonPath('zoo.animal_count', 1);
        $overview->assertJsonPath('zoo.zoo_value', 10);
        $overview->assertJsonPath('expeditions.pending_decisions', 0);
    }

    public function test_a_pending_capture_is_surfaced_on_the_overview(): void
    {
        $this->scriptGuaranteedCapture();
        $playerId = $this->registerPlayer();
        $expeditionId = $this->startInstantExpedition($playerId);
        $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");

        $this->getJson("/api/players/{$playerId}")
            ->assertJsonPath('expeditions.pending_decisions', 1)
            ->assertJsonPath('expeditions.active', 0);
    }

    public function test_zoo_value_unlocks_the_next_map(): void
    {
        $playerId = $this->registerPlayer();

        // Serengeti needs Zoo value 100. Cape Buffalo is worth 15, so ten
        // captures of the map's heaviest animal are not enough on their own;
        // drive the balance directly by keeping repeated Impalas (10 each).
        for ($i = 0; $i < 10; $i++) {
            $this->scriptGuaranteedCapture();
            $expeditionId = $this->startInstantExpedition($playerId);
            $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/resolve");
            $this->postJson("/api/players/{$playerId}/expeditions/{$expeditionId}/keep", ['name' => "Impala {$i}"]);
        }

        $maps = collect($this->getJson("/api/players/{$playerId}/maps")->json('maps'));

        $this->assertSame(100, $this->getJson("/api/players/{$playerId}")->json('zoo.zoo_value'));
        $this->assertTrue($maps->firstWhere('id', 'map_serengeti_plains_002')['unlocked'],
            'ten Impalas at 10 zoo value each meets the Serengeti threshold');
        $this->assertFalse($maps->firstWhere('id', 'map_okavango_delta_003')['unlocked'],
            'the 500-value map stays locked');
    }
}
