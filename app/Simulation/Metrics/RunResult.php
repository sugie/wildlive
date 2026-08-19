<?php

namespace App\Simulation\Metrics;

/**
 * What one agent's playthrough produced.
 *
 * Accumulates while the run happens, then answers the questions the target
 * curve asks. Everything is recorded against elapsed virtual minutes rather
 * than expedition count, because the design intent is stated in hours and
 * days ("a player should meet their first Rare within about four hours").
 */
final class RunResult
{
    /** Rare and above — the tier worth a celebration. */
    public const RARE_SORT_ORDER = 3;

    private int $expeditions = 0;

    private int $captures = 0;

    private int $misses = 0;

    private int $keeps = 0;

    private int $releases = 0;

    private int $spentG = 0;

    private ?int $firstRareAtMinutes = null;

    private ?int $stuckAtMinutes = null;

    private ?string $rejectedWith = null;

    private int $elapsedMinutes = 0;

    private int $finalBalance = 0;

    private int $finalZooValue = 0;

    /** @var array<int, int> rarity sort_order => times encountered */
    private array $rarityHistogram = [];

    /** @var array<int, array{minutes: int, value: int}> */
    private array $zooValueTimeline = [];

    /** @var array<int, array{minutes: int, balance: int}> */
    private array $balanceTimeline = [];

    /** @var array<string, array{name: string, minutes: int}> */
    private array $unlocks = [];

    public function __construct(
        public readonly string $agent,
        public readonly string $agentDescription,
        public readonly int $seed,
        public readonly int $days,
    ) {
    }

    // -- Recording --------------------------------------------------------

    public function recordExpedition(int $elapsedMinutes, int $costG, string $mapId, int $durationMinutes): void
    {
        $this->expeditions++;
        $this->spentG += $costG;
    }

    public function recordMiss(): void
    {
        $this->misses++;
    }

    /** @param array<string, mixed> $species */
    public function recordCapture(int $elapsedMinutes, array $species): void
    {
        $this->captures++;

        $tier = (int) $species['rarity']['sort_order'];
        $this->rarityHistogram[$tier] = ($this->rarityHistogram[$tier] ?? 0) + 1;

        if ($tier >= self::RARE_SORT_ORDER && $this->firstRareAtMinutes === null) {
            $this->firstRareAtMinutes = $elapsedMinutes;
        }
    }

    /** @param array<string, mixed> $species */
    public function recordKeep(array $species): void
    {
        $this->keeps++;
    }

    /** @param array<string, mixed> $species */
    public function recordRelease(array $species): void
    {
        $this->releases++;
    }

    public function recordZooValue(int $minutes, int $value): void
    {
        $this->zooValueTimeline[] = ['minutes' => $minutes, 'value' => $value];
    }

    public function recordBalance(int $minutes, int $balance): void
    {
        $this->balanceTimeline[] = ['minutes' => $minutes, 'balance' => $balance];
    }

    public function recordUnlock(string $mapId, string $name, int $minutes): void
    {
        // First time only: an unlock is a moment, and re-seeing it on a
        // later tick must not move it later.
        $this->unlocks[$mapId] ??= ['name' => $name, 'minutes' => $minutes];
    }

    public function recordStuck(int $minutes, int $balance): void
    {
        $this->stuckAtMinutes ??= $minutes;
    }

    public function recordRejection(string $code): void
    {
        $this->rejectedWith = $code;
    }

    public function finish(int $elapsedMinutes, int $finalBalance, int $finalZooValue): void
    {
        $this->elapsedMinutes = $elapsedMinutes;
        $this->finalBalance = $finalBalance;
        $this->finalZooValue = $finalZooValue;
    }

    // -- Questions the target curve asks ----------------------------------

    public function firstRareHours(): ?float
    {
        return $this->firstRareAtMinutes === null
            ? null
            : round($this->firstRareAtMinutes / 60, 2);
    }

    /** When the given map became available, in days. Null if it never did. */
    public function unlockDays(string $mapId): ?float
    {
        return isset($this->unlocks[$mapId])
            ? round($this->unlocks[$mapId]['minutes'] / 1440, 2)
            : null;
    }

    public function isStuck(): bool
    {
        return $this->stuckAtMinutes !== null;
    }

    public function stuckDays(): ?float
    {
        return $this->stuckAtMinutes === null ? null : round($this->stuckAtMinutes / 1440, 2);
    }

    public function captureRate(): float
    {
        return $this->expeditions === 0
            ? 0.0
            : round(100 * $this->captures / $this->expeditions, 1);
    }

    public function finalZooValue(): int
    {
        return $this->finalZooValue;
    }

    /** @return array<string, mixed> */
    public function toArray(): array
    {
        ksort($this->rarityHistogram);

        return [
            'agent' => $this->agent,
            'agent_description' => $this->agentDescription,
            'seed' => $this->seed,
            'days_requested' => $this->days,
            'elapsed_minutes' => $this->elapsedMinutes,
            'elapsed_days' => round($this->elapsedMinutes / 1440, 2),
            'expeditions' => $this->expeditions,
            'captures' => $this->captures,
            'misses' => $this->misses,
            'capture_rate_percent' => $this->captureRate(),
            'keeps' => $this->keeps,
            'releases' => $this->releases,
            'spent_g' => $this->spentG,
            'final_balance_g' => $this->finalBalance,
            'final_zoo_value' => $this->finalZooValue,
            'first_rare_hours' => $this->firstRareHours(),
            'stuck' => $this->isStuck(),
            'stuck_days' => $this->stuckDays(),
            'rejected_with' => $this->rejectedWith,
            'rarity_histogram' => $this->rarityHistogram,
            'unlocks' => $this->unlocks,
            'zoo_value_timeline' => $this->zooValueTimeline,
            'balance_timeline' => $this->balanceTimeline,
        ];
    }
}
