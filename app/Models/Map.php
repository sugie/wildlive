<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Game Master v0.3 — Maps sheet.
 *
 * The vertical slice ships only `availability_phase = initial_africa`
 * (nine African maps). `future_expansion` rows are seeded so the master
 * data stays a faithful copy of the workbook, but they are filtered out of
 * every player-facing query.
 */
class Map extends MasterModel
{
    protected $table = 'maps';

    protected $fillable = [
        'id', 'name_en', 'name_ja', 'region', 'biome_id', 'availability_phase',
        'map_role', 'unlock_rule', 'unlock_value', 'recommended_hunter_rank',
        'minimum_hunter_rank_gate', 'difficulty', 'expedition_minutes',
        'base_cost_g', 'risk_level', 'description_en', 'description_ja',
    ];

    protected function casts(): array
    {
        return [
            'unlock_value' => 'integer',
            'recommended_hunter_rank' => 'integer',
            'minimum_hunter_rank_gate' => 'integer',
            'difficulty' => 'integer',
            'expedition_minutes' => 'integer',
            'base_cost_g' => 'integer',
            'risk_level' => 'integer',
        ];
    }

    public function biome(): BelongsTo
    {
        return $this->belongsTo(Biome::class);
    }

    public function mapAnimals(): HasMany
    {
        return $this->hasMany(MapAnimal::class);
    }
}
