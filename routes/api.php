<?php

use App\Http\Controllers\HealthController;
use App\Http\Controllers\PlayerController;
use Illuminate\Support\Facades\Route;

Route::get('/health', [HealthController::class, 'show'])
    ->name('api.health');

Route::post('/players', [PlayerController::class, 'store'])
    ->name('api.players.store');
