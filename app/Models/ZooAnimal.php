<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

/**
 * An individual animal living in a player's Zoo.
 *
 * Created only by the KEEP branch of an expedition decision. Its species
 * data (rarity, zoo value, description) is never copied here — it is read
 * through `animal_id`, so a master-data correction reaches existing zoos.
 */
class ZooAnimal extends Model
{
    use HasUuids;

    protected $fillable = [
        'zoo_id', 'animal_id', 'name', 'expedition_id',
        'captured_from_map_id', 'captured_by_hunter_id', 'captured_at',
    ];

    protected function casts(): array
    {
        return [
            'captured_at' => 'datetime',
        ];
    }

    public function newUniqueId(): string
    {
        return (string) Str::orderedUuid();
    }

    /** @return array<int, string> */
    public function uniqueIds(): array
    {
        return ['id'];
    }

    public function zoo(): BelongsTo
    {
        return $this->belongsTo(Zoo::class);
    }

    public function animal(): BelongsTo
    {
        return $this->belongsTo(Animal::class);
    }

    public function expedition(): BelongsTo
    {
        return $this->belongsTo(Expedition::class);
    }

    public function capturedFromMap(): BelongsTo
    {
        return $this->belongsTo(Map::class, 'captured_from_map_id');
    }

    public function capturedByHunter(): BelongsTo
    {
        return $this->belongsTo(Hunter::class, 'captured_by_hunter_id');
    }
}
