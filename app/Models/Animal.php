<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Game Master v0.3 — Animals sheet (a species, not an individual).
 *
 * An individual animal owned by a player is a ZooAnimal, which references
 * this row through `animal_id`.
 */
class Animal extends MasterModel
{
    protected $table = 'animals';

    protected $fillable = [
        'id', 'name_en', 'name_ja', 'category', 'rarity_id', 'availability_phase',
        'placement_note', 'base_zoo_value', 'capture_difficulty', 'growth_rate',
        'visitor_appeal', 'habitat_biome_id', 'size', 'active_time',
        'description_en', 'description_ja',
    ];

    protected function casts(): array
    {
        return [
            'base_zoo_value' => 'integer',
            'capture_difficulty' => 'integer',
            'growth_rate' => 'integer',
            'visitor_appeal' => 'integer',
        ];
    }

    public function rarity(): BelongsTo
    {
        return $this->belongsTo(Rarity::class);
    }

    public function habitatBiome(): BelongsTo
    {
        return $this->belongsTo(Biome::class, 'habitat_biome_id');
    }
}
