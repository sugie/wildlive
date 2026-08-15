<?php

namespace App\Application\Expeditions;

/**
 * Guards the development-only "resolve this expedition immediately" path.
 *
 * Canonical Map.expedition_minutes runs from 10 minutes to 6 hours, which
 * no human tester and no E2E run can sit through. This policy is what lets
 * a client ask for an instantly-resolvable expedition, and it is
 * deliberately awkward to trip by accident:
 *
 *   - the application environment must be one the policy allows
 *     (local / testing — never production, whatever the env var says);
 *   - the config flag must be on;
 *   - and the caller must still opt in explicitly, per request.
 *
 * Values are injected rather than read from config() here so the rule can
 * be unit-tested without booting the framework. The binding lives in
 * AppServiceProvider.
 */
final class DevExpeditionPolicy
{
    /**
     * @param  array<int, string>  $allowedEnvironments
     */
    public function __construct(
        private readonly bool $enabled,
        private readonly string $environment,
        private readonly array $allowedEnvironments,
    ) {
    }

    public function allowsInstantResolve(): bool
    {
        return $this->enabled && in_array($this->environment, $this->allowedEnvironments, true);
    }

    /** Why a refusal happened, in words a developer can act on. */
    public function refusalReason(): string
    {
        if (! in_array($this->environment, $this->allowedEnvironments, true)) {
            return sprintf(
                'Instant expedition resolution is not available in the "%s" environment.',
                $this->environment
            );
        }

        return 'Instant expedition resolution is disabled (config wildlive.dev.instant_expeditions).';
    }
}
