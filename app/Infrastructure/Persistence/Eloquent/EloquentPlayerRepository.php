<?php

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Players\PlayerRepository;
use App\Models\Player;

/**
 * Eloquent-backed PlayerRepository implementation.
 *
 * Only the Infrastructure Layer is allowed to call `Player::create()`.
 * The Application Layer talks to the PlayerRepository interface; the
 * Presentation Layer talks to the Application Layer.
 */
final class EloquentPlayerRepository implements PlayerRepository
{
    public function create(string $displayName): Player
    {
        return Player::create(['display_name' => $displayName]);
    }
}
