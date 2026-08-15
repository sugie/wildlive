<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\Zoo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class RegisterPlayerTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_creates_player_and_zoo_and_returns_201(): void
    {
        $response = $this->postJson('/api/players', [
            'display_name' => 'Kai',
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'player' => ['id', 'display_name', 'created_at'],
            'zoo' => ['id', 'created_at'],
        ]);
        $response->assertJsonPath('player.display_name', 'Kai');

        $this->assertSame(1, Player::query()->count(), 'exactly one Player was created');
        $this->assertSame(1, Zoo::query()->count(),    'exactly one Zoo was created');

        $player = Player::query()->firstOrFail();
        $zoo = Zoo::query()->firstOrFail();

        $this->assertSame($player->id, $zoo->player_id, 'C1: Zoo.player_id points at the created Player');
        $this->assertSame($player->id, $response->json('player.id'));
        $this->assertSame($zoo->id, $response->json('zoo.id'));
    }

    public function test_registration_trims_whitespace_in_display_name(): void
    {
        $response = $this->postJson('/api/players', [
            'display_name' => '  Rin  ',
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('player.display_name', 'Rin');
    }

    public function test_missing_display_name_returns_422(): void
    {
        $response = $this->postJson('/api/players', []);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['display_name']);
        $this->assertSame(0, Player::query()->count());
        $this->assertSame(0, Zoo::query()->count());
    }

    public function test_short_display_name_returns_422(): void
    {
        $response = $this->postJson('/api/players', [
            'display_name' => 'A',
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['display_name']);
        $this->assertSame(0, Player::query()->count());
    }

    public function test_long_display_name_returns_422(): void
    {
        $response = $this->postJson('/api/players', [
            'display_name' => str_repeat('x', 33),
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['display_name']);
        $this->assertSame(0, Player::query()->count());
    }

    public function test_player_id_is_a_uuid(): void
    {
        $response = $this->postJson('/api/players', ['display_name' => 'Uuid Check']);

        $response->assertStatus(201);
        $id = $response->json('player.id');
        $this->assertIsString($id);
        $this->assertMatchesRegularExpression(
            '/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i',
            $id,
            'player.id should be a canonical UUID'
        );
    }

    public function test_two_registrations_produce_two_distinct_players_each_with_own_zoo(): void
    {
        $this->postJson('/api/players', ['display_name' => 'One'])->assertStatus(201);
        $this->postJson('/api/players', ['display_name' => 'Two'])->assertStatus(201);

        $this->assertSame(2, Player::query()->count());
        $this->assertSame(2, Zoo::query()->count());
        $this->assertSame(
            2,
            DB::table('zoos')->distinct('player_id')->count('player_id'),
            'Each Player has a distinct Zoo (C1 uniqueness)'
        );
    }
}
