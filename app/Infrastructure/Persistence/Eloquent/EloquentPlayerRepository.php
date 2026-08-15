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
        // g_balance is left to the column default so the starting balance
        // is defined in exactly one place (config/wildlive.php, applied by
        // the migration) rather than duplicated in the insert.
        //
        // refresh() because a column default is applied by PostgreSQL, not
        // by Eloquent: without it the model returned to the caller — and
        // therefore the registration response — would report 0 G for a
        // player who actually has the starting balance.
        $player = Player::create(['display_name' => $displayName]);

        return $player->refresh();
    }

    public function find(string $playerId): ?Player
    {
        return Player::query()->with('zoo')->find($playerId);
    }

    public function findForUpdate(string $playerId): ?Player
    {
        $player = Player::query()->lockForUpdate()->find($playerId);

        return $player?->load('zoo');
    }

    public function adjustBalance(Player $player, int $deltaG): Player
    {
        $player->g_balance = (int) $player->g_balance + $deltaG;
        $player->save();

        return $player;
    }
}
