<?php

namespace App\Domain\Players;

use App\Models\Player;

/**
 * Contract for persisting Player rows.
 *
 * The Application Layer talks to this interface, never to Eloquent directly.
 * The Eloquent Player model is intentionally used as the return type at this
 * stage: docs/ER_MODEL.md fixes Player as `id + created_at + display_name`
 * only, so introducing a separate POPO entity would be pure ceremony. The
 * moment Player grows behaviour that shouldn't live on the ORM row, this
 * interface's return type becomes the seam we split on.
 */
interface PlayerRepository
{
    /**
     * Persist a new Player with the given display name.
     *
     * The display name is expected to be already-validated and already-trimmed
     * by the caller (Application Layer). Server-generated fields (id,
     * created_at) are set here.
     */
    public function create(string $displayName): Player;

    /**
     * Load a player with their Zoo eager-loaded, or null if unknown.
     */
    public function find(string $playerId): ?Player;

    /**
     * Load a player with a row lock (SELECT … FOR UPDATE).
     *
     * Starting an expedition reads the G balance and then writes it, so
     * two simultaneous dispatches must not both see the pre-debit value
     * and each conclude the player can afford it. Callers must already be
     * inside a transaction.
     */
    public function findForUpdate(string $playerId): ?Player;

    /**
     * Move a player's G balance by a signed delta and persist it.
     *
     * The caller is responsible for having checked affordability under the
     * same lock; this method only records the movement.
     */
    public function adjustBalance(Player $player, int $deltaG): Player;
}
