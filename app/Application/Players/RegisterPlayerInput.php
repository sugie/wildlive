<?php

namespace App\Application\Players;

/**
 * Framework-free input to the RegisterPlayer use case.
 *
 * Everything HTTP-shaped (headers, form request, JSON) is left in the
 * Presentation Layer; this DTO is what actually crosses the boundary into
 * the Application Layer.
 *
 * The caller is expected to have already trimmed whitespace and passed
 * validation. This class deliberately does not re-validate — validation is
 * a Presentation-Layer concern (RegisterPlayerRequest) so error reporting
 * stays HTTP-shaped.
 */
final class RegisterPlayerInput
{
    public function __construct(
        public readonly string $displayName,
    ) {
    }
}
