<?php

namespace App\Http\Controllers;

use App\Application\Players\RegisterPlayer;
use App\Application\Players\RegisterPlayerInput;
use App\Http\Requests\RegisterPlayerRequest;
use App\Http\Resources\PlayerResource;
use App\Http\Resources\ZooResource;
use Illuminate\Http\JsonResponse;

/**
 * Presentation Layer entry point for player registration.
 *
 * The controller intentionally holds no business rules: it validates
 * (via RegisterPlayerRequest), maps the HTTP payload into a
 * framework-free RegisterPlayerInput, delegates the atomic Player + Zoo
 * creation to the RegisterPlayer application-layer use case, and shapes
 * the response with API Resources.
 *
 * The controller must NOT call Eloquent (Player::/Zoo::) directly, must
 * NOT open a DB transaction, and must NOT encode the Player + Zoo 1:1
 * invariant — those live in the Application Layer.
 */
final class PlayerController extends Controller
{
    public function __construct(
        private readonly RegisterPlayer $registerPlayer,
    ) {
    }

    public function store(RegisterPlayerRequest $request): JsonResponse
    {
        $input = new RegisterPlayerInput(
            displayName: $request->string('display_name')->trim()->value(),
        );

        $result = ($this->registerPlayer)($input);

        return response()->json([
            'player' => (new PlayerResource($result->player))->toArray($request),
            'zoo' => (new ZooResource($result->zoo))->toArray($request),
        ], 201);
    }
}
