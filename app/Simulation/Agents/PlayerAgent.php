<?php

namespace App\Simulation\Agents;

/**
 * A simulated player.
 *
 * Every decision a real player makes with the app in their hand, expressed
 * as a function of what the server would have shown them. An agent never
 * sees anything a player could not see: it is handed the catalogue and its
 * own overview, exactly what the API returns, and nothing about the roll
 * that is about to happen.
 *
 * Agents exist to answer a question the designer cannot answer by playing
 * once: does the game hold up for people who play it differently? If one
 * agent thrives and another goes broke on the same rules, that gap is the
 * finding.
 *
 * Deliberately not "good" or "bad" players — each is a coherent strategy
 * someone would actually adopt.
 */
interface PlayerAgent
{
    /** Stable identifier used in the report. */
    public function name(): string;

    /** One line explaining the person this agent stands in for. */
    public function description(): string;

    /**
     * Choose a map and hunter, or null to sit this turn out.
     *
     * @param  array<int, array<string, mixed>>  $maps      unlocked maps only
     * @param  array<int, array<string, mixed>>  $hunters   costed for each map
     * @param  int  $balanceG  what the player can spend
     * @return array{map_id: string, hunter_id: string}|null
     */
    public function chooseExpedition(array $maps, array $hunters, int $balanceG): ?array;

    /**
     * Keep the captured animal, or let it go.
     *
     * @param  array<string, mixed>  $animal  species as the API reports it
     * @param  array<string, mixed>  $zoo     the player's zoo summary
     */
    public function keepsCapture(array $animal, array $zoo): bool;
}
