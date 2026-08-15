<?php

use App\Application\Expeditions\ExpeditionRejected;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

/**
 * Maps a gameplay refusal onto an HTTP status.
 *
 * The Application Layer throws ExpeditionRejected with a stable machine
 * code and never knows what a status code is; this is the single place
 * that translation happens, which keeps every controller free of
 * try/catch blocks.
 */
$expeditionRejectionStatus = static function (string $code): int {
    return match ($code) {
        ExpeditionRejected::PLAYER_NOT_FOUND,
        ExpeditionRejected::MAP_NOT_FOUND,
        ExpeditionRejected::HUNTER_NOT_FOUND,
        ExpeditionRejected::EXPEDITION_NOT_FOUND => 404,

        // The player asked for something reasonable that the current game
        // state does not allow — the client shows the message and moves on.
        ExpeditionRejected::ALREADY_DECIDED => 409,

        default => 422,
    };
};

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        apiPrefix: 'api',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions) use ($expeditionRejectionStatus): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        $exceptions->render(function (ExpeditionRejected $e, Request $request) use ($expeditionRejectionStatus) {
            return response()->json([
                'error' => [
                    'code' => $e->code(),
                    'message' => $e->getMessage(),
                ],
            ], $expeditionRejectionStatus($e->code()));
        });
    })->create();
