<?php

namespace App\Http\Resources;

use App\Models\Animal;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A species from Game Master v0.3 — Animals sheet.
 *
 * Field names mirror the workbook columns so a reviewer can hold the
 * spreadsheet next to the JSON and read straight across.
 *
 * @mixin Animal
 */
class AnimalResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name_en' => $this->name_en,
            'name_ja' => $this->name_ja,
            'category' => $this->category,
            'rarity' => [
                'id' => $this->rarity->id,
                'name_en' => $this->rarity->name_en,
                'name_ja' => $this->rarity->name_ja,
                'sort_order' => (int) $this->rarity->sort_order,
            ],
            'base_zoo_value' => (int) $this->base_zoo_value,
            'capture_difficulty' => (int) $this->capture_difficulty,
            'visitor_appeal' => (int) $this->visitor_appeal,
            'habitat_biome_id' => $this->habitat_biome_id,
            'size' => $this->size,
            'active_time' => $this->active_time,
            'description_en' => $this->description_en,
            'description_ja' => $this->description_ja,
        ];
    }
}
