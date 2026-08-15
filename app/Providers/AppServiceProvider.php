<?php

namespace App\Providers;

use App\Application\Expeditions\DevExpeditionPolicy;
use App\Domain\Game\ExpeditionRepository;
use App\Domain\Game\HunterRepository;
use App\Domain\Game\MapRepository;
use App\Domain\Game\ZooAnimalRepository;
use App\Domain\Players\PlayerRepository;
use App\Domain\Players\ZooRepository;
use App\Domain\Support\RandomSource;
use App\Infrastructure\Persistence\Eloquent\EloquentExpeditionRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentHunterRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentMapRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentPlayerRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentZooAnimalRepository;
use App\Infrastructure\Persistence\Eloquent\EloquentZooRepository;
use App\Infrastructure\Random\SystemRandomSource;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Bind domain contracts to their implementations. The rest of the
     * object graph (Application use cases, Domain rule objects, HTTP
     * controllers) is auto-resolved by Laravel's container via constructor
     * injection — none of those have interfaces to bind, so none are
     * listed here.
     */
    public function register(): void
    {
        $this->app->bind(PlayerRepository::class, EloquentPlayerRepository::class);
        $this->app->bind(ZooRepository::class, EloquentZooRepository::class);
        $this->app->bind(MapRepository::class, EloquentMapRepository::class);
        $this->app->bind(HunterRepository::class, EloquentHunterRepository::class);
        $this->app->bind(ExpeditionRepository::class, EloquentExpeditionRepository::class);
        $this->app->bind(ZooAnimalRepository::class, EloquentZooAnimalRepository::class);

        // Every gameplay roll goes through this one binding. A test that
        // needs a fixed outcome swaps it for a scripted sequence; nothing
        // in the game calls random_int() directly.
        $this->app->bind(RandomSource::class, SystemRandomSource::class);

        // The development-only "resolve immediately" shortcut. Wired from
        // config here so the policy itself stays framework-free and
        // unit-testable. See config/wildlive.php.
        $this->app->singleton(DevExpeditionPolicy::class, fn ($app) => new DevExpeditionPolicy(
            enabled: (bool) config('wildlive.dev.instant_expeditions', false),
            environment: (string) $app->environment(),
            allowedEnvironments: (array) config('wildlive.dev.allowed_environments', ['local', 'testing']),
        ));
    }

    public function boot(): void
    {
        //
    }
}
