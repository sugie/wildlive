<?php

namespace App\Simulation\Agents;

/**
 * "I'm here for the rare ones."
 *
 * Pays for rare_find_bonus wherever it can afford to, and releases anything
 * Common — a collector wants a cabinet of rarities, not a full one.
 *
 * The agent that tests whether chasing rarity is a viable way to play or a
 * trap. Releasing Commons costs it Zoo value, which gates map unlocks, so
 * if the release rule is too strict this agent stalls.
 */
final class Collector implements PlayerAgent
{
    public function name(): string
    {
        return 'collector';
    }

    public function description(): string
    {
        return 'Pays for rare-find bonus and releases Commons. Tests whether '
            .'chasing rarity is viable or a trap.';
    }

    public function chooseExpedition(array $maps, array $hunters, int $balanceG): ?array
    {
        $best = null;

        foreach ($maps as $map) {
            foreach ($hunters as $hunter) {
                $cost = AgentSupport::totalCost($map, $hunter);
                if ($cost > $balanceG) {
                    continue;
                }

                // Rare find first, then anything that improves the odds of
                // actually landing the rare thing it finds.
                $score = ((int) ($hunter['rare_find_bonus'] ?? 0)) * 10
                    + ((int) ($hunter['capture_bonus'] ?? 0));

                if ($best === null || $score > $best['score']) {
                    $best = ['map_id' => $map['id'], 'hunter_id' => $hunter['id'], 'score' => $score];
                }
            }
        }

        return $best === null ? null : ['map_id' => $best['map_id'], 'hunter_id' => $best['hunter_id']];
    }

    public function keepsCapture(array $animal, array $zoo): bool
    {
        return AgentSupport::raritySortOrder($animal) >= 2;
    }
}
