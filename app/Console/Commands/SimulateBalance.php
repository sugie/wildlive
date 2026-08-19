<?php

namespace App\Console\Commands;

use App\Domain\Support\RandomSource;
use App\Infrastructure\Random\SeededRandomSource;
use App\Simulation\Agents\Casual;
use App\Simulation\Agents\Collector;
use App\Simulation\Agents\Frugal;
use App\Simulation\Agents\Impatient;
use App\Simulation\Agents\PlayerAgent;
use App\Simulation\Agents\ValueSeeker;
use App\Simulation\Metrics\TargetCurve;
use App\Simulation\Report\HtmlReport;
use App\Simulation\Simulator;
use Illuminate\Console\Command;

/**
 * Play the game many times over, without a client, and report.
 *
 * Runs each agent against the same seeds so the strategies are compared on
 * identical luck: any difference between them is the strategy, not the
 * dice. Writes a JSON file for diffing runs against each other and an HTML
 * report for a human to read.
 *
 * Nothing here touches production. The seeded RandomSource is bound only
 * for the lifetime of this command, and every playthrough runs inside a
 * transaction that is rolled back.
 */
final class SimulateBalance extends Command
{
    protected $signature = 'wildlive:simulate
        {--days=14 : Virtual days to play}
        {--seeds=5 : Playthroughs per agent, each with its own seed}
        {--seed=42 : First seed; later runs use seed+1, seed+2, …}
        {--agents= : Comma-separated agent names (default: all)}
        {--out=storage/sim : Directory for the report files}';

    protected $description = 'Test-play WildLive with simulated players and judge the balance';

    public function handle(): int
    {
        $days = (int) $this->option('days');
        $seedCount = (int) $this->option('seeds');
        $firstSeed = (int) $this->option('seed');
        $outDir = base_path((string) $this->option('out'));

        $wanted = $this->option('agents');
        $wanted = $wanted === null || $wanted === ''
            ? null
            : array_map('trim', explode(',', (string) $wanted));

        $runs = [];
        $started = microtime(true);

        foreach (range(0, $seedCount - 1) as $offset) {
            $seed = $firstSeed + $offset;

            foreach ($this->agentFactories() as $name => $factory) {
                if ($wanted !== null && ! in_array($name, $wanted, true)) {
                    continue;
                }

                // A fresh generator per run, bound before the services are
                // resolved so every roll the domain makes comes from it.
                $random = new SeededRandomSource($seed);
                $this->laravel->instance(RandomSource::class, $random);

                /** @var PlayerAgent $agent */
                $agent = $factory($random);

                /** @var Simulator $simulator */
                $simulator = $this->laravel->make(Simulator::class);

                $this->line(sprintf('  <fg=gray>seed %d</> %s …', $seed, $name));
                $run = $simulator->run($agent, $days, $seed);
                $runs[] = $run;

                $this->line(sprintf(
                    '    %d expeditions, %d captures, zoo %d, %s',
                    $run->toArray()['expeditions'],
                    $run->toArray()['captures'],
                    $run->finalZooValue(),
                    $run->isStuck()
                        ? sprintf('<fg=red>stuck at day %.2f</>', $run->stuckDays())
                        : '<fg=green>still playing</>'
                ));
            }
        }

        // Put production's generator back, in case anything else in this
        // process still needs it.
        $this->laravel->forgetInstance(RandomSource::class);

        $verdicts = TargetCurve::evaluate($runs);
        $elapsed = round(microtime(true) - $started, 1);

        $this->newLine();
        $this->table(
            ['ID', 'Target curve', 'Wanted', 'Measured', ''],
            array_map(fn (array $v) => [
                $v['id'], $v['name'], $v['target'], $v['actual'],
                $v['pass'] ? '<fg=green>PASS</>' : '<fg=red>FAIL</>',
            ], $verdicts)
        );

        @mkdir($outDir, 0755, true);
        $stamp = date('Ymd-His');

        $json = $outDir."/run-{$stamp}.json";
        file_put_contents($json, json_encode([
            'generated_at' => date('c'),
            'days' => $days,
            'seeds' => $seedCount,
            'first_seed' => $firstSeed,
            'wall_clock_seconds' => $elapsed,
            'verdicts' => $verdicts,
            'runs' => array_map(fn ($r) => $r->toArray(), $runs),
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));

        $html = $outDir."/report-{$stamp}.html";
        file_put_contents($html, HtmlReport::render($runs, $verdicts, [
            'days' => $days,
            'seeds' => $seedCount,
            'first_seed' => $firstSeed,
            'wall_clock_seconds' => $elapsed,
        ]));

        $this->newLine();
        $this->info("JSON  {$json}");
        $this->info("HTML  {$html}");

        // A failing target curve is a finding, not a broken command: the
        // whole point is to be told when the game does not match the intent.
        return self::SUCCESS;
    }

    /** @return array<string, callable(RandomSource): PlayerAgent> */
    private function agentFactories(): array
    {
        return [
            'frugal' => fn (RandomSource $r) => new Frugal(),
            'value-seeker' => fn (RandomSource $r) => new ValueSeeker(),
            'collector' => fn (RandomSource $r) => new Collector(),
            'impatient' => fn (RandomSource $r) => new Impatient(),
            'casual' => fn (RandomSource $r) => new Casual($r),
        ];
    }
}
