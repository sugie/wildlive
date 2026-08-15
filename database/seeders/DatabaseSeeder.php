<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     *
     * Game Master data is required for the app to function at all — with
     * no maps, hunters or animals there is no game — so it seeds by
     * default rather than being an opt-in extra.
     *
     * No demo players are created: players come from real registrations
     * through POST /api/players.
     */
    public function run(): void
    {
        $this->call(GameMasterSeeder::class);
    }
}
