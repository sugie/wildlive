<?php

namespace App\Http\Resources;

use App\Models\Zoo;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Zoo */
class ZooResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
