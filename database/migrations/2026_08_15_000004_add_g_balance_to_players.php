<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds the G balance to players.
 *
 * Additive and reversible. Existing rows get the configured starting
 * balance via the column default, so the migration cannot strand a
 * previously-registered player with a NULL balance.
 *
 * G is a plain signed integer: expeditions debit it, and the Application
 * Layer refuses to start an expedition that would take it below zero, so
 * the column never legitimately goes negative. It is not unsigned because
 * a would-be-negative value is a bug we want to see rather than a
 * constraint violation that masks where it came from.
 */
return new class extends Migration
{
    public function up(): void
    {
        $starting = (int) config('wildlive.starting_g_balance', 1000);

        Schema::table('players', function (Blueprint $table) use ($starting) {
            $table->integer('g_balance')->default($starting)->after('display_name');
        });
    }

    public function down(): void
    {
        Schema::table('players', function (Blueprint $table) {
            $table->dropColumn('g_balance');
        });
    }
};
