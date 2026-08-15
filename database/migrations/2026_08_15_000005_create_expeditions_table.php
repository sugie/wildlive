<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Expeditions — the core server-authoritative gameplay record.
 *
 * Lifecycle is modelled with timestamps, not workers (docs/ARCHITECTURE.md):
 *
 *   started_at   always set at creation
 *   ends_at      started_at + duration derived from Map.expedition_minutes
 *                and Hunter.speed_bonus
 *   resolved_at  set exactly once, when the outcome is computed
 *   decided_at   set exactly once, when the player KEEPs or RELEASEs
 *
 * The three state columns are deliberately separate rather than one
 * enum, because they answer three different questions and each has its
 * own guard in the Application Layer:
 *
 *   status    in_progress → resolved            (may the outcome be computed?)
 *   outcome   null → captured | no_capture      (was anything caught?)
 *   decision  null → kept | released            (what did the player do?)
 *
 * `resolved_at IS NULL` is the idempotency key for resolution and
 * `decided_at IS NULL` for the keep/release decision; both transitions run
 * inside a transaction with a row lock, so calling resolve twice is safe.
 *
 * Hunters are NOT owned by players (Game Master v0.3): the hunter is
 * contracted for this expedition only. That is why the contract lives here
 * as `hunter_id` + `contract_cost_g` and there is no player_hunters table.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('expeditions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('player_id')->constrained('players')->cascadeOnDelete();
            $table->string('map_id', 64);
            $table->string('hunter_id', 64);

            // Cost breakdown, snapshotted at dispatch so later master-data
            // edits cannot retroactively change what a player was charged.
            $table->unsignedInteger('map_cost_g');
            $table->unsignedInteger('contract_cost_g');
            $table->unsignedInteger('total_cost_g');

            // The duration the canonical Map.expedition_minutes and the
            // Hunter's speed_bonus actually imply. Recorded even when the
            // development shortcut collapses ends_at to started_at, so the
            // real timing is never lost and never rewritten.
            $table->unsignedInteger('planned_duration_minutes');

            $table->string('status', 24)->default('in_progress');
            $table->string('outcome', 24)->nullable();
            $table->string('decision', 24)->nullable();

            $table->string('encountered_animal_id', 64)->nullable();

            // Audit of the resolution maths. Kept because the whole point of
            // an injectable RandomSource is that a result can be re-checked.
            $table->unsignedSmallInteger('capture_chance_percent')->nullable();
            $table->unsignedInteger('capture_roll')->nullable();
            $table->unsignedInteger('encounter_roll')->nullable();

            // True only for expeditions created through the explicit
            // development shortcut (config/wildlive.php → dev.instant_expeditions).
            // Never set in production; surfaced in every API response.
            $table->boolean('dev_instant_resolve')->default(false);

            $table->timestamp('started_at');
            $table->timestamp('ends_at');
            $table->timestamp('resolved_at')->nullable();
            $table->timestamp('decided_at')->nullable();
            $table->timestamps();

            $table->foreign('map_id')->references('id')->on('maps')->restrictOnDelete();
            $table->foreign('hunter_id')->references('id')->on('hunters')->restrictOnDelete();
            $table->foreign('encountered_animal_id')->references('id')->on('animals')->restrictOnDelete();

            $table->index(['player_id', 'created_at']);
            $table->index(['status', 'ends_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('expeditions');
    }
};
