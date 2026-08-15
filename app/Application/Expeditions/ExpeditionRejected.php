<?php

namespace App\Application\Expeditions;

use RuntimeException;

/**
 * A gameplay rule said no.
 *
 * Framework-free on purpose: the Application Layer must not know what an
 * HTTP status code is. The Presentation Layer maps `code()` to a response.
 *
 * These are *expected* refusals (not enough G, map still locked, capture
 * already decided), not bugs — which is why they carry a stable machine
 * code the client can branch on as well as a human-readable message.
 */
final class ExpeditionRejected extends RuntimeException
{
    public const PLAYER_NOT_FOUND = 'player_not_found';
    public const MAP_NOT_FOUND = 'map_not_found';
    public const HUNTER_NOT_FOUND = 'hunter_not_found';
    public const EXPEDITION_NOT_FOUND = 'expedition_not_found';
    public const MAP_NOT_AVAILABLE = 'map_not_available';
    public const MAP_LOCKED = 'map_locked';
    public const INSUFFICIENT_G = 'insufficient_g';
    public const NOT_DUE = 'expedition_not_due';
    public const NOT_RESOLVED = 'expedition_not_resolved';
    public const NOTHING_TO_DECIDE = 'nothing_to_decide';
    public const ALREADY_DECIDED = 'already_decided';
    public const EMPTY_SPAWN_TABLE = 'empty_spawn_table';
    public const DEV_RESOLVE_NOT_ALLOWED = 'dev_instant_resolve_not_allowed';

    private function __construct(
        private readonly string $code,
        string $message,
    ) {
        parent::__construct($message);
    }

    public static function because(string $code, string $message): self
    {
        return new self($code, $message);
    }

    public function code(): string
    {
        return $this->code;
    }
}
