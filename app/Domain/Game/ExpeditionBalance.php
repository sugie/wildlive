<?php

namespace App\Domain\Game;

/**
 * The numeric knobs of expedition resolution, in one readable place.
 *
 * Two kinds of value live here and they are labelled as such:
 *
 *  A. GAME MASTER v0.3 values, copied from the ExpeditionRules sheet.
 *     Changing one of these here without changing the workbook is a bug.
 *
 *  B. VERTICAL-SLICE values, which Game Master v0.3 does not yet fix.
 *     The workbook states a base success rate, a biome affinity bonus and
 *     a mismatch penalty, but never says how much Map.difficulty or
 *     Animal.capture_difficulty should cost. Without some value the
 *     capture formula cannot be written at all, so the slice picks one and
 *     flags it. These are open game-design questions, not decisions —
 *     see docs/game-design/RUNTIME_MASTER_DATA.md.
 *
 * Kept as constants rather than a config file because they are game rules,
 * not deployment settings: an operator must not be able to retune capture
 * odds with an environment variable.
 */
final class ExpeditionBalance
{
    // -- A. Game Master v0.3, ExpeditionRules sheet ------------------------

    /** expedition_rule_base_success_rate = 60 percent. */
    public const BASE_SUCCESS_PERCENT = 60;

    /** expedition_rule_biome_affinity_bonus = 10 percent. */
    public const BIOME_AFFINITY_BONUS = 10;

    /** expedition_rule_biome_mismatch_penalty = 0 percent (v0.3: reward the match only). */
    public const BIOME_MISMATCH_PENALTY = 0;

    /** expedition_rule_minimum_minutes = 5. */
    public const MIN_EXPEDITION_MINUTES = 5;

    /** expedition_rule_maximum_minutes = 1440 (24 h). */
    public const MAX_EXPEDITION_MINUTES = 1440;

    /** expedition_rule_failure_penalty_g = 0 — a failed capture costs nothing extra. */
    public const FAILURE_PENALTY_G = 0;

    /** expedition_rule_release_reward_ratio = 0 — releasing returns no G. */
    public const RELEASE_REWARD_G = 0;

    /** expedition_rule_hunter_rank_gate_soft = 0 (soft) — rank never blocks a dispatch. */
    public const HUNTER_RANK_GATE_IS_HARD = false;

    // -- B. Vertical-slice values, NOT in Game Master v0.3 -----------------

    /**
     * Capture percentage lost per point of Map.difficulty above 1.
     * Difficulty 1 costs nothing; difficulty 5 costs 32.
     */
    public const DIFFICULTY_PENALTY_PER_POINT = 8;

    /**
     * Capture percentage lost per point of Animal.capture_difficulty above 1.
     * A Common impala (1) costs nothing; a Saola (5) costs 32.
     */
    public const ANIMAL_DIFFICULTY_PENALTY_PER_POINT = 8;

    /** Nothing is ever a certainty, and nothing is ever hopeless. */
    public const MIN_CAPTURE_PERCENT = 5;
    public const MAX_CAPTURE_PERCENT = 95;

    private function __construct()
    {
    }
}
