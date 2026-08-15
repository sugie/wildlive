<?php

namespace Tests\Unit\Domain\Game;

use App\Domain\Game\ExpeditionBalance;
use App\Domain\Game\ExpeditionPlanner;
use PHPUnit\Framework\TestCase;

/**
 * Everything decided before a Hunter is dispatched: is the map open, what
 * does it cost, how long does it take.
 *
 * No database, no clock, no randomness — every case here is a pure
 * function of two master-data rows.
 */
class ExpeditionPlannerTest extends TestCase
{
    use GameMasterFixtures;

    private ExpeditionPlanner $planner;

    protected function setUp(): void
    {
        parent::setUp();
        $this->planner = new ExpeditionPlanner();
    }

    // -- Release phase -------------------------------------------------------

    public function test_initial_africa_maps_are_released(): void
    {
        $this->assertTrue($this->planner->isReleased($this->map(availabilityPhase: 'initial_africa')));
    }

    public function test_future_expansion_maps_are_not_released(): void
    {
        $map = $this->map(availabilityPhase: 'future_expansion');

        $this->assertFalse($this->planner->isReleased($map));
        $this->assertFalse(
            $this->planner->isUnlocked($map, 999_999),
            'no amount of Zoo value unlocks a map that has not shipped'
        );
    }

    // -- Unlock rules --------------------------------------------------------

    public function test_always_maps_are_unlocked_from_registration(): void
    {
        $map = $this->map(unlockRule: 'always', unlockValue: 0);

        $this->assertTrue($this->planner->isUnlocked($map, 0));
    }

    public function test_zoo_value_map_is_locked_below_the_threshold(): void
    {
        $map = $this->map(unlockRule: 'zoo_value', unlockValue: 100);

        $this->assertFalse($this->planner->isUnlocked($map, 99));
    }

    public function test_zoo_value_map_unlocks_exactly_at_the_threshold(): void
    {
        $map = $this->map(unlockRule: 'zoo_value', unlockValue: 100);

        $this->assertTrue($this->planner->isUnlocked($map, 100));
        $this->assertTrue($this->planner->isUnlocked($map, 101));
    }

    public function test_unknown_unlock_rule_keeps_the_map_locked(): void
    {
        // Fail closed: a master-data typo must not open a map to everyone.
        $map = $this->map(unlockRule: 'future_expansion', unlockValue: 0);

        $this->assertFalse($this->planner->isUnlocked($map, 1_000_000));
    }

    // -- Cost ----------------------------------------------------------------

    public function test_cost_is_map_base_cost_plus_hunter_contract(): void
    {
        // Kenyan Savanna (50 G) + Amara Koné (50 G) — the cheapest possible
        // expedition in Game Master v0.3.
        $cost = $this->planner->totalCostG(
            $this->map(baseCostG: 50),
            $this->hunter(contractCostG: 50)
        );

        $this->assertSame(100, $cost);
    }

    public function test_cost_scales_with_an_expensive_hunter(): void
    {
        $cost = $this->planner->totalCostG(
            $this->map(baseCostG: 900),
            $this->hunter(contractCostG: 4500)
        );

        $this->assertSame(5400, $cost);
    }

    // -- Duration ------------------------------------------------------------

    public function test_duration_is_the_canonical_map_minutes_without_a_speed_bonus(): void
    {
        $minutes = $this->planner->durationMinutes(
            $this->map(expeditionMinutes: 240),
            $this->hunter(speedBonus: 0)
        );

        $this->assertSame(240, $minutes);
    }

    public function test_positive_speed_bonus_shortens_the_expedition(): void
    {
        // Yu-to (+20) on Kilimanjaro Slopes (240 min) → 192 min.
        $minutes = $this->planner->durationMinutes(
            $this->map(expeditionMinutes: 240),
            $this->hunter(speedBonus: 20)
        );

        $this->assertSame(192, $minutes);
    }

    public function test_negative_speed_bonus_lengthens_the_expedition(): void
    {
        // Zara Okafor (-5) pays for her rare-find bias with time.
        $minutes = $this->planner->durationMinutes(
            $this->map(expeditionMinutes: 100),
            $this->hunter(speedBonus: -5)
        );

        $this->assertSame(105, $minutes);
    }

    public function test_duration_never_drops_below_the_game_master_floor(): void
    {
        $minutes = $this->planner->durationMinutes(
            $this->map(expeditionMinutes: 5),
            $this->hunter(speedBonus: 30)
        );

        $this->assertSame(ExpeditionBalance::MIN_EXPEDITION_MINUTES, $minutes);
        $this->assertSame(5, $minutes);
    }

    public function test_duration_never_exceeds_the_game_master_ceiling(): void
    {
        $minutes = $this->planner->durationMinutes(
            $this->map(expeditionMinutes: 1440),
            $this->hunter(speedBonus: -20)
        );

        $this->assertSame(ExpeditionBalance::MAX_EXPEDITION_MINUTES, $minutes);
        $this->assertSame(1440, $minutes);
    }

    // -- Biome affinity ------------------------------------------------------

    public function test_matching_preferred_biome_grants_affinity(): void
    {
        $this->assertTrue($this->planner->hasBiomeAffinity(
            $this->map(biomeId: 'biome_desert'),
            $this->hunter(preferredBiomeId: 'biome_desert')
        ));
    }

    public function test_mismatched_preferred_biome_grants_no_affinity(): void
    {
        $this->assertFalse($this->planner->hasBiomeAffinity(
            $this->map(biomeId: 'biome_desert'),
            $this->hunter(preferredBiomeId: 'biome_mountain')
        ));
    }

    public function test_any_biome_hunter_never_gets_the_affinity_bonus(): void
    {
        // Game Master HunterSkills: `any` means "no matching bonus and no
        // mismatch penalty" — it is not a wildcard that always matches.
        foreach (['biome_savanna', 'biome_desert', 'biome_tundra'] as $biome) {
            $this->assertFalse(
                $this->planner->hasBiomeAffinity(
                    $this->map(biomeId: $biome),
                    $this->hunter(preferredBiomeId: 'any')
                ),
                "`any` must not match {$biome}"
            );
        }
    }
}
