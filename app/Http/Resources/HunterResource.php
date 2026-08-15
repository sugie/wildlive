<?php

namespace App\Http\Resources;

use App\Models\Hunter;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A Hunter from the Guild pool.
 *
 * There is no "owned" or "available" flag, and that is the point: Hunters
 * are contracted per expedition and belong to no one (Game Master v0.3).
 *
 * The `for_map` block appears when the client asked about a specific Map,
 * and answers the two questions a player actually has at the Guild —
 * what will this cost me, and how long will it take.
 *
 * @mixin Hunter
 */
class HunterResource extends JsonResource
{
    /**
     * @param  array{biome_affinity: bool, total_cost_g: int|null, duration_minutes: int|null}|null  $context
     */
    public function __construct(
        Hunter $hunter,
        private readonly ?array $context = null,
    ) {
        parent::__construct($hunter);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $payload = [
            'id' => $this->id,
            'name' => $this->name,
            'name_ja' => $this->name_ja,
            'rank' => $this->rank,
            'level' => (int) $this->level,
            'specialty' => $this->specialty,
            'preferred_biome_id' => $this->preferred_biome_id,
            'capture_bonus' => (int) $this->capture_bonus,
            'rare_find_bonus' => (int) $this->rare_find_bonus,
            'speed_bonus' => (int) $this->speed_bonus,
            'contract_cost_g' => (int) $this->contract_cost_g,
            'personality' => $this->personality,
            'description' => $this->description,
        ];

        if ($this->context !== null && $this->context['total_cost_g'] !== null) {
            $payload['for_map'] = [
                'biome_affinity' => (bool) $this->context['biome_affinity'],
                'total_cost_g' => (int) $this->context['total_cost_g'],
                'duration_minutes' => (int) $this->context['duration_minutes'],
            ];
        }

        return $payload;
    }
}
