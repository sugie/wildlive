<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Game master data
    |--------------------------------------------------------------------------
    |
    | The single runtime artifact generated from the canonical Game Master
    | source (docs/game-design/build_master_v0_3.py). GameMasterSeeder reads
    | this file; nothing at runtime ever opens the .xlsx workbook.
    |
    */

    'master_data_path' => database_path('master/game-master-v0.3.json'),

    /*
    |--------------------------------------------------------------------------
    | Starting balance
    |--------------------------------------------------------------------------
    |
    | G granted to a Player on registration.
    |
    | NOT a Game Master v0.3 value — the workbook does not fix a starting
    | balance. This is a vertical-slice constant chosen so a new Player can
    | afford roughly ten cheapest expeditions (Kenyan Savanna 50 G +
    | Amara Koné 50 G = 100 G). Economy balancing is explicitly out of scope
    | for this slice; see docs/game-design/RUNTIME_MASTER_DATA.md.
    |
    */

    'starting_g_balance' => (int) env('WILDLIVE_STARTING_G', 1000),

    /*
    |--------------------------------------------------------------------------
    | Development-only expedition acceleration
    |--------------------------------------------------------------------------
    |
    | Canonical Map.expedition_minutes ranges from 10 minutes to 6 hours, which
    | makes the gameplay loop impossible to exercise by hand or in an E2E test.
    |
    | `instant_expeditions` allows a client to opt in, PER REQUEST, to an
    | expedition that is immediately resolvable (ends_at == started_at). It is
    | deliberately hard to confuse with production behaviour:
    |
    |   1. The application environment must be listed in `allowed_environments`.
    |      In production this is never true, whatever the env var says.
    |   2. This config flag must be true.
    |   3. The client must explicitly send `dev_instant_resolve: true`.
    |
    | All three are required. An expedition created this way is permanently
    | flagged `dev_instant_resolve = true` in PostgreSQL and in every API
    | response, so a shortened expedition can never be mistaken for a real one.
    |
    | Canonical expedition_minutes is never modified by this mechanism.
    |
    */

    'dev' => [
        'instant_expeditions' => (bool) env('WILDLIVE_DEV_INSTANT_EXPEDITIONS', true),
        'allowed_environments' => ['local', 'testing'],
    ],

];
