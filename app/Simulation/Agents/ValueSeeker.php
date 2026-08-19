<?php

namespace App\Simulation\Agents;

/**
 * "What gets me the most Zoo value per G?"
 *
 * Scores every map/hunter pairing by the expected zoo value it should
 * return for what it costs, using only what the API tells a client: the
 * map's spawn table, its difficulty, and the hunter's quoted bonuses.
 *
 * The optimiser. If any single strategy runs away with the game, it is
 * most likely to be this one, so the spread between this agent and Frugal
 * is the headline balance number.
 */
final class ValueSeeker implements PlayerAgent
{
    public function name(): string
    {
        return 'value-seeker';
    }

    public function description(): string
    {
        return 'Maximises expected Zoo value per G spent, from the spawn table and '
            .'quoted hunter bonuses. The optimiser.';
    }

    public function chooseExpedition(array $maps, array $hunters, int $balanceG): ?array
    {
        $best = null;

        foreach ($maps as $map) {
            foreach ($hunters as $hunter) {
                $cost = AgentSupport::totalCost($map, $hunter);
                if ($cost > $balanceG || $cost <= 0) {
                    continue;
                }

                $value = AgentSupport::expectedZooValue($map, $hunter);
                $score = $value / $cost;

                if ($best === null || $score > $best['score']) {
                    $best = ['map_id' => $map['id'], 'hunter_id' => $hunter['id'], 'score' => $score];
                }
            }
        }

        return $best === null ? null : ['map_id' => $best['map_id'], 'hunter_id' => $best['hunter_id']];
    }

    public function keepsCapture(array $animal, array $zoo): bool
    {
        return true;
    }
}
