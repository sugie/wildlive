<?php

namespace App\Http\Controllers;

use App\Application\Game\ViewGameCatalog;
use App\Http\Resources\MapResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Presentation Layer for the Map catalogue.
 *
 * No game rules here: which maps exist, and whether this player has
 * unlocked them, are both decided by ViewGameCatalog.
 */
final class MapController extends Controller
{
    public function __construct(
        private readonly ViewGameCatalog $catalog,
    ) {
    }

    public function index(Request $request, string $playerId): JsonResponse
    {
        $result = $this->catalog->mapsFor($playerId);

        return response()->json([
            'zoo_value' => $result['zoo_value'],
            'maps' => array_map(
                fn (array $entry) => (new MapResource($entry['map'], $entry['unlocked']))->toArray($request),
                $result['maps']
            ),
        ]);
    }

    public function show(Request $request, string $playerId, string $mapId): JsonResponse
    {
        $result = $this->catalog->mapDetailFor($playerId, $mapId);

        return response()->json([
            'zoo_value' => $result['zoo_value'],
            'map' => (new MapResource($result['map'], $result['unlocked'], withAnimals: true))
                ->toArray($request),
        ]);
    }
}
