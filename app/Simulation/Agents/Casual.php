<?php

namespace App\Simulation\Agents;

use App\Domain\Support\RandomSource;

/**
 * "I just tap something."
 *
 * Picks uniformly at random from whatever it can afford, and keeps on a
 * coin flip. Nobody plays *this* carelessly, but somebody plays nearly this
 * carelessly, and a game that only works under optimal play does not work.
 *
 * Shares the run's RandomSource, so its choices are as reproducible as the
 * rolls the game makes.
 */
final class Casual implements PlayerAgent
{
    public function __construct(private readonly RandomSource $random)
    {
    }

    public function name(): string
    {
        return 'casual';
    }

    public function description(): string
    {
        return 'Picks at random from what it can afford and keeps on a coin flip. '
            .'The baseline: a game that only works under optimal play does not work.';
    }

    public function chooseExpedition(array $maps, array $hunters, int $balanceG): ?array
    {
        $affordable = [];

        foreach ($maps as $map) {
            foreach ($hunters as $hunter) {
                if (AgentSupport::totalCost($map, $hunter) <= $balanceG) {
                    $affordable[] = ['map_id' => $map['id'], 'hunter_id' => $hunter['id']];
                }
            }
        }

        if ($affordable === []) {
            return null;
        }

        return $affordable[$this->random->int(0, count($affordable) - 1)];
    }

    public function keepsCapture(array $animal, array $zoo): bool
    {
        return $this->random->int(1, 2) === 1;
    }
}
