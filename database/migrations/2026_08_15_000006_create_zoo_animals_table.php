<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Individual animals living in a player's Zoo.
 *
 * One row is created when a player chooses KEEP on a captured expedition
 * result. RELEASE creates nothing (Game Master v0.3:
 * expedition_rule_release_reward_ratio = 0 — releasing returns no G and no
 * animal).
 *
 * UNIQUE(expedition_id) is the structural guarantee that one expedition can
 * never mint two animals, even if KEEP is submitted twice concurrently. The
 * Application Layer also guards on `expeditions.decided_at IS NULL` inside a
 * row-locked transaction; the constraint is the backstop for callers that
 * bypass it.
 *
 * `name` is the player-assigned nickname. It is NOT NULL because the KEEP
 * flow always asks for a name; the Application Layer falls back to the
 * species' English name when the player submits an empty one.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('zoo_animals', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('zoo_id')->constrained('zoos')->cascadeOnDelete();
            $table->string('animal_id', 64);
            $table->string('name', 64);
            $table->uuid('expedition_id')->nullable()->unique();
            $table->string('captured_from_map_id', 64)->nullable();
            $table->string('captured_by_hunter_id', 64)->nullable();
            $table->timestamp('captured_at');
            $table->timestamps();

            $table->foreign('animal_id')->references('id')->on('animals')->restrictOnDelete();
            $table->foreign('expedition_id')->references('id')->on('expeditions')->cascadeOnDelete();
            $table->foreign('captured_from_map_id')->references('id')->on('maps')->nullOnDelete();
            $table->foreign('captured_by_hunter_id')->references('id')->on('hunters')->nullOnDelete();

            $table->index(['zoo_id', 'captured_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('zoo_animals');
    }
};
