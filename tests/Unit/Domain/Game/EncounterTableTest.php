<?php

namespace Tests\Unit\Domain\Game;

use App\Domain\Game\EncounterTable;
use PHPUnit\Framework\TestCase;
use Tests\Support\SequenceRandomSource;

/**
 * Which species the Hunter runs into.
 *
 * The draw is scripted through SequenceRandomSource, so these tests assert
 * exact outcomes rather than statistical tendencies — nothing here can
 * fail intermittently.
 */
class EncounterTableTest extends TestCase
{
    use GameMasterFixtures;

    /**
     * Impala (Common, weight 35), Leopard (Uncommon, weight 8),
     * Lion (Rare, weight 6) — a trimmed Kenyan Savanna table.
     *
     * @return array<int, \App\Models\MapAnimal>
     */
    private function savannaCandidates(): array
    {
        return [
            $this->placement('ma_impala', $this->animal('animal_impala_001', raritySortOrder: 1), 35),
            $this->placement('ma_leopard', $this->animal('animal_leopard_017', raritySortOrder: 2), 8),
            $this->placement('ma_lion', $this->animal('animal_lion_029', raritySortOrder: 3), 6),
        ];
    }

    // -- Weights -------------------------------------------------------------

    public function test_without_a_rare_find_bonus_weights_are_the_raw_spawn_weights(): void
    {
        $table = new EncounterTable(new SequenceRandomSource());

        $weights = $table->weights($this->savannaCandidates(), 0);

        // Scaled by 1000 for fixed-point arithmetic; the ratios are 35:8:6.
        $this->assertSame(35_000, $weights['ma_impala']);
        $this->assertSame(8_000, $weights['ma_leopard']);
        $this->assertSame(6_000, $weights['ma_lion']);
    }

    public function test_rare_find_bonus_compounds_with_rarity_tier(): void
    {
        $table = new EncounterTable(new SequenceRandomSource());

        // Dr. Malik Osei's +30, the highest in the game.
        $weights = $table->weights($this->savannaCandidates(), 30);

        // Common is untouched (exponent 0), Uncommon ×1.3, Rare ×1.69.
        $this->assertSame(35_000, $weights['ma_impala']);
        $this->assertSame(10_400, $weights['ma_leopard']);
        $this->assertSame(10_140, $weights['ma_lion']);
    }

    public function test_negative_rare_find_bonus_biases_toward_common(): void
    {
        $table = new EncounterTable(new SequenceRandomSource());

        // The rookies' -5.
        $weights = $table->weights($this->savannaCandidates(), -5);

        $this->assertSame(35_000, $weights['ma_impala'], 'Common is the pivot and never moves');
        $this->assertSame(7_600, $weights['ma_leopard']);
        $this->assertSame(5_415, $weights['ma_lion']);
    }

    public function test_rare_find_bonus_never_changes_the_relative_order_within_a_tier(): void
    {
        $table = new EncounterTable(new SequenceRandomSource());

        $candidates = [
            $this->placement('ma_a', $this->animal('animal_a', raritySortOrder: 3), 10),
            $this->placement('ma_b', $this->animal('animal_b', raritySortOrder: 3), 5),
        ];

        $weights = $table->weights($candidates, 30);

        $this->assertGreaterThan($weights['ma_b'], $weights['ma_a']);
    }

    // -- Draw ----------------------------------------------------------------

    public function test_lowest_roll_draws_the_first_candidate(): void
    {
        $table = new EncounterTable(new SequenceRandomSource([1]));

        $result = $table->draw($this->savannaCandidates(), 0);

        $this->assertSame('animal_impala_001', $result['candidate']->animal_id);
        $this->assertSame(49_000, $result['total_weight']);
    }

    public function test_roll_at_a_boundary_draws_that_candidate(): void
    {
        // Impala occupies 1..35000; 35000 is still the Impala.
        $table = new EncounterTable(new SequenceRandomSource([35_000]));
        $this->assertSame(
            'animal_impala_001',
            $table->draw($this->savannaCandidates(), 0)['candidate']->animal_id
        );

        // 35001 is the first Leopard ticket.
        $table = new EncounterTable(new SequenceRandomSource([35_001]));
        $this->assertSame(
            'animal_leopard_017',
            $table->draw($this->savannaCandidates(), 0)['candidate']->animal_id
        );
    }

    public function test_highest_roll_draws_the_last_candidate(): void
    {
        $table = new EncounterTable(new SequenceRandomSource([49_000]));

        $result = $table->draw($this->savannaCandidates(), 0);

        $this->assertSame('animal_lion_029', $result['candidate']->animal_id);
        $this->assertSame(49_000, $result['roll']);
    }

    public function test_rare_find_bonus_moves_the_boundary_so_the_same_roll_finds_something_rarer(): void
    {
        // A roll of 36,000 lands on the Leopard either way, but at +30 the
        // rare half of the table is wider: the same roll relative to the
        // total is more likely to be rare. Assert the widening directly.
        $table = new EncounterTable(new SequenceRandomSource([1]));

        $plain = $table->weights($this->savannaCandidates(), 0);
        $boosted = (new EncounterTable(new SequenceRandomSource()))
            ->weights($this->savannaCandidates(), 30);

        $plainRareShare = ($plain['ma_leopard'] + $plain['ma_lion']) / array_sum($plain);
        $boostedRareShare = ($boosted['ma_leopard'] + $boosted['ma_lion']) / array_sum($boosted);

        $this->assertGreaterThan(
            $plainRareShare,
            $boostedRareShare,
            'a rare-find Hunter must make the non-Common share of the table larger'
        );
    }

    public function test_the_draw_consumes_exactly_one_roll_over_the_total_weight(): void
    {
        $random = new SequenceRandomSource([1]);
        $table = new EncounterTable($random);

        $table->draw($this->savannaCandidates(), 0);

        $this->assertSame(1, $random->callCount());
        $this->assertSame(['min' => 1, 'max' => 49_000, 'returned' => 1], $random->calls()[0]);
    }

    public function test_an_empty_candidate_list_is_rejected(): void
    {
        $table = new EncounterTable(new SequenceRandomSource([1]));

        $this->expectException(\InvalidArgumentException::class);
        $table->draw([], 0);
    }

    public function test_a_candidate_list_with_no_weight_is_rejected(): void
    {
        $table = new EncounterTable(new SequenceRandomSource([1]));

        $this->expectException(\InvalidArgumentException::class);
        $table->draw([$this->placement('ma_zero', $this->animal(), 0)], 0);
    }
}
