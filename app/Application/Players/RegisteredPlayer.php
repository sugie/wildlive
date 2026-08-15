<?php

namespace App\Application\Players;

use App\Models\Player;
use App\Models\Zoo;

/**
 * Result of the RegisterPlayer use case.
 *
 * Carries the two rows that the C1 invariant links (Player + Zoo, created
 * in the same transaction) so the Presentation Layer can format both into
 * the response payload.
 */
final class RegisteredPlayer
{
    public function __construct(
        public readonly Player $player,
        public readonly Zoo $zoo,
    ) {
    }
}
