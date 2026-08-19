<?php

namespace App\Simulation\Agents;

/**
 * "I can't afford to waste money."
 *
 * Always the cheapest hunter on the cheapest map, and keeps everything.
 * The most cautious way to play, and therefore the floor: if this agent
 * goes broke, the economy is too tight for anybody.
 */
final class Frugal implements PlayerAgent
{
    public function name(): string
    {
        return 'frugal';
    }

    public function description(): string
    {
        return 'Always the cheapest expedition available. Keeps every capture. '
            .'The cautious player, and the floor of the economy.';
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
                if ($best === null || $cost < $best['cost']) {
                    $best = ['map_id' => $map['id'], 'hunter_id' => $hunter['id'], 'cost' => $cost];
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
