<?php

namespace App\Providers;

use App\Domain\Players\PlayerRepository;
use App\Domain\Players\ZooRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentPlayerRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentZooRepository;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Bind domain repository contracts to their Eloquent-backed
     * implementations. The rest of the object graph (Application use
     * cases, HTTP controllers) is auto-resolved by Laravel's container
     * via constructor injection.
     */
    public function register(): void
    {
        $this->app->bind(PlayerRepository::class, EloquentPlayerRepository::class);
        $this->app->bind(ZooRepository::class, EloquentZooRepository::class);
    }

    public function boot(): void
    {
        //
    }
}
