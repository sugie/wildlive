<?php

namespace Tests\Unit\Domain\Game;

use App\Domain\Game\CaptureResolver;
use App\Domain\Game\ExpeditionBalance;
use App\Domain\Game\ExpeditionPlanner;
use PHPUnit\Framework\TestCase;
use Tests\Support\SequenceRandomSource;

/**
 * Whether the encountered animal is caught.
 *
 * The most important test in this file is the one asserting that
 * rare_find_bonus changes nothing: Game Master v0.3 fixes rare_find as an
 * encounter-distribution effect, and a regression that let it leak into
 * capture success would silently rewrite the game's core rule.
 */
class CaptureResolverTest extends TestCase
{
    use GameMasterFixtures;

    private function resolver(SequenceRandomSource $random = new SequenceRandomSource()): CaptureResolver
    {
        return new CaptureResolver($random, new ExpeditionPlanner());
    }

    // -- Chance --------------------------------------------------------------

    public function test_easiest_case_is_base_rate_plus_biome_affinity(): void
    {
        // Kenyan Savanna (difficulty 1) + Impala (capture_difficulty 1)
        // + Amara Koné (capture_bonus 0, prefers savanna).
        $chance = $this->resolver()->chancePercent(
            $this->map(difficulty: 1, biomeId: 'biome_savanna'),
            $this->hunter(captureBonus: 0, preferredBiomeId: 'biome_savanna'),
            $this->placement('ma', $this->animal(captureDifficulty: 1), 10)
        );

        $this->assertSame(
            ExpeditionBalance::BASE_SUCCESS_PERCENT + ExpeditionBalance::BIOME_AFFINITY_BONUS,
            $chance
        );
        $this->assertSame(70, $chance);
    }

    public function test_map_difficulty_reduces_the_chance(): void
    {
        $chance = $this->resolver()->chancePercent(
            $this->map(difficulty: 4, biomeId: 'biome_mountain'),
            $this->hunter(captureBonus: 0, preferredBiomeId: 'any'),
            $this->placement('ma', $this->animal(captureDifficulty: 1), 10)
        );

        // 60 − 8×3 = 36.
        $this->assertSame(36, $chance);
    }

    public function test_animal_capture_difficulty_reduces_the_chance(): void
    {
        $chance = $this->resolver()->chancePercent(
            $this->map(difficulty: 1, biomeId: 'biome_savanna'),
            $this->hunter(captureBonus: 0, preferredBiomeId: 'any'),
            $this->placement('ma', $this->animal(captureDifficulty: 4), 10)
        );

        // 60 − 8×3 = 36.
        $this->assertSame(36, $chance);
    }

    public function test_hunter_capture_bonus_raises_the_chance(): void
    {
        $chance = $this->resolver()->chancePercent(
            $this->map(difficulty: 4, biomeId: 'biome_rainforest'),
            $this->hunter(captureBonus: 25, preferredBiomeId: 'any'),
            $this->placement('ma', $this->animal(captureDifficulty: 3), 10)
        );

        // 60 − 24 − 16 + 25 = 45.
        $this->assertSame(45, $chance);
    }

    public function test_biome_affinity_adds_the_game_master_bonus(): void
    {
        $map = $this->map(difficulty: 3, biomeId: 'biome_desert');
        $placement = $this->placement('ma', $this->animal(captureDifficulty: 2), 10);

        $without = $this->resolver()->chancePercent(
            $map,
            $this->hunter(captureBonus: 15, preferredBiomeId: 'biome_mountain'),
            $placement
        );
        $with = $this->resolver()->chancePercent(
            $map,
            // Susumu — the Guild's only desert specialist.
            $this->hunter(captureBonus: 15, preferredBiomeId: 'biome_desert'),
            $placement
        );

        $this->assertSame(ExpeditionBalance::BIOME_AFFINITY_BONUS, $with - $without);
        $this->assertSame(10, $with - $without);
    }

    public function test_any_biome_hunter_is_neither_rewarded_nor_penalised(): void
    {
        // Game Master v0.3 sets the mismatch penalty to 0, so an `any`
        // Hunter sits exactly at the un-bonused baseline.
        $chance = $this->resolver()->chancePercent(
            $this->map(difficulty: 1, biomeId: 'biome_savanna'),
            $this->hunter(captureBonus: 0, preferredBiomeId: 'any'),
            $this->placement('ma', $this->animal(captureDifficulty: 1), 10)
        );

        $this->assertSame(ExpeditionBalance::BASE_SUCCESS_PERCENT, $chance);
    }

    public function test_per_placement_capture_modifier_is_applied(): void
    {
        // The Okapi's −15 on Congo Rainforest.
        $chance = $this->resolver()->chancePercent(
            $this->map(difficulty: 1, biomeId: 'biome_savanna'),
            $this->hunter(captureBonus: 0, preferredBiomeId: 'any'),
            $this->placement('ma', $this->animal(captureDifficulty: 1), 10, captureModifier: -15)
        );

        $this->assertSame(45, $chance);
    }

    public function test_chance_is_clamped_to_the_floor(): void
    {
        $chance = $this->resolver()->chancePercent(
            $this->map(difficulty: 5, biomeId: 'biome_rainforest'),
            $this->hunter(captureBonus: -20, preferredBiomeId: 'any'),
            $this->placement('ma', $this->animal(captureDifficulty: 5), 1, captureModifier: -30)
        );

        $this->assertSame(ExpeditionBalance::MIN_CAPTURE_PERCENT, $chance);
        $this->assertSame(5, $chance, 'nothing is ever hopeless');
    }

    public function test_chance_is_clamped_to_the_ceiling(): void
    {
        $chance = $this->resolver()->chancePercent(
            $this->map(difficulty: 1, biomeId: 'biome_savanna'),
            $this->hunter(captureBonus: 30, preferredBiomeId: 'biome_savanna'),
            $this->placement('ma', $this->animal(captureDifficulty: 1), 40, captureModifier: 20)
        );

        $this->assertSame(ExpeditionBalance::MAX_CAPTURE_PERCENT, $chance);
        $this->assertSame(95, $chance, 'nothing is ever certain');
    }

    // -- The rule that must not drift ---------------------------------------

    public function test_rare_find_bonus_does_not_change_capture_chance(): void
    {
        $map = $this->map(difficulty: 2, biomeId: 'biome_savanna');
        $placement = $this->placement('ma', $this->animal(captureDifficulty: 2), 10);

        $chances = [];
        foreach ([-20, -5, 0, 15, 30] as $rareFind) {
            $chances[] = $this->resolver()->chancePercent(
                $map,
                $this->hunter(captureBonus: 8, rareFindBonus: $rareFind, preferredBiomeId: 'biome_savanna'),
                $placement
            );
        }

        $this->assertCount(1, array_unique($chances),
            'rare_find_bonus biases WHAT is encountered, never whether it is caught');
    }

    // -- Roll ----------------------------------------------------------------

    public function test_a_roll_at_or_below_the_chance_captures(): void
    {
        $random = new SequenceRandomSource([70]);

        $attempt = $this->resolver($random)->attempt(
            $this->map(difficulty: 1, biomeId: 'biome_savanna'),
            $this->hunter(preferredBiomeId: 'biome_savanna'),
            $this->placement('ma', $this->animal(captureDifficulty: 1), 10)
        );

        $this->assertSame(70, $attempt['chance_percent']);
        $this->assertSame(70, $attempt['roll']);
        $this->assertTrue($attempt['captured'], 'the boundary roll succeeds');
    }

    public function test_a_roll_above_the_chance_fails(): void
    {
        $random = new SequenceRandomSource([71]);

        $attempt = $this->resolver($random)->attempt(
            $this->map(difficulty: 1, biomeId: 'biome_savanna'),
            $this->hunter(preferredBiomeId: 'biome_savanna'),
            $this->placement('ma', $this->animal(captureDifficulty: 1), 10)
        );

        $this->assertFalse($attempt['captured']);
    }

    public function test_the_attempt_rolls_exactly_once_on_a_d100(): void
    {
        // expedition_rule_base_capture_attempts = 1.
        $random = new SequenceRandomSource([50]);

        $this->resolver($random)->attempt(
            $this->map(),
            $this->hunter(),
            $this->placement('ma', $this->animal(), 10)
        );

        $this->assertSame(1, $random->callCount());
        $this->assertSame(['min' => 1, 'max' => 100, 'returned' => 50], $random->calls()[0]);
    }
}
