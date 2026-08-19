<?php

namespace App\Simulation\Agents;

/**
 * Arithmetic every agent needs, done once.
 *
 * Careful boundary: these helpers read only fields the API actually returns
 * to a client. An agent that consulted the database, the encounter roll, or
 * ExpeditionBalance's constants would be cheating — it would be optimising
 * against knowledge no player has, and the balance conclusions drawn from
 * it would be about a game nobody is playing.
 */
final class AgentSupport
{
    /**
     * Map cost plus contract cost.
     *
     * The server quotes `for_map.total_cost_g` when hunters are requested
     * for a specific map; the sum is the fallback for when they are not.
     *
     * @param  array<string, mixed>  $map
     * @param  array<string, mixed>  $hunter
     */
    public static function totalCost(array $map, array $hunter): int
    {
        if (isset($hunter['for_map']['total_cost_g'])) {
            return (int) $hunter['for_map']['total_cost_g'];
        }

        return (int) ($map['base_cost_g'] ?? 0) + (int) ($hunter['contract_cost_g'] ?? 0);
    }

    /**
     * How long this pairing takes, after the hunter's speed bonus.
     *
     * @param  array<string, mixed>  $map
     * @param  array<string, mixed>  $hunter
     */
    public static function durationMinutes(array $map, array $hunter): int
    {
        if (isset($hunter['for_map']['duration_minutes'])) {
            return (int) $hunter['for_map']['duration_minutes'];
        }

        return (int) ($map['expedition_minutes'] ?? 0);
    }

    /**
     * The Zoo value this pairing should return on average.
     *
     * Deliberately approximate. An agent is a player, and a player reasons
     * from the spawn table on the map screen and the bonuses on the hunter
     * card — not from the capture formula, which is not published. So this
     * weights each species' base value by its listed spawn chance, then
     * discounts by a rough sense of how hard the map is and how good the
     * hunter is. Being wrong in the same direction a player would be wrong
     * is the point.
     *
     * @param  array<string, mixed>  $map
     * @param  array<string, mixed>  $hunter
     */
    public static function expectedZooValue(array $map, array $hunter): float
    {
        $spawns = $map['spawn_table'] ?? [];
        if ($spawns === []) {
            return 0.0;
        }

        $value = 0.0;
        $totalChance = 0.0;

        foreach ($spawns as $entry) {
            $chance = (float) ($entry['spawn_chance_percent'] ?? 0);
            $animal = $entry['animal'] ?? $entry;
            $value += $chance * (float) ($animal['base_zoo_value'] ?? 0);
            $totalChance += $chance;
        }

        if ($totalChance <= 0) {
            return 0.0;
        }

        $expectedValue = $value / $totalChance;

        // A player's intuition: harder map, less likely to come home with
        // anything; better hunter, more likely.
        $difficulty = max(1, (int) ($map['difficulty'] ?? 1));
        $captureBonus = (int) ($hunter['capture_bonus'] ?? 0);
        $odds = max(0.05, min(0.95, (60 - 8 * ($difficulty - 1) + $captureBonus) / 100));

        return $expectedValue * $odds;
    }

    /**
     * Rarity tier, 1 Common … 5 Legendary.
     *
     * @param  array<string, mixed>  $animal
     */
    public static function raritySortOrder(array $animal): int
    {
        return (int) ($animal['rarity']['sort_order'] ?? 1);
    }
}
