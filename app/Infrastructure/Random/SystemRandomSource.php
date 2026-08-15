<?php

namespace App\Infrastructure\Random;

use App\Domain\Support\RandomSource;

/**
 * Production RandomSource, backed by PHP's CSPRNG.
 *
 * random_int() rather than mt_rand() because expedition outcomes are
 * player-visible scarcity: a predictable sequence would be exploitable
 * once expeditions become competitive (World First, rare captures).
 */
final class SystemRandomSource implements RandomSource
{
    public function int(int $min, int $max): int
    {
        if ($min > $max) {
            throw new \InvalidArgumentException("min ({$min}) must not exceed max ({$max}).");
        }

        return random_int($min, $max);
    }
}
