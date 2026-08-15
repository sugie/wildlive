<?php

namespace App\Domain\Game;

use App\Domain\Support\RandomSource;
use App\Models\Hunter;
use App\Models\Map;
use App\Models\MapAnimal;

/**
 * Whether the encountered animal is actually caught.
 *
 * Resolution is discovery-first: EncounterTable picks WHAT was found, then
 * this decides WHETHER it was caught. The two are independent by design —
 * `rare_find_bonus` appears nowhere in this file, and that absence is the
 * rule (Game Master v0.3: rare_find_bonus biases encounters, not captures).
 *
 * Chance, in percentage points:
 *
 *     60                                  base success rate
 *   −  8 × (Map.difficulty − 1)           harder terrain
 *   −  8 × (Animal.capture_difficulty − 1) harder quarry
 *   +  Hunter.capture_bonus               skill
 *   +  10 if Hunter.preferred_biome_id == Map.biome_id
 *   +  MapAnimal.capture_modifier         per-placement tweak (e.g. Okapi −15)
 *   clamped to [5, 95]
 *
 * A single attempt per expedition (expedition_rule_base_capture_attempts = 1).
 * Failure costs nothing beyond the already-sunk dispatch and contract G.
 */
final class CaptureResolver
{
    public function __construct(
        private readonly RandomSource $random,
        private readonly ExpeditionPlanner $planner,
    ) {
    }

    /** The capture chance in whole percentage points, already clamped. */
    public function chancePercent(Map $map, Hunter $hunter, MapAnimal $placement): int
    {
        $chance = ExpeditionBalance::BASE_SUCCESS_PERCENT;

        $chance -= ExpeditionBalance::DIFFICULTY_PENALTY_PER_POINT * ((int) $map->difficulty - 1);
        $chance -= ExpeditionBalance::ANIMAL_DIFFICULTY_PENALTY_PER_POINT
            * ((int) $placement->animal->capture_difficulty - 1);

        $chance += (int) $hunter->capture_bonus;

        if ($this->planner->hasBiomeAffinity($map, $hunter)) {
            $chance += ExpeditionBalance::BIOME_AFFINITY_BONUS;
        } else {
            $chance -= ExpeditionBalance::BIOME_MISMATCH_PENALTY;
        }

        $chance += (int) $placement->capture_modifier;

        return max(
            ExpeditionBalance::MIN_CAPTURE_PERCENT,
            min(ExpeditionBalance::MAX_CAPTURE_PERCENT, $chance)
        );
    }

    /**
     * Roll for the capture.
     *
     * A d100: the attempt succeeds when the roll is at or below the chance,
     * so `chance` reads directly as "this many rolls in a hundred succeed".
     *
     * @return array{captured: bool, chance_percent: int, roll: int}
     */
    public function attempt(Map $map, Hunter $hunter, MapAnimal $placement): array
    {
        $chance = $this->chancePercent($map, $hunter, $placement);
        $roll = $this->random->int(1, 100);

        return [
            'captured' => $roll <= $chance,
            'chance_percent' => $chance,
            'roll' => $roll,
        ];
    }
}
