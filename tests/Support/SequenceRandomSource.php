<?php

namespace Tests\Support;

use App\Domain\Support\RandomSource;
use RuntimeException;

/**
 * A RandomSource that returns exactly what the test told it to.
 *
 * Every gameplay roll goes through RandomSource, so scripting it makes an
 * expedition's outcome fully determined: no test in this suite can fail
 * intermittently because of a dice roll.
 *
 * Values are clamped into the requested range rather than returned raw, so
 * a test can say "roll low" with 1 and "roll high" with 100 without
 * knowing whether the call site is a d100 or a draw over a total weight.
 */
final class SequenceRandomSource implements RandomSource
{
    /** @var array<int, int> */
    private array $remaining;

    /** @var array<int, array{min: int, max: int, returned: int}> */
    private array $calls = [];

    /**
     * @param  array<int, int>  $values  returned in order, one per call
     */
    public function __construct(array $values = [])
    {
        $this->remaining = array_values($values);
    }

    /**
     * Queue more values behind whatever is left.
     *
     * Needed because Laravel caches the resolved controller on the Route
     * object, so a second container binding made partway through a test
     * never reaches a route that has already been hit once. Extending the
     * one instance the first request captured is what actually works.
     *
     * @param  array<int, int>  $values
     */
    public function push(array $values): void
    {
        foreach ($values as $value) {
            $this->remaining[] = $value;
        }
    }

    public function int(int $min, int $max): int
    {
        if ($this->remaining === []) {
            throw new RuntimeException(sprintf(
                'SequenceRandomSource ran out of values (call %d asked for [%d, %d]). '
                .'The code under test made more rolls than the test scripted.',
                count($this->calls) + 1,
                $min,
                $max
            ));
        }

        $value = array_shift($this->remaining);
        $clamped = max($min, min($max, $value));

        $this->calls[] = ['min' => $min, 'max' => $max, 'returned' => $clamped];

        return $clamped;
    }

    /** @return array<int, array{min: int, max: int, returned: int}> */
    public function calls(): array
    {
        return $this->calls;
    }

    public function callCount(): int
    {
        return count($this->calls);
    }
}
