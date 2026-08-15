<?php

namespace App\Http\Controllers;

use App\Application\Players\ViewPlayerProfile;
use App\Http\Resources\ZooAnimalResource;
use App\Models\ZooAnimal;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Presentation Layer for My Zoo.
 *
 * Everything here comes from PostgreSQL. There is no client-side zoo.
 */
final class ZooController extends Controller
{
    public function __construct(
        private readonly ViewPlayerProfile $profile,
    ) {
    }

    public function show(Request $request, string $playerId): JsonResponse
    {
        $result = $this->profile->zoo($playerId);

        return response()->json([
            'zoo' => [
                'id' => $result['player']->zoo?->id,
                'zoo_value' => $result['zoo_value'],
                'animal_count' => $result['animals']->count(),
            ],
            'animals' => $result['animals']
                ->map(fn (ZooAnimal $animal) => (new ZooAnimalResource($animal))->toArray($request))
                ->values()
                ->all(),
        ]);
    }
}
