<?php

namespace App\Http\Controllers;

use App\Application\Game\ViewGameCatalog;
use App\Http\Resources\HunterResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Presentation Layer for the Guild's Hunter pool.
 *
 * The pool is not player-scoped — no player owns a Hunter — so this route
 * sits at /api/hunters. Pass ?map_id= to have each Hunter annotated with
 * what they would cost and how long they would take on that Map.
 */
final class HunterController extends Controller
{
    public function __construct(
        private readonly ViewGameCatalog $catalog,
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $mapId = $request->query('map_id');
        $mapId = is_string($mapId) && $mapId !== '' ? $mapId : null;

        $entries = $this->catalog->huntersFor($mapId);

        return response()->json([
            'map_id' => $mapId,
            'hunters' => array_map(
                fn (array $entry) => (new HunterResource($entry['hunter'], $entry))->toArray($request),
                $entries
            ),
        ]);
    }
}
