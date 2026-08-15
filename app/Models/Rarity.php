<?php

namespace App\Models;

/**
 * Game Master v0.3 — Rarities sheet.
 *
 * Five tiers, ordered by `sort_order` (1 = Common … 5 = Legendary).
 * `sort_order` is what the encounter table uses to bias a Hunter's
 * rare_find_bonus toward rarer species; `base_multiplier` is reserved for
 * a later economy pass and is not used by the vertical slice.
 */
class Rarity extends MasterModel
{
    protected $table = 'rarities';

    protected $fillable = [
        'id', 'name_en', 'name_ja', 'sort_order', 'base_multiplier', 'description',
    ];

    protected function casts(): array
    {
        return [
            'sort_order' => 'integer',
            'base_multiplier' => 'float',
        ];
    }
}
