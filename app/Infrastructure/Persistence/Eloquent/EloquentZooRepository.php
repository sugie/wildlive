<?php

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Players\ZooRepository;
use App\Models\Player;
use App\Models\Zoo;

final class EloquentZooRepository implements ZooRepository
{
    public function createForPlayer(Player $player): Zoo
    {
        return Zoo::create(['player_id' => $player->id]);
    }
}
