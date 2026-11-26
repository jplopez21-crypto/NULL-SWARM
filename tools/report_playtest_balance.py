#!/usr/bin/env python3
"""Summarize normal-play observations; compare matched conditions, not host speed."""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
import math
from pathlib import Path
import statistics

REPORTS = ('bot-report.json', 'extended-seeds.json', 'corruption-probe.json', 'engineer-probe.json')
CONDITIONS = ('profile', 'kit', 'fixture', 'bot_policy', 'pickup_mode', 'link_policy')
METRICS = ('survived_seconds', 'kills', 'level', 'xp_collected', 'uncollected_xp',
           'first_level_seconds', 'first_new_weapon_seconds', 'longest_upgrade_gap_seconds')
LIMITS = [
    'Fixed-seed bot observations, not human enjoyment, retention or population win-rate estimates.',
    'Suites, kits, fixtures, policies and research remain separate; medians describe only the recorded seeds.',
    'Missing first-level/weapon events are unobserved, not zero seconds. Mutation times include reached runs only.',
    'Comparison covers selected balance observations. Full gameplay determinism is checked separately.',
    'Host CPU timings are excluded. No Android rendering, phone FPS, touch-latency or thermal claim.',
    'Victories, defeats and time limits are observations; valid balance changes do not fail this tool.',
]


def number(value, label, minimum=0):
    try:
        valid = type(value) in (int, float) and math.isfinite(value) and value >= minimum
    except OverflowError:
        valid = False
    if not valid:
        raise ValueError(f'{label}: expected a finite number >= {minimum}')
    return value


def load_runs(folder):
    cases, sources, seen = [], {}, set()
    for name in REPORTS:
        path = Path(folder) / name
        raw = path.read_bytes()
        report = json.loads(raw)
        if (not isinstance(report, dict) or type(report.get('schema')) is not int or report['schema'] != 1
                or report.get('failures') != [] or not isinstance(report.get('kind'), str)
                or 'normal-rules' not in report['kind'] or not isinstance(report.get('cases'), list)
                or not report['cases'] or not isinstance(report.get('godot'), str) or not report['godot']):
            raise ValueError(f'{name}: incomplete, failed or unsupported normal-play report')
        step = number(report.get('fixed_step'), f'{name}/fixed_step')
        if step <= 0:
            raise ValueError(f'{name}: fixed_step must be positive')
        sources[name] = {'sha256': hashlib.sha256(raw).hexdigest(), 'schema': 1,
                         'godot': report['godot'], 'fixed_step': step, 'kind': report['kind']}
        for source in report['cases']:
            if not isinstance(source, dict):
                raise ValueError(f'{name}: case must be an object')
            conditions = {'suite': name}
            for key in CONDITIONS:
                if not isinstance(source.get(key), str) or not source[key]:
                    raise ValueError(f'{name}: missing case condition {key}')
                conditions[key] = source[key]
            research = source.get('research')
            if not isinstance(research, dict) or any(not isinstance(k, str) or type(v) is not int or v < 0 for k, v in research.items()):
                raise ValueError(f'{name}: invalid research conditions')
            conditions['research'] = dict(sorted(research.items()))
            if type(source.get('seed')) is not int:
                raise ValueError(f'{name}: seed must be an integer')
            identity = {**conditions, 'seed': source['seed']}
            key = json.dumps(identity, sort_keys=True)
            if key in seen:
                raise ValueError(f'{name}: duplicate case identity {key}')
            seen.add(key)
            if source.get('outcome') not in ('victory', 'defeat', 'time_limit'):
                raise ValueError(f'{name}: invalid outcome')
            metrics = {}
            for metric in METRICS:
                value = number(source.get(metric), f'{name}/{metric}', -1 if metric.startswith('first_') else 0)
                if metric in ('kills', 'level', 'xp_collected', 'uncollected_xp') and type(value) is not int:
                    raise ValueError(f'{name}/{metric}: expected an integer')
                if metric.startswith('first_'):
                    if value < 0 and value != -1:
                        raise ValueError(f'{name}/{metric}: only -1 means unobserved')
                    value = None if value == -1 else value
                metrics[metric] = value
            duration = metrics['survived_seconds']
            if duration <= 0 or metrics['level'] < 1:
                raise ValueError(f'{name}: invalid duration or level')
            if any(metrics[k] is not None and metrics[k] > duration + .02 for k in ('first_level_seconds', 'first_new_weapon_seconds')):
                raise ValueError(f'{name}: event after run end')
            mutations = source.get('mutations')
            if not isinstance(mutations, dict):
                raise ValueError(f'{name}: mutation observations must be an object')
            for mutation, at in mutations.items():
                if not isinstance(mutation, str) or not mutation or number(at, f'{name}/mutation') > duration + .02:
                    raise ValueError(f'{name}: invalid mutation observation')
            cases.append({'identity': identity, 'outcome': source['outcome'], 'metrics': metrics,
                          'mutations': dict(sorted(mutations.items()))})
    return {'sources': sources, 'cases': sorted(cases, key=lambda c: json.dumps(c['identity'], sort_keys=True))}


def distribution(values):
    values = list(values)
    observed = [v for v in values if v is not None]
    return {'observed': len(observed), 'unobserved': len(values) - len(observed),
            'median': statistics.median(observed) if observed else None,
            'minimum': min(observed) if observed else None, 'maximum': max(observed) if observed else None}


def summarize(cases):
    cohorts = defaultdict(list)
    for case in cases:
        conditions = {k: v for k, v in case['identity'].items() if k != 'seed'}
        cohorts[json.dumps(conditions, sort_keys=True)].append(case)
    groups = []
    for key, group in sorted(cohorts.items()):
        mutations = sorted({name for case in group for name in case['mutations']})
        groups.append({'conditions': json.loads(key), 'runs': len(group),
                       'seeds': sorted(c['identity']['seed'] for c in group),
                       'outcomes': dict(Counter(c['outcome'] for c in group)),
                       'metrics': {name: distribution(c['metrics'][name] for c in group) for name in METRICS},
                       'mutations': {name: distribution(c['mutations'].get(name) for c in group) for name in mutations}})
    return groups


def compare(baseline, candidate):
    for name in REPORTS:
        for key in ('schema', 'godot', 'fixed_step', 'kind'):
            if baseline['sources'][name][key] != candidate['sources'][name][key]:
                raise ValueError(f'{name}: incompatible comparison metadata: {key}')
    old = {json.dumps(c['identity'], sort_keys=True): c for c in baseline['cases']}
    new = {json.dumps(c['identity'], sort_keys=True): c for c in candidate['cases']}
    changes = []
    for key in sorted(old.keys() & new.keys()):
        a, b = old[key], new[key]
        if a == b:
            continue
        deltas = {m: {'before': a['metrics'][m], 'after': b['metrics'][m],
                      'delta': b['metrics'][m] - a['metrics'][m] if a['metrics'][m] is not None and b['metrics'][m] is not None else None}
                  for m in METRICS if a['metrics'][m] != b['metrics'][m]}
        changes.append({'identity': b['identity'], 'outcome': {'before': a['outcome'], 'after': b['outcome']},
                        'metrics': deltas, 'mutations': {'before': a['mutations'], 'after': b['mutations']}})
    return {'matched': len(old.keys() & new.keys()), 'changed_observations': len(changes), 'changes': changes,
            'added': [new[k]['identity'] for k in sorted(new.keys() - old.keys())],
            'removed': [old[k]['identity'] for k in sorted(old.keys() - new.keys())]}


def markdown(report):
    def cell(value):
        return str(value).replace('|', '\\|').replace('\n', ' ')
    def median(group, key):
        value = group['metrics'][key]['median']
        return 'unobserved' if value is None else f'{value:.2f}'
    lines = ['# Normal-play balance observations', '', *[f'- {limit}' for limit in LIMITS], '',
             '| Suite / build / kit / conditions | Runs | Outcomes | Survival median (s) | First weapon median (s) | Longest upgrade gap median (s) | Collected / left XP medians |',
             '|---|---:|---|---:|---:|---:|---:|']
    for index, group in enumerate(report['cohorts'], 1):
        c = group['conditions']
        label = f'C{index:02d} / ' + ' / '.join(str(c[k]) for k in ('suite', *CONDITIONS)) + ' / research=' + json.dumps(c['research'], sort_keys=True)
        outcomes = ', '.join(f'{name}: {count}' for name, count in sorted(group['outcomes'].items()))
        lines.append(f'| {cell(label)} | {group["runs"]} | {outcomes} | {median(group,"survived_seconds")} | {median(group,"first_new_weapon_seconds")} | {median(group,"longest_upgrade_gap_seconds")} | {median(group,"xp_collected")} / {median(group,"uncollected_xp")} |')
    lines += ['', '| Cohort / mutation | Reached / runs | Observed median (s) | Observed range (s) |', '|---|---:|---:|---|']
    for index, group in enumerate(report['cohorts'], 1):
        for mutation, values in group['mutations'].items():
            lines.append(f'| C{index:02d} / {cell(mutation)} | {values["observed"]} / {group["runs"]} | {values["median"]:.2f} | {values["minimum"]:.2f}–{values["maximum"]:.2f} |')
    lines += ['', 'A missing mutation row means it was never reached in that cohort. Seeds, first-level pacing and coverage counts are in balance-report.json.']
    comparison = report.get('comparison')
    if comparison is not None:
        lines += ['', f'Matched cases: {comparison["matched"]}; changed observations: {comparison["changed_observations"]}; added: {len(comparison["added"])}; removed: {len(comparison["removed"])}.', '',
                  '| Matched case | Outcome before → after | Changed observations |', '|---|---|---|']
        for change in comparison['changes']:
            identity = json.dumps(change['identity'], sort_keys=True)
            details = '; '.join(f'{k}: {v["before"]} → {v["after"]} (delta {v["delta"]})' for k, v in change['metrics'].items())
            if change['mutations']['before'] != change['mutations']['after']:
                details += '; mutations: ' + json.dumps(change['mutations'], sort_keys=True)
            lines.append(f'| {cell(identity)} | {change["outcome"]["before"]} → {change["outcome"]["after"]} | {cell(details)} |')
        for label in ('added', 'removed'):
            for identity in comparison[label]:
                lines.append(f'- {label}: {cell(json.dumps(identity, sort_keys=True))}')
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', type=Path, required=True, help='Folder containing all four normal-play reports')
    parser.add_argument('--baseline', type=Path, help='Optional earlier artifact folder with the same report schema/engine/step')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        candidate = load_runs(args.candidate)
        report = {'schema': 1, 'status': 'observed', 'sources': candidate['sources'], 'runs': len(candidate['cases']),
                  'outcomes': dict(Counter(c['outcome'] for c in candidate['cases'])),
                  'cohorts': summarize(candidate['cases']), 'limitations': LIMITS}
        if args.baseline:
            baseline = load_runs(args.baseline)
            report.update(baseline_sources=baseline['sources'], comparison=compare(baseline, candidate))
        args.output.mkdir(parents=True, exist_ok=True)
        (args.output / 'balance-report.json').write_text(json.dumps(report, indent=2, allow_nan=False) + '\n')
        (args.output / 'BALANCE_REPORT.md').write_text(markdown(report))
    except (OSError, ValueError, TypeError) as error:
        parser.exit(2, f'BALANCE_REPORT_ERROR: {error}\n')
    print(f'BALANCE_REPORT observed runs={report["runs"]} cohorts={len(report["cohorts"])}')


if __name__ == '__main__':
    main()
