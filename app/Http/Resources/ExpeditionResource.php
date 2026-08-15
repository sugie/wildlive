<?php

namespace App\Http\Resources;

use App\Models\Expedition;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A dispatched expedition, in whatever state it is currently in.
 *
 * `resolution` is present only once the outcome exists, and includes the
 * chance and the roll. Showing the maths is deliberate: the client can
 * explain to a player why a capture failed, and a reviewer can check that
 * rare_find_bonus never appears in the capture calculation.
 *
 * `dev_instant_resolve` is echoed on every expedition, so a shortened
 * development expedition is impossible to mistake for a real one.
 *
 * @mixin Expedition
 */
class ExpeditionResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $payload = [
            'id' => $this->id,
            'player_id' => $this->player_id,
            'status' => $this->status,
            'outcome' => $this->outcome,
            'decision' => $this->decision,
            'map' => [
                'id' => $this->map->id,
                'name_en' => $this->map->name_en,
                'name_ja' => $this->map->name_ja,
                'biome_id' => $this->map->biome_id,
                'difficulty' => (int) $this->map->difficulty,
                'expedition_minutes' => (int) $this->map->expedition_minutes,
            ],
            'hunter' => [
                'id' => $this->hunter->id,
                'name' => $this->hunter->name,
                'name_ja' => $this->hunter->name_ja,
                'rank' => $this->hunter->rank,
                'specialty' => $this->hunter->specialty,
            ],
            'cost' => [
                'map_cost_g' => (int) $this->map_cost_g,
                'contract_cost_g' => (int) $this->contract_cost_g,
                'total_cost_g' => (int) $this->total_cost_g,
            ],
            'planned_duration_minutes' => (int) $this->planned_duration_minutes,
            'dev_instant_resolve' => (bool) $this->dev_instant_resolve,
            'started_at' => $this->started_at?->toISOString(),
            'ends_at' => $this->ends_at?->toISOString(),
            'resolved_at' => $this->resolved_at?->toISOString(),
            'decided_at' => $this->decided_at?->toISOString(),
            'is_due' => $this->isDue(),
            'awaits_decision' => $this->awaitsDecision(),
        ];

        if ($this->isResolved()) {
            $payload['resolution'] = [
                'encountered_animal' => $this->encounteredAnimal
                    ? (new AnimalResource($this->encounteredAnimal))->toArray($request)
                    : null,
                'capture_chance_percent' => (int) $this->capture_chance_percent,
                'capture_roll' => (int) $this->capture_roll,
                'encounter_roll' => (int) $this->encounter_roll,
            ];
        }

        $payload['zoo_animal'] = $this->zooAnimal
            ? (new ZooAnimalResource($this->zooAnimal->loadMissing('animal.rarity')))->toArray($request)
            : null;

        return $payload;
    }
}
