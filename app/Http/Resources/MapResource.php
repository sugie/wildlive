<?php

namespace App\Http\Resources;

use App\Models\Map;
use App\Models\MapAnimal;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A Map from Game Master v0.3 — Maps sheet.
 *
 * `unlocked` is not a master-data column: it is computed per player by
 * ViewGameCatalog and passed in, because whether a map is open depends on
 * who is asking.
 *
 * `animals` is present only on the detail endpoint (when the spawn table
 * was eager-loaded), so the list response stays small.
 *
 * @mixin Map
 */
class MapResource extends JsonResource
{
    public function __construct(
        Map $map,
        private readonly bool $unlocked,
        private readonly bool $withAnimals = false,
    ) {
        parent::__construct($map);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $payload = [
            'id' => $this->id,
            'name_en' => $this->name_en,
            'name_ja' => $this->name_ja,
            'region' => $this->region,
            'biome_id' => $this->biome_id,
            'map_role' => $this->map_role,
            'availability_phase' => $this->availability_phase,
            'difficulty' => (int) $this->difficulty,
            'risk_level' => (int) $this->risk_level,
            'expedition_minutes' => (int) $this->expedition_minutes,
            'base_cost_g' => (int) $this->base_cost_g,
            'recommended_hunter_rank' => (int) $this->recommended_hunter_rank,
            'unlock_rule' => $this->unlock_rule,
            'unlock_value' => (int) $this->unlock_value,
            'unlocked' => $this->unlocked,
            'description_en' => $this->description_en,
            'description_ja' => $this->description_ja,
        ];

        if ($this->withAnimals) {
            $payload['animals'] = $this->mapAnimals
                ->map(fn (MapAnimal $placement) => [
                    'spawn_weight' => (int) $placement->spawn_weight,
                    'capture_modifier' => (int) $placement->capture_modifier,
                    'notes' => $placement->notes,
                    'animal' => (new AnimalResource($placement->animal))->toArray($request),
                ])
                ->values()
                ->all();
        }

        return $payload;
    }
}
