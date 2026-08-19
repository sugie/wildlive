<?php

namespace App\Simulation\Report;

use App\Simulation\Metrics\RunResult;

/**
 * Turns a batch of runs into something a designer can read in one sitting.
 *
 * Leads with the verdicts, because the question being asked is "does the
 * game match the intent", not "what happened". The per-agent and per-run
 * detail is underneath for when the answer is no and the next question is
 * why.
 *
 * Self-contained HTML: no scripts, no external assets. It is an artefact to
 * be committed, mailed, or opened from a file path, not a web page.
 */
final class HtmlReport
{
    /**
     * @param  array<int, RunResult>  $runs
     * @param  array<int, array<string, mixed>>  $verdicts
     * @param  array<string, mixed>  $meta
     */
    public static function render(array $runs, array $verdicts, array $meta): string
    {
        $byAgent = [];
        foreach ($runs as $run) {
            $byAgent[$run->agent][] = $run;
        }

        $passed = count(array_filter($verdicts, fn ($v) => $v['pass']));
        $total = count($verdicts);

        $h = fn (?string $s) => htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8');

        $css = self::css();
        $generated = $h(date('Y-m-d H:i:s'));
        $summaryClass = $passed === $total ? 'ok' : 'bad';

        $out = <<<HTML
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>WildLive バランスシミュレーション結果</title>
<style>{$css}</style>
</head>
<body>
<div class="wrap">
<header>
  <p class="eyebrow">Balance simulation</p>
  <h1>WildLive バランスシミュレーション結果</h1>
  <p class="meta">
    生成 {$generated} ／ 仮想 {$meta['days']} 日 ／ エージェントあたり {$meta['seeds']} シード
    （seed {$meta['first_seed']} から）／ 実時間 {$meta['wall_clock_seconds']} 秒
  </p>
</header>

<div class="verdict {$summaryClass}">
  <strong>目標曲線 {$passed} / {$total} 達成</strong>
</div>

<h2>目標曲線に対する判定</h2>
<div class="tablewrap">
<table>
<thead><tr><th>ID</th><th>項目</th><th>意図</th><th>実測</th><th>判定</th><th>内訳</th></tr></thead>
<tbody>
HTML;

        foreach ($verdicts as $v) {
            $cls = $v['pass'] ? 'pass' : 'fail';
            $label = $v['pass'] ? 'PASS' : 'FAIL';
            $out .= sprintf(
                "<tr><td><code>%s</code></td><td>%s</td><td>%s</td><td><b>%s</b></td>"
                ."<td class=\"%s\">%s</td><td class=\"note\">%s</td></tr>\n",
                $h($v['id']), $h($v['name']), $h($v['target']), $h($v['actual']),
                $cls, $label, $h($v['note'])
            );
        }

        $out .= "</tbody></table></div>\n<h2>プレイヤー像ごとの結果</h2>\n";

        foreach ($byAgent as $name => $agentRuns) {
            /** @var array<int, RunResult> $agentRuns */
            $first = $agentRuns[0];
            $rows = array_map(fn (RunResult $r) => $r->toArray(), $agentRuns);

            $meanZoo = self::mean(array_column($rows, 'final_zoo_value'));
            $meanExp = self::mean(array_column($rows, 'expeditions'));
            $meanRate = self::mean(array_column($rows, 'capture_rate_percent'));
            $stuck = count(array_filter($agentRuns, fn (RunResult $r) => $r->isStuck()));

            $rares = array_values(array_filter(
                array_map(fn (RunResult $r) => $r->firstRareHours(), $agentRuns),
                fn ($v) => $v !== null
            ));
            $rareText = $rares === []
                ? 'なし'
                : sprintf('%.1f h（%d/%d 回）', self::mean($rares), count($rares), count($agentRuns));

            $out .= sprintf(
                "<section class=\"agent\">\n<h3>%s</h3>\n<p class=\"desc\">%s</p>\n",
                $h($name), $h($first->agentDescription)
            );

            $out .= "<div class=\"stats\">\n";
            $out .= self::stat('平均 Zoo 値', number_format($meanZoo, 0));
            $out .= self::stat('平均遠征回数', number_format($meanExp, 1));
            $out .= self::stat('捕獲成功率', sprintf('%.1f%%', $meanRate));
            $out .= self::stat('初レアまで', $rareText);
            $out .= self::stat('詰み', sprintf('%d / %d', $stuck, count($agentRuns)));
            $out .= "</div>\n";

            $out .= "<div class=\"tablewrap\"><table class=\"runs\">\n"
                ."<thead><tr><th>seed</th><th>遠征</th><th>捕獲</th><th>成功率</th>"
                ."<th>キープ</th><th>リリース</th><th>使った G</th><th>残 G</th>"
                ."<th>Zoo 値</th><th>初レア</th><th>解放マップ</th><th>詰み</th></tr></thead><tbody>\n";

            foreach ($rows as $r) {
                $out .= sprintf(
                    "<tr><td><code>%d</code></td><td>%d</td><td>%d</td><td>%.1f%%</td>"
                    ."<td>%d</td><td>%d</td><td>%s</td><td>%s</td><td><b>%s</b></td>"
                    ."<td>%s</td><td>%d</td><td class=\"%s\">%s</td></tr>\n",
                    $r['seed'], $r['expeditions'], $r['captures'], $r['capture_rate_percent'],
                    $r['keeps'], $r['releases'],
                    number_format($r['spent_g']), number_format($r['final_balance_g']),
                    number_format($r['final_zoo_value']),
                    $r['first_rare_hours'] === null ? '—' : sprintf('%.1f h', $r['first_rare_hours']),
                    count($r['unlocks']),
                    $r['stuck'] ? 'fail' : 'pass',
                    $r['stuck'] ? sprintf('%.2f d', $r['stuck_days']) : '—'
                );
            }

            $out .= "</tbody></table></div>\n";

            // Rarity mix, pooled across this agent's runs.
            $histogram = [];
            foreach ($rows as $r) {
                foreach ($r['rarity_histogram'] as $tier => $count) {
                    $histogram[$tier] = ($histogram[$tier] ?? 0) + $count;
                }
            }
            ksort($histogram);
            $totalCaptures = array_sum($histogram);

            if ($totalCaptures > 0) {
                $out .= "<p class=\"sub\">捕獲したもののレアリティ内訳</p>\n<div class=\"bars\">\n";
                foreach ($histogram as $tier => $count) {
                    $pct = 100 * $count / $totalCaptures;
                    $out .= sprintf(
                        "<div class=\"bar\"><span class=\"lbl\">%s</span>"
                        ."<span class=\"track\"><span class=\"fill t%d\" style=\"width:%.1f%%\"></span></span>"
                        ."<span class=\"val\">%d（%.1f%%）</span></div>\n",
                        $h(self::rarityName((int) $tier)), $tier, max(1.0, $pct), $count, $pct
                    );
                }
                $out .= "</div>\n";
            }

            $out .= "</section>\n";
        }

        $out .= self::methodology($h);
        $out .= "</div>\n</body>\n</html>\n";

        return $out;
    }

    private static function stat(string $label, string $value): string
    {
        return sprintf(
            "<div class=\"stat\"><span class=\"k\">%s</span><span class=\"v\">%s</span></div>\n",
            htmlspecialchars($label, ENT_QUOTES, 'UTF-8'),
            htmlspecialchars($value, ENT_QUOTES, 'UTF-8')
        );
    }

    private static function rarityName(int $tier): string
    {
        return match ($tier) {
            1 => 'Common',
            2 => 'Uncommon',
            3 => 'Rare',
            4 => 'Epic',
            5 => 'Legendary',
            default => "tier {$tier}",
        };
    }

    /** @param array<int, float|int> $values */
    private static function mean(array $values): float
    {
        return $values === [] ? 0.0 : array_sum($values) / count($values);
    }

    private static function methodology(callable $h): string
    {
        return <<<HTML
<h2>読み方と前提</h2>
<div class="box">
  <p>
    <b>本物のゲームロジックを実行しています。</b>HTTP も UI も通らず、コントローラが呼ぶのと同じ
    Application サービス（<code>StartExpedition</code> / <code>ResolveExpedition</code> /
    <code>DecideCapturedAnimal</code>）を直接呼んでいます。遭遇判定も捕獲判定も出荷されるコードそのものです。
  </p>
  <p>
    <b>時間は仮想です。</b><code>Carbon::setTestNow()</code> でアプリ全体の時計を進めているので、
    10 分の遠征は実時間ゼロで終わりますが、ドメインから見れば確かに 10 分経過しています。
    <code>isDue()</code> が真になるまで解決できない規則はそのままです。
  </p>
  <p>
    <b>エージェントはプレイヤーが見られるものしか見ません。</b>マップ画面の遭遇率、ハンターカードの
    ボーナス、自分の残高だけです。捕獲式の中身も、これから振られるサイコロの目も知りません。
  </p>
  <p class="warn">
    <b>最も重要な前提。</b>エージェントは可能になった瞬間に次の遠征を出します。人間は寝ます。
    したがってここでの経過時間は「フィールドにいた時間」であり、
    「◯◯までどれくらい」という数字はすべて<b>最も速い場合の下限</b>です。
    実際のプレイヤーはこれより遅くなります。
  </p>
  <p>
    <b>データベースは汚しません。</b>各プレイスルーはトランザクション内で実行され、必ずロールバックされます。
  </p>
  <p style="margin-bottom:0">
    <b>同じ seed は同じプレイを再現します。</b>乱数は <code>SeededRandomSource</code>（xorshift*）で、
    全エージェントが同じ seed 集合を共有しています。エージェント間の差は運の差ではなく戦略の差です。
    本番の <code>SystemRandomSource</code>（CSPRNG）は変更していません。
  </p>
</div>
HTML;
    }

    private static function css(): string
    {
        return <<<'CSS'
:root{--bg:#fff;--panel:#f7f7f5;--panel2:#f0efec;--border:#e0dfda;--text:#1f1e1b;
--muted:#6b6862;--accent:#b8501f;--ok:#2f6b3a;--bad:#9c3226;--warn:#8a5a00;--code:#f2f1ed}
@media(prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#171614;--panel:#1f1e1b;
--panel2:#262421;--border:#35322d;--text:#eceae5;--muted:#a09b92;--accent:#e08a5c;
--ok:#7fbc8c;--bad:#e08579;--warn:#d9a94e;--code:#232120}}
:root[data-theme=dark]{--bg:#171614;--panel:#1f1e1b;--panel2:#262421;--border:#35322d;
--text:#eceae5;--muted:#a09b92;--accent:#e08a5c;--ok:#7fbc8c;--bad:#e08579;--warn:#d9a94e;--code:#232120}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);line-height:1.75;font-size:15px;
font-family:-apple-system,BlinkMacSystemFont,"Hiragino Sans","Noto Sans JP",sans-serif}
.wrap{max-width:1000px;margin:0 auto;padding:48px 24px 110px}
header{border-bottom:2px solid var(--border);padding-bottom:20px;margin-bottom:28px}
.eyebrow{color:var(--accent);font-size:12px;letter-spacing:.12em;text-transform:uppercase;font-weight:700;margin:0 0 8px}
h1{font-size:26px;margin:0 0 12px;letter-spacing:-.01em}
.meta{color:var(--muted);font-size:13px;margin:0}
h2{font-size:19px;margin:46px 0 12px;padding-top:14px;border-top:1px solid var(--border)}
h3{font-size:16px;margin:0 0 4px}
.verdict{border-radius:8px;padding:14px 20px;font-size:16px;border:1px solid var(--border)}
.verdict.ok{background:rgba(47,107,58,.12);border-left:3px solid var(--ok)}
.verdict.bad{background:rgba(156,50,38,.1);border-left:3px solid var(--bad)}
.tablewrap{overflow-x:auto;margin:0 0 18px}
table{border-collapse:collapse;width:100%;font-size:13px;min-width:560px}
th,td{text-align:left;padding:8px 11px;border-bottom:1px solid var(--border);vertical-align:top}
th{background:var(--panel2);font-weight:600;white-space:nowrap}
td.note{color:var(--muted);font-size:12.5px}
.pass{color:var(--ok);font-weight:700}
.fail{color:var(--bad);font-weight:700}
code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.87em;background:var(--code);padding:1px 5px;border-radius:4px}
section.agent{background:var(--panel);border:1px solid var(--border);border-radius:10px;padding:20px 24px;margin:0 0 22px}
.desc{color:var(--muted);font-size:13.5px;margin:0 0 16px}
.stats{display:flex;flex-wrap:wrap;gap:10px;margin:0 0 18px}
.stat{background:var(--bg);border:1px solid var(--border);border-radius:7px;padding:8px 14px;min-width:120px}
.stat .k{display:block;font-size:11.5px;color:var(--muted)}
.stat .v{display:block;font-size:17px;font-weight:600;font-variant-numeric:tabular-nums}
.sub{font-size:13px;color:var(--muted);margin:16px 0 8px}
.bars{display:flex;flex-direction:column;gap:6px}
.bar{display:flex;align-items:center;gap:10px;font-size:12.5px}
.bar .lbl{width:88px;color:var(--muted);flex-shrink:0}
.bar .track{flex:1;height:14px;background:var(--panel2);border-radius:4px;overflow:hidden;min-width:80px}
.bar .fill{display:block;height:100%;border-radius:4px}
.fill.t1{background:#9aa0a6}.fill.t2{background:#4d9c5a}.fill.t3{background:#3b7dd8}
.fill.t4{background:#8b5cd6}.fill.t5{background:#d99b2e}
.bar .val{width:110px;text-align:right;font-variant-numeric:tabular-nums;flex-shrink:0}
.box{background:var(--panel);border:1px solid var(--border);border-left:3px solid var(--accent);border-radius:6px;padding:16px 20px}
.box p{margin:0 0 12px}
.box .warn{color:var(--text);background:rgba(138,90,0,.1);border-radius:5px;padding:10px 14px}
CSS;
    }
}
