<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Minimum-viable zoos table for Milestone 002.
 *
 * `docs/ER_MODEL.md` C1 fixes `Player 1..1 Zoo` with UNIQUE(player_id) NOT NULL
 * and requires both rows be created in the same transaction. The unique
 * constraint here + the transaction in PlayerController::store together
 * enforce that invariant.
 *
 * Cascade delete on player removal is chosen so we never leave orphan Zoos.
 * When account-deletion policy is decided the ON DELETE rule may change.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('zoos', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('player_id')
                ->unique()
                ->constrained('players')
                ->cascadeOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('zoos');
    }
};
