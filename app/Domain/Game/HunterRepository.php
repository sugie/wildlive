<?php

namespace App\Domain\Game;

use App\Models\Hunter;
use Illuminate\Support\Collection;

/**
 * Read access to the Guild's Hunter pool.
 *
 * There is no "hunters owned by player" query, and there will not be one:
 * a Hunter is contracted per expedition and never owned (Game Master v0.3).
 * The whole pool is therefore visible to every player.
 */
interface HunterRepository
{
    /** @return Collection<int, Hunter> */
    public function all(): Collection;

    public function find(string $hunterId): ?Hunter;
}
