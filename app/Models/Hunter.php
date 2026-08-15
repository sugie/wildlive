<?php

namespace App\Models;

/**
 * Game Master v0.3 — Hunters sheet.
 *
 * Hunters belong to the Guild pool and are NEVER owned by a player: a
 * player contracts one for a single expedition and pays `contract_cost_g`
 * once. There is deliberately no player_hunters table and no upkeep.
 *
 * `specialty` is a display label only. All gameplay maths uses the
 * structured fields (capture_bonus, rare_find_bonus, speed_bonus,
 * preferred_biome_id) — see Game Master HunterSkills.
 */
class Hunter extends MasterModel
{
    protected $table = 'hunters';

    protected $fillable = [
        'id', 'name', 'name_ja', 'rank', 'level', 'specialty', 'preferred_biome_id',
        'capture_bonus', 'rare_find_bonus', 'speed_bonus', 'contract_cost_g',
        'personality', 'description',
    ];

    protected function casts(): array
    {
        return [
            'level' => 'integer',
            'capture_bonus' => 'integer',
            'rare_find_bonus' => 'integer',
            'speed_bonus' => 'integer',
            'contract_cost_g' => 'integer',
        ];
    }
}
