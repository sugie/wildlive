<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class HealthTest extends TestCase
{
    public function test_health_endpoint_returns_ok_when_database_is_reachable(): void
    {
        $response = $this->getJson('/api/health');

        $response->assertStatus(200);
        $response->assertJson([
            'status' => 'ok',
            'checks' => [
                'app' => 'ok',
                'database' => [
                    'ok' => true,
                    'connection' => 'pgsql',
                ],
            ],
        ]);
    }

    public function test_health_endpoint_reports_degraded_when_database_is_unreachable(): void
    {
        config(['database.connections.pgsql_broken' => [
            'driver' => 'pgsql',
            'host' => '127.0.0.1',
            'port' => 1,
            'database' => 'nope',
            'username' => 'nope',
            'password' => 'nope',
            'charset' => 'utf8',
            'prefix' => '',
            'schema' => 'public',
            'sslmode' => 'prefer',
        ]]);

        config(['database.default' => 'pgsql_broken']);
        DB::purge('pgsql_broken');

        $response = $this->getJson('/api/health');

        $response->assertStatus(503);
        $response->assertJsonPath('status', 'degraded');
        $response->assertJsonPath('checks.database.ok', false);
    }

    public function test_postgres_connection_actually_reaches_postgres_engine(): void
    {
        $version = DB::selectOne('select version() as version');

        $this->assertNotNull($version);
        $this->assertStringContainsStringIgnoringCase('postgresql', $version->version);
    }
}
