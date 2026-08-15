<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Game Master v0.3 runtime tables.
 *
 * These are *master data* tables: read-only at runtime, populated only by
 * Database\Seeders\GameMasterSeeder from
 * database/master/game-master-v0.3.json, which is generated from the
 * canonical Python source (docs/game-design/build_master_v0_3.py).
 *
 * Primary keys are the Game Master's own string identifiers
 * (`map_kenyan_savanna_001`, `animal_impala_001`, `hunter_susumu_019`, …)
 * rather than surrogate integers. That keeps the whole chain traceable by
 * eye: workbook cell → JSON row → PostgreSQL row → API payload → Simulator.
 *
 * Additive only: no existing table is touched.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('biomes', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('name_en');
            $table->string('name_ja');
            $table->text('description_en')->default('');
            $table->text('description_ja')->default('');
        });

        Schema::create('rarities', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('name_en');
            $table->string('name_ja');
            $table->unsignedSmallInteger('sort_order');
            $table->decimal('base_multiplier', 6, 2);
            $table->text('description')->default('');
        });

        Schema::create('animals', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('name_en');
            $table->string('name_ja');
            $table->string('category', 32)->default('');
            $table->string('rarity_id', 64);
            $table->string('availability_phase', 32);
            $table->text('placement_note')->default('');
            $table->unsignedInteger('base_zoo_value');
            $table->unsignedSmallInteger('capture_difficulty');
            $table->unsignedSmallInteger('growth_rate')->default(0);
            $table->unsignedSmallInteger('visitor_appeal')->default(0);
            $table->string('habitat_biome_id', 64);
            $table->string('size', 32)->default('');
            $table->string('active_time', 32)->default('');
            $table->text('description_en')->default('');
            $table->text('description_ja')->default('');

            $table->foreign('rarity_id')->references('id')->on('rarities')->restrictOnDelete();
            $table->foreign('habitat_biome_id')->references('id')->on('biomes')->restrictOnDelete();
            $table->index('availability_phase');
        });

        Schema::create('hunters', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('name');
            $table->string('name_ja');
            $table->string('rank', 32);
            $table->unsignedSmallInteger('level');
            $table->string('specialty', 64);
            // 'any' is a legal value here (Game Master HunterSkills:
            // skill_biome_affinity), so this deliberately has no FK to biomes.
            $table->string('preferred_biome_id', 64);
            $table->smallInteger('capture_bonus');
            $table->smallInteger('rare_find_bonus');
            $table->smallInteger('speed_bonus');
            $table->unsignedInteger('contract_cost_g');
            $table->text('personality')->default('');
            $table->text('description')->default('');
        });

        Schema::create('maps', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('name_en');
            $table->string('name_ja');
            $table->string('region', 64);
            $table->string('biome_id', 64);
            $table->string('availability_phase', 32);
            $table->string('map_role', 32);
            $table->string('unlock_rule', 32);
            $table->unsignedInteger('unlock_value')->default(0);
            $table->unsignedSmallInteger('recommended_hunter_rank')->default(0);
            $table->unsignedSmallInteger('minimum_hunter_rank_gate')->default(0);
            $table->unsignedSmallInteger('difficulty');
            $table->unsignedInteger('expedition_minutes');
            $table->unsignedInteger('base_cost_g');
            $table->unsignedSmallInteger('risk_level')->default(0);
            $table->text('description_en')->default('');
            $table->text('description_ja')->default('');

            $table->foreign('biome_id')->references('id')->on('biomes')->restrictOnDelete();
            $table->index('availability_phase');
        });

        Schema::create('map_animals', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('map_id', 64);
            $table->string('animal_id', 64);
            $table->unsignedInteger('spawn_weight');
            $table->smallInteger('capture_modifier')->default(0);
            $table->boolean('needs_review')->default(false);
            $table->text('notes')->default('');

            $table->foreign('map_id')->references('id')->on('maps')->cascadeOnDelete();
            $table->foreign('animal_id')->references('id')->on('animals')->restrictOnDelete();
            $table->unique(['map_id', 'animal_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('map_animals');
        Schema::dropIfExists('maps');
        Schema::dropIfExists('hunters');
        Schema::dropIfExists('animals');
        Schema::dropIfExists('rarities');
        Schema::dropIfExists('biomes');
    }
};
