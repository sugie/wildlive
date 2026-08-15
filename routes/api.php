<?php

use App\Http\Controllers\ExpeditionController;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\HunterController;
use App\Http\Controllers\MapController;
use App\Http\Controllers\PlayerController;
use App\Http\Controllers\ZooController;
use Illuminate\Support\Facades\Route;

Route::get('/health', [HealthController::class, 'show'])
    ->name('api.health');

/*
|--------------------------------------------------------------------------
| Player
|--------------------------------------------------------------------------
*/

Route::post('/players', [PlayerController::class, 'store'])
    ->name('api.players.store');

Route::get('/players/{player}', [PlayerController::class, 'show'])
    ->name('api.players.show');

Route::get('/players/{player}/zoo', [ZooController::class, 'show'])
    ->name('api.players.zoo');

/*
|--------------------------------------------------------------------------
| Game catalogue
|--------------------------------------------------------------------------
|
| Maps are player-scoped because unlock state depends on the player's Zoo
| value. Hunters are not: the Guild pool is shared and a Hunter is never
| owned, so /hunters sits at the top level. Pass ?map_id= to have each
| Hunter costed for a specific Map.
|
*/

Route::get('/players/{player}/maps', [MapController::class, 'index'])
    ->name('api.players.maps.index');

Route::get('/players/{player}/maps/{map}', [MapController::class, 'show'])
    ->name('api.players.maps.show');

Route::get('/hunters', [HunterController::class, 'index'])
    ->name('api.hunters.index');

/*
|--------------------------------------------------------------------------
| Expeditions
|--------------------------------------------------------------------------
|
| Nested under the player so ownership is explicit in the URL and can be
| enforced without an auth layer that does not exist yet.
|
| resolve / keep / release are POSTs because each is a state transition,
| and each is idempotent: resolving twice returns the first outcome, and
| re-sending the same decision returns the decided expedition.
|
*/

Route::get('/players/{player}/expeditions', [ExpeditionController::class, 'index'])
    ->name('api.players.expeditions.index');

Route::post('/players/{player}/expeditions', [ExpeditionController::class, 'store'])
    ->name('api.players.expeditions.store');

Route::get('/players/{player}/expeditions/{expedition}', [ExpeditionController::class, 'show'])
    ->name('api.players.expeditions.show');

Route::post('/players/{player}/expeditions/{expedition}/resolve', [ExpeditionController::class, 'resolve'])
    ->name('api.players.expeditions.resolve');

Route::post('/players/{player}/expeditions/{expedition}/keep', [ExpeditionController::class, 'keep'])
    ->name('api.players.expeditions.keep');

Route::post('/players/{player}/expeditions/{expedition}/release', [ExpeditionController::class, 'release'])
    ->name('api.players.expeditions.release');
