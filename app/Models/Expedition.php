<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

/**
 * A single dispatched expedition.
 *
 * State lives in three columns rather than one enum — see the migration
 * for why. The constants below are the only legal values; the Application
 * Layer is responsible for the transitions.
 */
class Expedition extends Model
{
    use HasUuids;

    public const STATUS_IN_PROGRESS = 'in_progress';
    public const STATUS_RESOLVED = 'resolved';

    public const OUTCOME_CAPTURED = 'captured';
    public const OUTCOME_NO_CAPTURE = 'no_capture';

    public const DECISION_KEPT = 'kept';
    public const DECISION_RELEASED = 'released';

    protected $fillable = [
        'player_id', 'map_id', 'hunter_id',
        'map_cost_g', 'contract_cost_g', 'total_cost_g', 'planned_duration_minutes',
        'status', 'outcome', 'decision', 'encountered_animal_id',
        'capture_chance_percent', 'capture_roll', 'encounter_roll',
        'dev_instant_resolve', 'started_at', 'ends_at', 'resolved_at', 'decided_at',
    ];

    protected function casts(): array
    {
        return [
            'map_cost_g' => 'integer',
            'contract_cost_g' => 'integer',
            'total_cost_g' => 'integer',
            'planned_duration_minutes' => 'integer',
            'capture_chance_percent' => 'integer',
            'capture_roll' => 'integer',
            'encounter_roll' => 'integer',
            'dev_instant_resolve' => 'boolean',
            'started_at' => 'datetime',
            'ends_at' => 'datetime',
            'resolved_at' => 'datetime',
            'decided_at' => 'datetime',
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

    public function player(): BelongsTo
    {
        return $this->belongsTo(Player::class);
    }

    public function map(): BelongsTo
    {
        return $this->belongsTo(Map::class);
    }

    public function hunter(): BelongsTo
    {
        return $this->belongsTo(Hunter::class);
    }

    public function encounteredAnimal(): BelongsTo
    {
        return $this->belongsTo(Animal::class, 'encountered_animal_id');
    }

    public function zooAnimal(): HasOne
    {
        return $this->hasOne(ZooAnimal::class);
    }

    public function isResolved(): bool
    {
        return $this->resolved_at !== null;
    }

    public function isDecided(): bool
    {
        return $this->decided_at !== null;
    }

    /** True once ends_at has passed — i.e. the outcome may now be computed. */
    public function isDue(): bool
    {
        return $this->ends_at !== null && $this->ends_at->isPast();
    }

    /** A captured animal that the player has not yet kept or released. */
    public function awaitsDecision(): bool
    {
        return $this->outcome === self::OUTCOME_CAPTURED && ! $this->isDecided();
    }
}
