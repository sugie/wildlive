<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Game Master v0.3 — MapAnimals sheet: which species can appear on which
 * map, with what spawn weight and per-placement capture modifier.
 *
 * This table is the *only* source of encounter candidates. A species with
 * no row here can never be encountered — which is how the Northern White
 * Rhinoceros stays a non-spawning special-event animal.
 */
class MapAnimal extends MasterModel
{
    protected $table = 'map_animals';

    protected $fillable = [
        'id', 'map_id', 'animal_id', 'spawn_weight', 'capture_modifier',
        'needs_review', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'spawn_weight' => 'integer',
            'capture_modifier' => 'integer',
            'needs_review' => 'boolean',
        ];
    }

    public function map(): BelongsTo
    {
        return $this->belongsTo(Map::class);
    }

    public function animal(): BelongsTo
    {
        return $this->belongsTo(Animal::class);
    }
}
