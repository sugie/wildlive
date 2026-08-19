<?php

namespace App\Simulation\Metrics;

/**
 * The design intent, written down so a run can disagree with it.
 *
 * A pile of metrics is not a balance report. What turns numbers into a
 * judgement is a statement of what the game is supposed to feel like, made
 * before the run, in terms a run can contradict. These four came from the
 * designer (decisions A-2a … A-2d) and are the only reason this tool can
 * say "no" rather than just "here are some numbers".
 *
 * They are targets, not laws. A failure here means the current parameters
 * do not produce the intended experience — which may mean the parameters
 * are wrong, or that the intent was. Both are useful; neither is decided
 * by this file.
 */
final class TargetCurve
{
    /** A-2a: median time until the player meets their first Rare or better. */
    public const FIRST_RARE_TARGET_HOURS = 4.0;

    /** Judged against a band, since a median is not a promise. */
    public const FIRST_RARE_TOLERANCE_HOURS = 2.0;

    /** A-2b: median time until Serengeti Plains (Zoo value 100) opens. */
    public const SERENGETI_TARGET_DAYS = 2.0;

    public const SERENGETI_TOLERANCE_DAYS = 1.0;

    /** A-2c: share of players with nothing left to do by day 14. */
    public const MAX_STUCK_PERCENT = 5.0;

    /** A-2d: how far the best strategy may outrun the worst. */
    public const MAX_POLICY_SPREAD = 3.0;

    public const SERENGETI_MAP_ID = 'map_serengeti_plains_002';

    /**
     * Judge a set of runs.
     *
     * @param  array<int, RunResult>  $runs
     * @return array<int, array<string, mixed>>
     */
    public static function evaluate(array $runs): array
    {
        return [
            self::judgeFirstRare($runs),
            self::judgeSerengeti($runs),
            self::judgeStuck($runs),
            self::judgeSpread($runs),
        ];
    }

    /** @param array<int, RunResult> $runs */
    private static function judgeFirstRare(array $runs): array
    {
        $hours = array_values(array_filter(
            array_map(fn (RunResult $r) => $r->firstRareHours(), $runs),
            fn ($v) => $v !== null
        ));

        $reached = count($hours);
        $total = count($runs);

        if ($reached === 0) {
            return self::result(
                'A-2a', 'First Rare',
                sprintf('median %.1f h (±%.1f)', self::FIRST_RARE_TARGET_HOURS, self::FIRST_RARE_TOLERANCE_HOURS),
                'never reached',
                false,
                sprintf('No run in %d met a Rare or better at all.', $total)
            );
        }

        $median = self::median($hours);
        $low = self::FIRST_RARE_TARGET_HOURS - self::FIRST_RARE_TOLERANCE_HOURS;
        $high = self::FIRST_RARE_TARGET_HOURS + self::FIRST_RARE_TOLERANCE_HOURS;
        $pass = $median >= $low && $median <= $high;

        return self::result(
            'A-2a', 'First Rare',
            sprintf('%.1f–%.1f h', $low, $high),
            sprintf('%.1f h', $median),
            $pass,
            sprintf('%d of %d runs reached a Rare.', $reached, $total)
        );
    }

    /** @param array<int, RunResult> $runs */
    private static function judgeSerengeti(array $runs): array
    {
        $days = array_values(array_filter(
            array_map(fn (RunResult $r) => $r->unlockDays(self::SERENGETI_MAP_ID), $runs),
            fn ($v) => $v !== null
        ));

        $total = count($runs);

        if ($days === []) {
            return self::result(
                'A-2b', 'Serengeti unlock',
                sprintf('median %.1f d (±%.1f)', self::SERENGETI_TARGET_DAYS, self::SERENGETI_TOLERANCE_DAYS),
                'never unlocked',
                false,
                sprintf('No run in %d reached Zoo value 100.', $total)
            );
        }

        $median = self::median($days);
        $low = max(0, self::SERENGETI_TARGET_DAYS - self::SERENGETI_TOLERANCE_DAYS);
        $high = self::SERENGETI_TARGET_DAYS + self::SERENGETI_TOLERANCE_DAYS;
        $pass = $median >= $low && $median <= $high;

        return self::result(
            'A-2b', 'Serengeti unlock',
            sprintf('%.1f–%.1f d', $low, $high),
            sprintf('%.2f d', $median),
            $pass,
            sprintf('%d of %d runs unlocked it.', count($days), $total)
        );
    }

    /** @param array<int, RunResult> $runs */
    private static function judgeStuck(array $runs): array
    {
        $total = max(1, count($runs));
        $stuck = count(array_filter($runs, fn (RunResult $r) => $r->isStuck()));
        $percent = round(100 * $stuck / $total, 1);

        return self::result(
            'A-2c', 'Stuck by day 14',
            sprintf('< %.0f%%', self::MAX_STUCK_PERCENT),
            sprintf('%.1f%%', $percent),
            $percent < self::MAX_STUCK_PERCENT,
            sprintf('%d of %d runs ran out of affordable options.', $stuck, $total)
        );
    }

    /** @param array<int, RunResult> $runs */
    private static function judgeSpread(array $runs): array
    {
        // Compare strategies, not individual runs: average each agent, then
        // measure best against worst.
        $byAgent = [];
        foreach ($runs as $run) {
            $byAgent[$run->agent][] = $run->finalZooValue();
        }

        $means = array_map(fn (array $v) => array_sum($v) / count($v), $byAgent);
        $best = max($means);
        $worst = min($means);

        if ($worst <= 0) {
            return self::result(
                'A-2d', 'Strategy spread',
                sprintf('≤ %.0f×', self::MAX_POLICY_SPREAD),
                $best <= 0 ? 'no strategy scored' : 'unbounded',
                false,
                $best <= 0
                    ? 'Every strategy finished with a Zoo value of zero.'
                    : sprintf('The weakest strategy (%s) finished at zero, so the ratio is undefined.',
                        array_search($worst, $means, true))
            );
        }

        $spread = $best / $worst;

        return self::result(
            'A-2d', 'Strategy spread',
            sprintf('≤ %.0f×', self::MAX_POLICY_SPREAD),
            sprintf('%.2f×', $spread),
            $spread <= self::MAX_POLICY_SPREAD,
            sprintf('Best %s (%.0f) vs worst %s (%.0f) by mean final Zoo value.',
                array_search($best, $means, true), $best,
                array_search($worst, $means, true), $worst)
        );
    }

    /** @param array<int, float> $values */
    private static function median(array $values): float
    {
        sort($values);
        $count = count($values);
        $mid = intdiv($count, 2);

        return $count % 2 === 1
            ? $values[$mid]
            : ($values[$mid - 1] + $values[$mid]) / 2;
    }

    private static function result(
        string $id,
        string $name,
        string $target,
        string $actual,
        bool $pass,
        string $note,
    ): array {
        return compact('id', 'name', 'target', 'actual', 'pass', 'note');
    }
}
