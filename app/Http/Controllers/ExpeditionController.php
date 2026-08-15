<?php

namespace App\Http\Controllers;

use App\Application\Expeditions\DecideCapturedAnimal;
use App\Application\Expeditions\ResolveExpedition;
use App\Application\Expeditions\StartExpedition;
use App\Application\Expeditions\StartExpeditionInput;
use App\Application\Expeditions\ViewExpeditions;
use App\Http\Requests\KeepCapturedAnimalRequest;
use App\Http\Requests\StartExpeditionRequest;
use App\Http\Resources\ExpeditionResource;
use App\Models\Expedition;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Presentation Layer for the expedition loop.
 *
 * Every action is one line of workflow: map the request into an
 * Application Layer call and shape the result. No rule, no roll, no
 * transaction, and no Eloquent query lives in this file — the routes are
 * nested under /players/{player} so ownership is explicit in the URL and
 * checked in the Application Layer.
 *
 * Refusals (locked map, insufficient G, already decided, …) are thrown as
 * ExpeditionRejected and turned into HTTP status codes by the handler
 * registered in bootstrap/app.php, so no try/catch is needed here.
 */
final class ExpeditionController extends Controller
{
    public function __construct(
        private readonly StartExpedition $start,
        private readonly ResolveExpedition $resolve,
        private readonly DecideCapturedAnimal $decide,
        private readonly ViewExpeditions $view,
    ) {
    }

    public function index(Request $request, string $playerId): JsonResponse
    {
        $expeditions = $this->view->forPlayer($playerId);

        return response()->json([
            'expeditions' => $expeditions
                ->map(fn (Expedition $e) => (new ExpeditionResource($e))->toArray($request))
                ->values()
                ->all(),
        ]);
    }

    public function store(StartExpeditionRequest $request, string $playerId): JsonResponse
    {
        $expedition = ($this->start)(new StartExpeditionInput(
            playerId: $playerId,
            mapId: $request->string('map_id')->trim()->value(),
            hunterId: $request->string('hunter_id')->trim()->value(),
            devInstantResolve: $request->boolean('dev_instant_resolve'),
        ));

        return $this->single($request, $expedition, 201);
    }

    /**
     * Fetching an expedition settles it if it is due — the lazy resolution
     * described in docs/ARCHITECTURE.md.
     */
    public function show(Request $request, string $playerId, string $expeditionId): JsonResponse
    {
        return $this->single($request, $this->view->one($playerId, $expeditionId));
    }

    public function resolve(Request $request, string $playerId, string $expeditionId): JsonResponse
    {
        return $this->single($request, ($this->resolve)($playerId, $expeditionId));
    }

    public function keep(
        KeepCapturedAnimalRequest $request,
        string $playerId,
        string $expeditionId,
    ): JsonResponse {
        $name = $request->has('name')
            ? $request->string('name')->trim()->value()
            : null;

        return $this->single($request, $this->decide->keep($playerId, $expeditionId, $name));
    }

    public function release(Request $request, string $playerId, string $expeditionId): JsonResponse
    {
        return $this->single($request, $this->decide->release($playerId, $expeditionId));
    }

    private function single(Request $request, Expedition $expedition, int $status = 200): JsonResponse
    {
        return response()->json(
            ['expedition' => (new ExpeditionResource($expedition))->toArray($request)],
            $status
        );
    }
}
