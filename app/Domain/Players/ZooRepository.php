<?php

namespace App\Domain\Players;

use App\Models\Player;
use App\Models\Zoo;

/**
 * Contract for persisting Zoo rows.
 *
 * The Player → Zoo 1:1 invariant (docs/ER_MODEL.md §C1) is enforced by:
 *   - RegisterPlayer opening a transaction and calling this + PlayerRepository
 *     inside the same closure, AND
 *   - the UNIQUE(zoos.player_id) NOT NULL constraint at the DB level.
 *
 * Both are needed. The transaction protects against partial writes; the
 * constraint protects against future callers that forget the transaction.
 */
interface ZooRepository
{
    public function createForPlayer(Player $player): Zoo;
}
