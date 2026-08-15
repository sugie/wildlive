<?php

namespace App\Application\Players;

use App\Domain\Players\PlayerRepository;
use App\Domain\Players\ZooRepository;
use Illuminate\Database\ConnectionInterface;

/**
 * First-time player registration use case.
 *
 * Encapsulates the Player + Zoo atomic-creation invariant fixed by
 * docs/ER_MODEL.md §C1. The Presentation Layer must call this class
 * instead of touching Player::create / Zoo::create / DB::transaction
 * directly.
 *
 * The dependency on Illuminate\Database\ConnectionInterface is intentional:
 * it is an interface (fakeable in unit tests) and using it directly avoids
 * introducing a bespoke TransactionRunner abstraction that would exist
 * only to be forwarded to the same underlying implementation.
 */
final class RegisterPlayer
{
    public function __construct(
        private readonly ConnectionInterface $db,
        private readonly PlayerRepository $players,
        private readonly ZooRepository $zoos,
    ) {
    }

    public function __invoke(RegisterPlayerInput $input): RegisteredPlayer
    {
        /** @var RegisteredPlayer $result */
        $result = $this->db->transaction(function () use ($input): RegisteredPlayer {
            $player = $this->players->create($input->displayName);
            $zoo = $this->zoos->createForPlayer($player);
            return new RegisteredPlayer(player: $player, zoo: $zoo);
        });

        return $result;
    }
}
