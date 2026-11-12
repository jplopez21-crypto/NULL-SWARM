#!/usr/bin/env python3
"""Audit paired Arcstorm collection traces without changing play or balance."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import statistics

SEEDS = (101, 202, 303, 404)
POLICIES = ('cautious', 'value_aware')
LIMITS = [
    'Normal rules and identical starting conditions/upgrade preferences; existing navigation and dash policies differ.',
    'Movement can change adaptive enemies, offers and subsequent selections. Outcomes do not isolate one navigation component.',
    'Five-second samples describe XP proximity, not safety, exact human visibility or collection opportunities.',
    'Gaps measure time without an applied upgrade choice, including the final tail. Samples may omit interval boundaries.',
    'Time is simulated combat time. Four fixed seeds do not establish human balance, enjoyment or device performance.',
    'No spawn/damage/XP changes, teleportation, stat grants or injected immunity. Defeats are observations.',
]


def numeric(value, name, minimum=0):
    try:
        valid = type(value) in (int, float) and math.isfinite(value) and value >= minimum
    except OverflowError:
        valid = False
    if not valid:
        raise ValueError(f'{name}: invalid finite number')
    return value


def longest_gap(choices, duration):
    if not isinstance(choices, list):
        raise ValueError('upgrade choices must be a list')
    cursor, gaps, last_event = 0., [], 0.
    for choice in choices:
        if not isinstance(choice, dict) or not isinstance(choice.get('id'), str) or not choice['id']:
            raise ValueError('invalid choice')
        at = numeric(choice.get('at'), 'choice time')
        if at < last_event or at > duration + .02:
            raise ValueError('choice time outside run/order')
        last_event = at
        if choice['id'] != 'reroll':
            gaps.append((cursor, at)); cursor = at
    gaps.append((cursor, duration))
    start, end = max(gaps, key=lambda p: p[1] - p[0])
    return {'start': start, 'end': end, 'seconds': round(end - start, 2)}


def describe_case(case, policies=POLICIES):
    if not isinstance(case, dict) or case.get('outcome') not in ('victory', 'defeat', 'time_limit'):
        raise ValueError('invalid case/outcome')
    for key, expected in {'profile': 'arcstorm', 'kit': 'vanguard', 'fixture': 'new player',
                          'pickup_mode': 'local', 'link_policy': 'clean', 'research': {}}.items():
        if case.get(key) != expected:
            raise ValueError(f'unmatched starting condition: {key}')
    if type(case.get('seed')) is not int or case['seed'] not in SEEDS or case.get('bot_policy') not in policies:
        raise ValueError('unexpected seed or policy')
    duration = numeric(case.get('survived_seconds'), 'duration')
    if duration <= 0:
        raise ValueError('empty run')
    gap = longest_gap(case.get('upgrade_choices'), duration)
    if not math.isclose(gap['seconds'], numeric(case.get('longest_upgrade_gap_seconds'), 'reported gap'), abs_tol=.03):
        raise ValueError('reported gap disagrees with choice history')
    trace = case.get('pacing_trace')
    if not isinstance(trace, list) or not trace:
        raise ValueError('missing pacing trace')
    previous_time, previous_collected = -1., -1
    for sample in trace:
        if not isinstance(sample, dict):
            raise ValueError('invalid trace sample')
        at = numeric(sample.get('time'), 'trace time')
        if at < previous_time or at > duration + .02:
            raise ValueError('trace time outside run/order')
        for key in ('dropped', 'collected', 'cold_xp', 'attracted_xp', 'cold_xp_within_16m', 'pending', 'level', 'xp'):
            if type(sample.get(key)) is not int or sample[key] < 0:
                raise ValueError(f'invalid trace counter: {key}')
        if (sample['dropped'] != sample['collected'] + sample['cold_xp'] + sample['attracted_xp']
                or sample['collected'] < previous_collected or sample['cold_xp_within_16m'] > sample['cold_xp'] or sample['level'] < 1):
            raise ValueError('trace violates XP accounting/order')
        distance = numeric(sample.get('nearest_cold_m'), 'nearest cold pickup', -1)
        if (distance < 0 and distance != -1) or (sample['cold_xp'] == 0) != (distance == -1):
            raise ValueError('distance/no-pickup sentinel disagrees with XP')
        if (sample['cold_xp_within_16m'] > 0 and distance > 16.02
                or sample['cold_xp'] > 0 and sample['cold_xp_within_16m'] == 0 and distance < 15.98):
            raise ValueError('nearest distance disagrees with sensor availability')
        previous_time, previous_collected = at, sample['collected']
    window = [s for s in trace if gap['start'] <= s['time'] <= gap['end']]
    distances = [s['nearest_cold_m'] for s in window if s['nearest_cold_m'] >= 0]
    gap.update(samples=len(window), samples_with_nearby_cold_xp=sum(s['cold_xp_within_16m'] > 0 for s in window),
               samples_with_cold_xp_only_beyond_sensor=sum(s['cold_xp'] > 0 and s['cold_xp_within_16m'] == 0 for s in window),
               nearest_cold_median=statistics.median(distances) if distances else None,
               sampled_collected_delta=window[-1]['collected'] - window[0]['collected'] if window else None,
               maximum_pending=max((s['pending'] for s in window), default=None))
    for key in ('level', 'xp_collected', 'uncollected_xp'):
        if type(case.get(key)) is not int or case[key] < (1 if key == 'level' else 0):
            raise ValueError(f'invalid result counter: {key}')
    final = trace[-1]
    if (abs(final['time'] - duration) > .02 or final['collected'] != case['xp_collected']
            or final['level'] != case['level'] or final['cold_xp'] + final['attracted_xp'] != case['uncollected_xp']):
        raise ValueError('final trace disagrees with run totals')
    return {'seed': case['seed'], 'policy': case['bot_policy'], 'outcome': case['outcome'],
            'survived_seconds': duration, 'level': case['level'], 'xp_collected': case['xp_collected'],
            'uncollected_xp': case['uncollected_xp'], 'longest_gap': gap, 'trace_samples': len(trace)}


def analyze(source, policies=POLICIES, kind='normal-rules Arcstorm collection probe'):
    if len(policies) != 2 or len(set(policies)) != 2 or any(not isinstance(p, str) or not p for p in policies):
        raise ValueError('investigation requires two distinct named policies')
    if (not isinstance(source, dict) or type(source.get('schema')) is not int or source['schema'] != 1
            or source.get('kind') != kind or source.get('failures') != []
            or not isinstance(source.get('cases'), list) or len(source['cases']) != len(SEEDS) * len(policies)):
        raise ValueError('incomplete, failed or unsupported investigation')
    if not isinstance(source.get('godot'), str) or not source['godot'] or numeric(source.get('fixed_step'), 'fixed step') <= 0:
        raise ValueError('missing engine/step provenance')
    cases, seen = [], set()
    for case in source['cases']:
        row = describe_case(case, policies); key = (row['seed'], row['policy'])
        if key in seen:
            raise ValueError('duplicate paired case')
        seen.add(key); cases.append(row)
    if seen != {(s, p) for s in SEEDS for p in policies}:
        raise ValueError('incomplete paired coverage')
    cases.sort(key=lambda c: (c['seed'], policies.index(c['policy'])))
    pairs = []
    for seed in SEEDS:
        a, b = [next(c for c in cases if c['seed'] == seed and c['policy'] == policy) for policy in policies]
        pairs.append({'seed': seed, policies[0] + '_outcome': a['outcome'], policies[1] + '_outcome': b['outcome'],
                      policies[1] + '_minus_' + policies[0]: {'survived_seconds': round(b['survived_seconds'] - a['survived_seconds'], 2),
                                                    'xp_collected': b['xp_collected'] - a['xp_collected'],
                                                    'longest_gap_seconds': round(b['longest_gap']['seconds'] - a['longest_gap']['seconds'], 2)}})
    return {'schema': 1, 'status': 'observed', 'godot': source['godot'], 'fixed_step': source['fixed_step'],
            'cases': cases, 'pairs': pairs, 'limitations': LIMITS}


def markdown(report):
    lines = ['# Arcstorm collection investigation', '', *[f'- {s}' for s in LIMITS], '',
             '| Seed | Navigation | Outcome | Survival (s) | Level | Collected / left XP | Longest gap (s) |', '|---:|---|---|---:|---:|---:|---:|']
    for c in report['cases']:
        lines.append(f'| {c["seed"]} | {c["policy"]} | {c["outcome"]} | {c["survived_seconds"]:.2f} | {c["level"]} | {c["xp_collected"]} / {c["uncollected_xp"]} | {c["longest_gap"]["seconds"]:.2f} |')
    lines += ['', '| Seed / navigation | Longest interval (s) | Nearby cold XP samples / total | Cold XP only beyond sensor samples | Nearest cold median (m) | Sampled collected delta |', '|---|---|---:|---:|---:|---:|']
    for c in report['cases']:
        g = c['longest_gap']; nearest = 'unobserved' if g['nearest_cold_median'] is None else f'{g["nearest_cold_median"]:.2f}'
        collected = 'unobserved' if g['sampled_collected_delta'] is None else str(g['sampled_collected_delta'])
        lines.append(f'| {c["seed"]} / {c["policy"]} | {g["start"]:.2f}–{g["end"]:.2f} | {g["samples_with_nearby_cold_xp"]} / {g["samples"]} | {g["samples_with_cold_xp_only_beyond_sensor"]} | {nearest} | {collected} |')
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        raw = args.input.read_bytes(); result = analyze(json.loads(raw))
        result['source_sha256'] = hashlib.sha256(raw).hexdigest()
        args.output.mkdir(parents=True, exist_ok=True)
        (args.output / 'arcstorm-collection-analysis.json').write_text(json.dumps(result, indent=2, allow_nan=False) + '\n')
        (args.output / 'ARCSTORM_COLLECTION_REPORT.md').write_text(markdown(result))
    except (OSError, ValueError, TypeError) as error:
        parser.exit(2, f'COLLECTION_REPORT_ERROR: {error}\n')
    print(f'COLLECTION_REPORT observed cases={len(result["cases"])} pairs={len(result["pairs"])}')


if __name__ == '__main__':
    main()
