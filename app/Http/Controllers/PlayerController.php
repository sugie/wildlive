<?php

namespace App\Http\Controllers;

use App\Http\Requests\RegisterPlayerRequest;
use App\Http\Resources\PlayerResource;
use App\Http\Resources\ZooResource;
use App\Models\Player;
use App\Models\Zoo;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class PlayerController extends Controller
{
    /**
     * Create the first-time Player (with its owning Zoo) in one transaction.
     *
     * ER_MODEL.md §C1 requires Player and Zoo be created atomically so a Player
     * never exists without a Zoo (or vice versa). The DB::transaction closure
     * plus UNIQUE(zoos.player_id) NOT NULL enforce that invariant.
     */
    public function store(RegisterPlayerRequest $request): JsonResponse
    {
        [$player, $zoo] = DB::transaction(function () use ($request) {
            $player = Player::create([
                'display_name' => $request->string('display_name')->trim()->value(),
            ]);
            $zoo = Zoo::create(['player_id' => $player->id]);
            return [$player, $zoo];
        });

        return response()->json([
            'player' => (new PlayerResource($player))->toArray($request),
            'zoo' => (new ZooResource($zoo))->toArray($request),
        ], 201);
    }
}
