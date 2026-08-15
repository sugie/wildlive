<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Base for Game Master v0.3 master-data models.
 *
 * Master rows share three properties that differ from gameplay rows:
 *
 *   - the primary key is the Game Master's own string id, not an integer
 *     or UUID (`animal_impala_001`), so the workbook → JSON → DB → API
 *     chain stays readable end to end;
 *   - they carry no created_at / updated_at — a master row has no
 *     lifecycle, it is replaced wholesale by the seeder;
 *   - they are never written by gameplay code, only by GameMasterSeeder.
 */
abstract class MasterModel extends Model
{
    public $incrementing = false;

    public $timestamps = false;

    protected $keyType = 'string';
}
