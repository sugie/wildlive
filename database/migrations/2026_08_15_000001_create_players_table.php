<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Minimum-viable players table for Milestone 002 first-time registration.
 *
 * `id` is a time-ordered UUID (Laravel `Str::orderedUuid()`) — non-enumerable
 * when exposed to clients while retaining B-tree locality for the index.
 *
 * Deliberately omits every field still marked TBD in
 * `docs/ER_MODEL.md` (authentication, handle, email, verification,
 * currency, etc.). Additive follow-up migrations may add those columns
 * without touching this file.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('players', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('display_name');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('players');
    }
};
