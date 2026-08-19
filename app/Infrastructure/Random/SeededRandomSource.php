<?php

namespace App\Infrastructure\Random;

use App\Domain\Support\RandomSource;
use InvalidArgumentException;

/**
 * A reproducible RandomSource, for simulation only.
 *
 * The whole point of a balance simulation is to compare runs. If the only
 * randomness available is a CSPRNG, two runs of the same parameters differ,
 * and there is no way to tell a parameter's effect apart from noise. Seed
 * this and the same seed always produces the same playthrough, so a
 * difference between runs is a difference in the rules.
 *
 * NOT for production. SystemRandomSource stays bound in the container for
 * anything a player can reach: expedition outcomes are player-visible
 * scarcity, and a predictable sequence would be exploitable the moment
 * captures become competitive. This class is bound only by the simulation
 * command, which never serves a request.
 *
 * The generator is a 64-bit xorshift*. It is not cryptographic and does not
 * need to be — it needs to be uniform enough for a Monte Carlo run and
 * identical on every machine that runs it. PHP's mt_rand() would not do:
 * its seeding and stream have changed between PHP versions before, which
 * would silently invalidate a stored baseline.
 */
final class SeededRandomSource implements RandomSource
{
    private int $state;

    private int $draws = 0;

    public function __construct(private readonly int $seed)
    {
        // xorshift is dead at zero. Any other value is a fine starting
        // point, but a small seed takes a few rounds to look random, so
        // spin the state before handing out draws.
        $this->state = $seed === 0 ? PHP_INT_MAX : $seed;

        for ($i = 0; $i < 16; $i++) {
            $this->next();
        }
    }

    public function int(int $min, int $max): int
    {
        if ($min > $max) {
            throw new InvalidArgumentException("min ({$min}) must not exceed max ({$max}).");
        }

        $this->draws++;

        if ($min === $max) {
            return $min;
        }

        $range = $max - $min + 1;

        // Modulo alone would bias the low end of the range. Rejection
        // sampling keeps the draw uniform, which matters here: a 1%
        // Legendary is exactly the tail a biased generator would misreport.
        $limit = PHP_INT_MAX - (PHP_INT_MAX % $range) - 1;

        do {
            $value = $this->next() & PHP_INT_MAX;
        } while ($value > $limit);

        return $min + ($value % $range);
    }

    /** How many rolls have been drawn — a cheap check that a run is comparable. */
    public function draws(): int
    {
        return $this->draws;
    }

    public function seed(): int
    {
        return $this->seed;
    }

    /**
     * One xorshift64 step.
     *
     * Shifts and xors only, deliberately: PHP promotes an integer
     * multiplication that overflows to float, so the multiply-based
     * variants of this family (xorshift*, splitmix64) silently stop being
     * 64-bit integer generators. Left shifts discard the bits that fall off
     * the top and stay integers, so this stays exact on any 64-bit PHP.
     */
    private function next(): int
    {
        $x = $this->state;
        $x ^= ($x << 13);
        $x ^= self::unsignedShiftRight($x, 7);
        $x ^= ($x << 17);

        return $this->state = $x;
    }

    /** PHP's >> is arithmetic; this generator needs a logical shift. */
    private static function unsignedShiftRight(int $value, int $bits): int
    {
        if ($bits === 0) {
            return $value;
        }

        return ($value >> $bits) & ~(PHP_INT_MIN >> ($bits - 1));
    }
}
