<?php

namespace App\Http\Resources;

use App\Models\Player;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Player */
class PlayerResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'display_name' => $this->display_name,
            'g_balance' => (int) $this->g_balance,
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
