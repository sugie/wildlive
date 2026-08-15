<?php

namespace App\Http\Resources;

use App\Models\Player;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Everything Home needs about the signed-in player in one payload.
 *
 * Wraps the existing PlayerResource rather than re-listing its fields, so
 * the registration response and this response cannot drift apart.
 */
class PlayerOverviewResource extends JsonResource
{
    /**
     * @param  array{player: Player, zoo_value: int, animal_count: int, active_expeditions: int, pending_decisions: int}  $overview
     */
    public function __construct(
        private readonly array $overview,
    ) {
        parent::__construct($overview['player']);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Player $player */
        $player = $this->overview['player'];

        return [
            'player' => (new PlayerResource($player))->toArray($request),
            'zoo' => [
                'id' => $player->zoo?->id,
                'zoo_value' => $this->overview['zoo_value'],
                'animal_count' => $this->overview['animal_count'],
            ],
            'expeditions' => [
                'active' => $this->overview['active_expeditions'],
                'pending_decisions' => $this->overview['pending_decisions'],
            ],
        ];
    }
}
