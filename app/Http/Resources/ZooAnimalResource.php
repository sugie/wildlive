<?php

namespace App\Http\Resources;

use App\Models\ZooAnimal;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * An individual animal in a player's Zoo.
 *
 * Carries the three things My Zoo must show — assigned name, species,
 * rarity — plus the provenance that makes each one a story.
 *
 * @mixin ZooAnimal
 */
class ZooAnimalResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'species' => (new AnimalResource($this->animal))->toArray($request),
            'captured_at' => $this->captured_at?->toISOString(),
            'captured_from_map_id' => $this->captured_from_map_id,
            'captured_by_hunter_id' => $this->captured_by_hunter_id,
            'expedition_id' => $this->expedition_id,
        ];
    }
}
