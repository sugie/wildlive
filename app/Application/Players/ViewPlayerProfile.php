<?php

namespace App\Application\Players;

use App\Application\Expeditions\ExpeditionRejected;
use App\Domain\Game\ExpeditionRepository;
use App\Domain\Game\ZooAnimalRepository;
use App\Domain\Players\PlayerRepository;
use App\Models\Expedition;
use App\Models\Player;
use App\Models\ZooAnimal;
use Illuminate\Support\Collection;

/**
 * The player's own view of themselves: balance, Zoo, and what still needs
 * their attention.
 *
 * `pending_decisions` is the number of captured animals waiting to be kept
 * or released. It drives the badge on Home, and it is computed server-side
 * so the client never has to work out what "needs attention" means.
 */
final class ViewPlayerProfile
{
    public function __construct(
        private readonly PlayerRepository $players,
        private readonly ZooAnimalRepository $zooAnimals,
        private readonly ExpeditionRepository $expeditions,
    ) {
    }

    /**
     * @return array{player: Player, zoo_value: int, animal_count: int, active_expeditions: int, pending_decisions: int}
     */
    public function overview(string $playerId): array
    {
        $player = $this->requirePlayer($playerId);
        $expeditions = $this->expeditions->forPlayer($playerId);

        return [
            'player' => $player,
            'zoo_value' => $this->zooAnimals->zooValue($player->zoo->id),
            'animal_count' => $this->zooAnimals->forZoo($player->zoo->id)->count(),
            'active_expeditions' => $expeditions
                ->filter(fn (Expedition $e) => ! $e->isResolved())
                ->count(),
            'pending_decisions' => $expeditions
                ->filter(fn (Expedition $e) => $e->awaitsDecision())
                ->count(),
        ];
    }

    /**
     * @return array{player: Player, animals: Collection<int, ZooAnimal>, zoo_value: int}
     */
    public function zoo(string $playerId): array
    {
        $player = $this->requirePlayer($playerId);

        return [
            'player' => $player,
            'animals' => $this->zooAnimals->forZoo($player->zoo->id),
            'zoo_value' => $this->zooAnimals->zooValue($player->zoo->id),
        ];
    }

    private function requirePlayer(string $playerId): Player
    {
        return $this->players->find($playerId)
            ?? throw ExpeditionRejected::because(
                ExpeditionRejected::PLAYER_NOT_FOUND,
                'No such player.'
            );
    }
}
