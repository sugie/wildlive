<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Zoo extends Model
{
    use HasUuids;

    protected $fillable = ['player_id'];

    public function newUniqueId(): string
    {
        return (string) Str::orderedUuid();
    }

    /** @return array<int, string> */
    public function uniqueIds(): array
    {
        return ['id'];
    }

    public function player(): BelongsTo
    {
        return $this->belongsTo(Player::class);
    }

    public function animals(): HasMany
    {
        return $this->hasMany(ZooAnimal::class);
    }
}
