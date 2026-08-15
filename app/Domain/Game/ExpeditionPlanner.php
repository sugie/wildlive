<?php

namespace App\Domain\Game;

use App\Models\Hunter;
use App\Models\Map;

/**
 * Everything that must be decided BEFORE an expedition is dispatched:
 * is this map open to this player, what does it cost, how long does it run.
 *
 * Pure functions over master-data rows. No database access, no clock, no
 * randomness — so every rule here is unit-testable with hand-built models.
 *
 * The Eloquent models are used as plain typed row containers (they can be
 * `new`ed without a database connection). That follows the convention this
 * repository already set for PlayerRepository rather than introducing a
 * parallel set of Domain structs that would carry the same five fields.
 */
final class ExpeditionPlanner
{
    /**
     * Is this map playable at all in the current release?
     *
     * Game Master v0.3 ships Africa first; `future_expansion` maps are
     * seeded for fidelity with the workbook but are never dispatchable.
     */
    public function isReleased(Map $map): bool
    {
        return $map->availability_phase === 'initial_africa';
    }

    /**
     * Has this player met the map's unlock condition?
     *
     * Game Master v0.3 uses two live rules:
     *   `always`      — open from registration (the starter map)
     *   `zoo_value`   — open once the player's Zoo is worth `unlock_value`
     *
     * Unlocking depends only on Zoo value. It is deliberately independent
     * of which Hunters exist or which Hunter a player can afford: Hunters
     * are contracted per expedition and are not a progression gate.
     */
    public function isUnlocked(Map $map, int $zooValue): bool
    {
        if (! $this->isReleased($map)) {
            return false;
        }

        return match ($map->unlock_rule) {
            'always' => true,
            'zoo_value' => $zooValue >= (int) $map->unlock_value,
            default => false,
        };
    }

    /**
     * Total G debited when the expedition is dispatched.
     *
     * Both halves are sunk immediately (Game Master v0.3): a failed capture
     * refunds nothing and adds no further penalty.
     */
    public function totalCostG(Map $map, Hunter $hunter): int
    {
        return (int) $map->base_cost_g + (int) $hunter->contract_cost_g;
    }

    /**
     * Expedition duration in minutes.
     *
     * Canonical Map.expedition_minutes reduced by the Hunter's speed_bonus
     * percentage, then clamped to the Game Master's absolute floor and
     * ceiling. A negative speed_bonus lengthens the trip, which is how
     * rare-find specialists pay for their bias.
     *
     * Rounding is half-up on the reduced value, so a 20-minute map with a
     * +25% speed Hunter is 15 minutes rather than 15.0000001.
     */
    public function durationMinutes(Map $map, Hunter $hunter): int
    {
        $base = (int) $map->expedition_minutes;
        $factor = (100 - (int) $hunter->speed_bonus) / 100;

        $minutes = (int) round($base * $factor);

        return max(
            ExpeditionBalance::MIN_EXPEDITION_MINUTES,
            min(ExpeditionBalance::MAX_EXPEDITION_MINUTES, $minutes)
        );
    }

    /**
     * Does this Hunter's preferred biome match the Map's biome?
     *
     * `any` means "no matching bonus and no mismatch penalty" — it is not
     * a wildcard that always matches (Game Master HunterSkills:
     * skill_biome_affinity).
     */
    public function hasBiomeAffinity(Map $map, Hunter $hunter): bool
    {
        if ($hunter->preferred_biome_id === 'any') {
            return false;
        }

        return $hunter->preferred_biome_id === $map->biome_id;
    }
}
