<?php

namespace App\Simulation\Agents;

/**
 * "I want to play now, not in ten minutes."
 *
 * Always the fastest hunter it can afford, so it takes more turns per day
 * than anyone else and pays more per turn for the privilege.
 *
 * This is the agent that finds out whether speed_bonus is priced correctly.
 * More expeditions per day means more chances at a rare, but also a much
 * faster burn rate.
 */
final class Impatient implements PlayerAgent
{
    public function name(): string
    {
        return 'impatient';
    }

    public function description(): string
    {
        return 'Always the fastest hunter it can afford. More turns per day, '
            .'and a faster burn rate. Tests whether speed is priced right.';
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

                $minutes = AgentSupport::durationMinutes($map, $hunter);

                if ($best === null
                    || $minutes < $best['minutes']
                    || ($minutes === $best['minutes'] && $cost < $best['cost'])
                ) {
                    $best = [
                        'map_id' => $map['id'],
                        'hunter_id' => $hunter['id'],
                        'minutes' => $minutes,
                        'cost' => $cost,
                    ];
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
