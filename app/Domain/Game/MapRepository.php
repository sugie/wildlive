<?php

namespace App\Domain\Game;

use App\Models\Map;
use Illuminate\Support\Collection;

/**
 * Read access to Game Master Map rows.
 *
 * Master data is never written at runtime, so this contract is read-only:
 * the only writer is Database\Seeders\GameMasterSeeder.
 */
interface MapRepository
{
    /**
     * Every map that ships in the current release, in unlock order.
     *
     * @return Collection<int, Map>
     */
    public function released(): Collection;

    public function find(string $mapId): ?Map;

    /**
     * A map with its spawn table eager-loaded
     * (mapAnimals → animal → rarity), ready for EncounterTable.
     */
    public function findWithSpawnTable(string $mapId): ?Map;
}
