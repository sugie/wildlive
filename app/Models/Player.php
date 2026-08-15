<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class Player extends Model
{
    use HasUuids;

    protected $fillable = ['display_name'];

    /**
     * Use a time-ordered UUID (Timestamp-based v4) so the primary key
     * stays index-friendly while remaining non-enumerable when exposed
     * to clients.
     */
    public function newUniqueId(): string
    {
        return (string) Str::orderedUuid();
    }

    /** @return array<int, string> */
    public function uniqueIds(): array
    {
        return ['id'];
    }

    public function zoo(): HasOne
    {
        return $this->hasOne(Zoo::class);
    }
}
