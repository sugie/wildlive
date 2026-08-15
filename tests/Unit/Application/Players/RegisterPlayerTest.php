<?php

namespace Tests\Unit\Application\Players;

use App\Application\Players\RegisterPlayer;
use App\Application\Players\RegisterPlayerInput;
use App\Application\Players\RegisteredPlayer;
use App\Domain\Players\PlayerRepository;
use App\Domain\Players\ZooRepository;
use App\Models\Player;
use App\Models\Zoo;
use Closure;
use Illuminate\Database\ConnectionInterface;
use PHPUnit\Framework\TestCase;
use RuntimeException;

/**
 * Unit tests for the RegisterPlayer application-layer use case.
 *
 * These tests exercise the Application Layer in isolation:
 *   - No HTTP boot.
 *   - No Eloquent connection (no database).
 *   - No Laravel container.
 *
 * Repository fakes are hand-rolled (no Mockery / Prophecy) so the test
 * file also documents what the repositories are expected to do. The
 * ConnectionInterface fake uses PHPUnit's built-in double so the test
 * survives future evolutions of Laravel's connection signature.
 */
class RegisterPlayerTest extends TestCase
{
    public function test_creates_player_then_zoo_and_returns_result(): void
    {
        $connection = $this->fakeConnection($transactionCalls);
        $playerRepo = new InMemoryPlayerRepository();
        $zooRepo = new InMemoryZooRepository();

        $useCase = new RegisterPlayer($connection, $playerRepo, $zooRepo);
        $result = ($useCase)(new RegisterPlayerInput(displayName: 'Kai'));

        $this->assertInstanceOf(RegisteredPlayer::class, $result);
        $this->assertSame('Kai', $result->player->display_name);
        $this->assertSame($result->player->id, $result->zoo->player_id,
            'zoo returned by the use case must belong to the player');

        $this->assertSame(['Kai'], $playerRepo->createdDisplayNames,
            'PlayerRepository::create called exactly once with the given display name');
        $this->assertSame([$result->player->id], $zooRepo->createdForPlayerIds,
            'ZooRepository::createForPlayer called exactly once with the created player');
    }

    public function test_wraps_creation_in_a_single_transaction(): void
    {
        $connection = $this->fakeConnection($transactionCalls);
        $useCase = new RegisterPlayer(
            $connection,
            new InMemoryPlayerRepository(),
            new InMemoryZooRepository()
        );

        ($useCase)(new RegisterPlayerInput(displayName: 'Rin'));

        $this->assertSame(1, $transactionCalls,
            'exactly one transaction opened per use-case invocation');
    }

    public function test_player_repo_is_called_before_zoo_repo(): void
    {
        $order = [];
        $playerRepo = new InMemoryPlayerRepository(onCreate: function () use (&$order): void {
            $order[] = 'player';
        });
        $zooRepo = new InMemoryZooRepository(onCreate: function () use (&$order): void {
            $order[] = 'zoo';
        });

        $useCase = new RegisterPlayer($this->fakeConnection($_), $playerRepo, $zooRepo);
        ($useCase)(new RegisterPlayerInput(displayName: 'Order'));

        $this->assertSame(['player', 'zoo'], $order,
            'Zoo depends on the created Player, so PlayerRepository must be called first');
    }

    public function test_passes_through_display_name_verbatim(): void
    {
        // Trimming and length validation are Presentation-Layer concerns
        // (RegisterPlayerRequest). The use case must not silently transform.
        $playerRepo = new InMemoryPlayerRepository();
        $useCase = new RegisterPlayer(
            $this->fakeConnection($_),
            $playerRepo,
            new InMemoryZooRepository()
        );

        ($useCase)(new RegisterPlayerInput(displayName: '  padded  '));

        $this->assertSame(['  padded  '], $playerRepo->createdDisplayNames,
            'use case must not silently trim / re-validate input');
    }

    public function test_exception_from_zoo_repo_propagates_and_transaction_was_used(): void
    {
        $connection = $this->fakeConnection($transactionCalls);
        $useCase = new RegisterPlayer(
            $connection,
            new InMemoryPlayerRepository(),
            new InMemoryZooRepository(
                onCreate: function (): void {
                    throw new RuntimeException('simulated zoo insert failure');
                }
            )
        );

        try {
            ($useCase)(new RegisterPlayerInput(displayName: 'Boom'));
            $this->fail('exception should have propagated out of the use case');
        } catch (RuntimeException $e) {
            $this->assertSame('simulated zoo insert failure', $e->getMessage());
        }

        $this->assertSame(1, $transactionCalls,
            'transaction was opened even though the closure threw');
    }

    public function test_exception_from_player_repo_propagates_and_zoo_is_never_called(): void
    {
        $zooRepo = new InMemoryZooRepository();

        $useCase = new RegisterPlayer(
            $this->fakeConnection($_),
            new InMemoryPlayerRepository(
                onCreate: function (): void {
                    throw new RuntimeException('simulated player insert failure');
                }
            ),
            $zooRepo
        );

        $this->expectException(RuntimeException::class);
        try {
            ($useCase)(new RegisterPlayerInput(displayName: 'Boom'));
        } finally {
            $this->assertSame([], $zooRepo->createdForPlayerIds,
                'zoo repository must not be reached if player creation failed');
        }
    }

    // -- helper --------------------------------------------------------------

    /**
     * Build a ConnectionInterface double whose only meaningful method is
     * transaction(): it runs the closure inline (mirroring a successful
     * commit) and increments an out-parameter counter.
     *
     * PHPUnit's createStub generates a subclass that matches whichever
     * ConnectionInterface signature the installed Laravel ships — this
     * insulates the tests from Laravel adding parameters to methods like
     * select() that RegisterPlayer never calls. `createStub` (not
     * `createMock`) is used because we do not verify per-method
     * invocation counts on the connection itself; the invocation count
     * we care about is exposed via `$transactionCalls`.
     */
    private function fakeConnection(?int &$transactionCalls = null): ConnectionInterface
    {
        $transactionCalls = 0;
        $counter = &$transactionCalls;

        /** @var ConnectionInterface&\PHPUnit\Framework\MockObject\Stub $stub */
        $stub = $this->createStub(ConnectionInterface::class);
        $stub->method('transaction')
            ->willReturnCallback(function (Closure $callback) use (&$counter, $stub) {
                $counter++;
                return $callback($stub);
            });
        return $stub;
    }
}

// -- Test doubles -------------------------------------------------------------

/**
 * Records calls and returns a plain Eloquent Player instance without
 * touching the database (Eloquent supports being constructed without a
 * PDO connection as long as save() / refresh() are never called).
 */
final class InMemoryPlayerRepository implements PlayerRepository
{
    /** @var array<int, string> */
    public array $createdDisplayNames = [];

    public function __construct(
        private readonly ?Closure $onCreate = null,
    ) {
    }

    public function create(string $displayName): Player
    {
        if ($this->onCreate !== null) {
            ($this->onCreate)();
        }
        $this->createdDisplayNames[] = $displayName;

        $player = new Player();
        $player->id = 'test-player-' . count($this->createdDisplayNames);
        $player->display_name = $displayName;
        return $player;
    }
}

final class InMemoryZooRepository implements ZooRepository
{
    /** @var array<int, string> */
    public array $createdForPlayerIds = [];

    public function __construct(
        private readonly ?Closure $onCreate = null,
    ) {
    }

    public function createForPlayer(Player $player): Zoo
    {
        if ($this->onCreate !== null) {
            ($this->onCreate)();
        }
        $this->createdForPlayerIds[] = $player->id;

        $zoo = new Zoo();
        $zoo->id = 'test-zoo-' . count($this->createdForPlayerIds);
        $zoo->player_id = $player->id;
        return $zoo;
    }
}
