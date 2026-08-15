<?php

namespace App\Domain\Game;

use App\Domain\Support\RandomSource;
use App\Models\MapAnimal;

/**
 * Which species the Hunter runs into.
 *
 * Candidates come from the Map's MapAnimals rows — nothing else can ever
 * be encountered, which is what keeps the Northern White Rhinoceros
 * (special_event, no spawn row) out of normal play.
 *
 * Each candidate's base chance is its `spawn_weight`. A Hunter's
 * `rare_find_bonus` then tilts the table toward rarer species:
 *
 *     weight = spawn_weight × ((100 + rare_find_bonus) / 100) ^ (sort_order − 1)
 *
 * where `sort_order` is the Rarity tier (1 Common … 5 Legendary). The
 * exponent is what makes the bias compound with rarity: at +30, a Common
 * is untouched, an Uncommon is ×1.3, a Legendary is ×2.86. At 0 the table
 * is exactly the raw spawn weights; a negative bonus pushes toward Common.
 *
 * This is the ONLY thing rare_find_bonus does. It never touches capture
 * success — a rare-find Hunter finds rarer animals, which are then harder
 * to catch, not easier (Game Master v0.3, HunterSkills.skill_rare_find_bonus).
 *
 * Weights are computed in scaled integer arithmetic so the same inputs
 * always produce byte-identical weights and a test can assert on them.
 */
final class EncounterTable
{
    /** Fixed-point scale for the weight arithmetic (3 decimal places). */
    private const SCALE = 1000;

    public function __construct(
        private readonly RandomSource $random,
    ) {
    }

    /**
     * Scaled integer weight per candidate, keyed by MapAnimal id.
     *
     * @param  array<int, MapAnimal>  $candidates  each with animal.rarity loaded
     * @return array<string, int>
     */
    public function weights(array $candidates, int $rareFindBonus): array
    {
        // HunterSkills bounds rare_find_bonus to [-20, +30]; clamping here
        // keeps a bad master-data edit from producing a zero or negative
        // multiplier base rather than a silently strange table.
        $base = max(1, 100 + $rareFindBonus);

        $weights = [];
        foreach ($candidates as $candidate) {
            $sortOrder = (int) $candidate->animal->rarity->sort_order;
            $steps = max(0, $sortOrder - 1);

            $numerator = (int) $candidate->spawn_weight * self::SCALE;
            $denominator = 1;
            for ($i = 0; $i < $steps; $i++) {
                $numerator *= $base;
                $denominator *= 100;
            }

            $weights[$candidate->id] = (int) round($numerator / $denominator);
        }

        return $weights;
    }

    /**
     * Draw one candidate.
     *
     * Returns the chosen MapAnimal and the roll that produced it, so the
     * expedition row can record how the encounter was decided.
     *
     * @param  array<int, MapAnimal>  $candidates
     * @return array{candidate: MapAnimal, roll: int, total_weight: int}
     */
    public function draw(array $candidates, int $rareFindBonus): array
    {
        if ($candidates === []) {
            throw new \InvalidArgumentException('Cannot draw an encounter from an empty candidate list.');
        }

        $weights = $this->weights($candidates, $rareFindBonus);
        $total = array_sum($weights);

        if ($total <= 0) {
            throw new \InvalidArgumentException('Encounter candidates have no positive spawn weight.');
        }

        $roll = $this->random->int(1, $total);

        $cursor = 0;
        foreach ($candidates as $candidate) {
            $cursor += $weights[$candidate->id];
            if ($roll <= $cursor) {
                return ['candidate' => $candidate, 'roll' => $roll, 'total_weight' => $total];
            }
        }

        // Unreachable while $roll <= $total; kept so a future rounding
        // change fails loudly at the boundary instead of returning null.
        $last = $candidates[array_key_last($candidates)];

        return ['candidate' => $last, 'roll' => $roll, 'total_weight' => $total];
    }
}
