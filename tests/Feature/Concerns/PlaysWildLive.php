<?php

namespace Tests\Feature\Concerns;

use App\Domain\Support\RandomSource;
use Database\Seeders\GameMasterSeeder;
use Tests\Support\SequenceRandomSource;

/**
 * Shared setup for the gameplay feature tests.
 *
 * Two things every one of them needs:
 *
 *   1. Real Game Master v0.3 data in PostgreSQL. The tests assert against
 *      actual workbook values (Kenyan Savanna costs 50 G, Amara Koné
 *      prefers savanna), not against invented fixtures — so a master-data
 *      change that breaks the game breaks the tests.
 *
 *   2. A scripted RandomSource. Every roll the game makes goes through
 *      that one binding, so an expedition's outcome is fully determined
 *      and no test in this suite can fail on a dice roll.
 */
trait PlaysWildLive
{
    protected const STARTER_MAP = 'map_kenyan_savanna_001';

    /** Bronze, savanna, capture_bonus 0, 50 G — the first Hunter a player meets. */
    protected const CHEAP_HUNTER = 'hunter_amara_kone_001';

    protected function seedGameMaster(): void
    {
        $this->seed(GameMasterSeeder::class);
    }

    private ?SequenceRandomSource $scriptedRandom = null;

    /**
     * Script the game's dice.
     *
     * ResolveExpedition rolls exactly twice, in this order:
     *   1. the encounter draw, over the map's total spawn weight
     *   2. the capture attempt, on a d100
     *
     * SequenceRandomSource clamps into the requested range, so `1` reliably
     * means "the first candidate" / "the lowest possible roll" without the
     * test needing to know the total weight.
     *
     * Calling this more than once in a test APPENDS to the queue rather
     * than replacing it. That is not a convenience: Laravel caches the
     * resolved controller on the Route object, so a fresh container
     * binding made after the route has already been called would never be
     * seen. One instance per test, extended as the scenario goes on, is
     * the only version that works.
     *
     * @param  array<int, int>  $values
     */
    protected function scriptRolls(array $values): SequenceRandomSource
    {
        if ($this->scriptedRandom !== null) {
            $this->scriptedRandom->push($values);

            return $this->scriptedRandom;
        }

        $this->scriptedRandom = new SequenceRandomSource($values);
        $this->app->instance(RandomSource::class, $this->scriptedRandom);

        return $this->scriptedRandom;
    }

    /** Roll low twice: encounter the highest-weighted animal, and catch it. */
    protected function scriptGuaranteedCapture(): SequenceRandomSource
    {
        return $this->scriptRolls([1, 1]);
    }

    /** Encounter the highest-weighted animal, then miss it. */
    protected function scriptGuaranteedMiss(): SequenceRandomSource
    {
        return $this->scriptRolls([1, 100]);
    }

    /** Register through the real endpoint and return the new player's id. */
    protected function registerPlayer(string $displayName = 'Tester'): string
    {
        $response = $this->postJson('/api/players', ['display_name' => $displayName]);
        $response->assertStatus(201);

        return $response->json('player.id');
    }

    /**
     * Dispatch an expedition that can be resolved immediately.
     *
     * @return string the new expedition's id
     */
    protected function startInstantExpedition(
        string $playerId,
        string $mapId = self::STARTER_MAP,
        string $hunterId = self::CHEAP_HUNTER,
    ): string {
        $response = $this->postJson("/api/players/{$playerId}/expeditions", [
            'map_id' => $mapId,
            'hunter_id' => $hunterId,
            'dev_instant_resolve' => true,
        ]);
        $response->assertStatus(201);

        return $response->json('expedition.id');
    }
}
