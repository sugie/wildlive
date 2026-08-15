<?php

namespace Tests\Unit\Application\Expeditions;

use App\Application\Expeditions\DevExpeditionPolicy;
use PHPUnit\Framework\TestCase;

/**
 * The guard on the development-only "resolve immediately" shortcut.
 *
 * The case that matters most is the last one: production must refuse even
 * when the config flag has been switched on, because an env var is exactly
 * the kind of thing that gets copied into the wrong deployment.
 */
class DevExpeditionPolicyTest extends TestCase
{
    private const ALLOWED = ['local', 'testing'];

    public function test_allows_when_enabled_in_an_allowed_environment(): void
    {
        $policy = new DevExpeditionPolicy(true, 'local', self::ALLOWED);

        $this->assertTrue($policy->allowsInstantResolve());
    }

    public function test_allows_in_the_testing_environment(): void
    {
        $policy = new DevExpeditionPolicy(true, 'testing', self::ALLOWED);

        $this->assertTrue($policy->allowsInstantResolve());
    }

    public function test_refuses_when_the_config_flag_is_off(): void
    {
        $policy = new DevExpeditionPolicy(false, 'local', self::ALLOWED);

        $this->assertFalse($policy->allowsInstantResolve());
        $this->assertStringContainsString('disabled', $policy->refusalReason());
    }

    public function test_refuses_in_production_even_when_the_flag_is_on(): void
    {
        $policy = new DevExpeditionPolicy(true, 'production', self::ALLOWED);

        $this->assertFalse($policy->allowsInstantResolve());
        $this->assertStringContainsString('production', $policy->refusalReason());
    }

    public function test_refuses_in_any_unlisted_environment(): void
    {
        foreach (['production', 'staging', 'demo', ''] as $environment) {
            $this->assertFalse(
                (new DevExpeditionPolicy(true, $environment, self::ALLOWED))->allowsInstantResolve(),
                "environment {$environment} must not allow instant resolution"
            );
        }
    }
}
