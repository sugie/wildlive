<?php

namespace App\Application\Expeditions;

/**
 * Framework-free input to the StartExpedition use case.
 *
 * `devInstantResolve` is the client's *request* for the development
 * shortcut, not permission to use it — DevExpeditionPolicy decides.
 */
final class StartExpeditionInput
{
    public function __construct(
        public readonly string $playerId,
        public readonly string $mapId,
        public readonly string $hunterId,
        public readonly bool $devInstantResolve = false,
    ) {
    }
}
