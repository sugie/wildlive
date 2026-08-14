<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Throwable;

class HealthController extends Controller
{
    public function show(): JsonResponse
    {
        $databaseOk = true;
        $databaseError = null;

        try {
            DB::connection()->select('select 1');
        } catch (Throwable $e) {
            $databaseOk = false;
            $databaseError = $e->getMessage();
        }

        $status = $databaseOk ? 'ok' : 'degraded';
        $httpCode = $databaseOk ? 200 : 503;

        return response()->json([
            'status' => $status,
            'checks' => [
                'app' => 'ok',
                'database' => [
                    'ok' => $databaseOk,
                    'connection' => config('database.default'),
                    'error' => $databaseError,
                ],
            ],
        ], $httpCode);
    }
}
