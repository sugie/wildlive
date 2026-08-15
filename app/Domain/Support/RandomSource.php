<?php

namespace App\Domain\Support;

/**
 * The single source of randomness for game resolution.
 *
 * Every roll the game makes — encounter selection, capture success —
 * goes through this interface, so a test can supply an exact sequence and
 * assert an exact outcome. No gameplay code may call rand(), mt_rand(),
 * random_int(), or Arr::random() directly.
 *
 * Deliberately narrow: one inclusive-integer method covers both a
 * weighted draw (`int(1, $totalWeight)`) and a percentage roll
 * (`int(1, 100)`), and a single method is trivial to fake.
 */
interface RandomSource
{
    /**
     * A uniformly distributed integer in [$min, $max], both inclusive.
     */
    public function int(int $min, int $max): int;
}
