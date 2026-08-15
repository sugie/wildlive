<?php

namespace App\Models;

/** Game Master v0.3 — Biomes sheet. */
class Biome extends MasterModel
{
    protected $table = 'biomes';

    protected $fillable = [
        'id', 'name_en', 'name_ja', 'description_en', 'description_ja',
    ];
}
