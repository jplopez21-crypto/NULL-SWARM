#!/usr/bin/env python3
"""Audit actual travel and dash use during the paired Arcstorm upgrade gaps."""
import argparse
import hashlib
import json
import math
from pathlib import Path
from report_collection_pacing import analyze, numeric

COUNTERS = ('steps', 'command_reversals', 'dash_requests', 'dash_activations')
MEASURES = ('travel_m', 'active_seconds', 'dash_ready_seconds')
LIMITATIONS = [
    'Read-only per-physics-step observations; existing navigation, upgrades, RNG and combat rules are unchanged.',
    'Opposite command means a direction change over 120 degrees. Requests and successful cooldown transitions are separate.',
    'Longest-gap windows include only complete intervals between five-second samples inside the gap; boundaries are omitted.',
    'Low net intervals last 4–6 seconds, travel at least 5m and finish under 0.75m from their start. This can include intentional circling.',
    'Sampled footprint omits excursions between snapshots. Readiness is time available before dash selection, including same-tick cooldown expiry.',
    'Four fixed seeds describe these bots, not safe routes, human skill, balance causality or physical-device performance.',
]


def point(sample):
    p = sample.get('position')
    if not isinstance(p, list) or len(p) != 2:
        raise ValueError('missing planar position')
    return [numeric(x, 'position', -100) for x in p]


def analyze_routes(source):
    base = analyze(source)  # Reuse full paired-condition, XP, outcome and gap validation.
    if type(source.get('route_schema')) is not int or source['route_schema'] != 1:
        raise ValueError('missing route schema; older proximity traces cannot measure travel')
    cases = []
    for case in source['cases']:
        route, pacing = case.get('route_trace'), case['pacing_trace']
        if not isinstance(route, list) or len(route) != len(pacing):
            raise ValueError('route/pacing coverage mismatch')
        previous, previous_location = None, None
        for sample, location in zip(route, pacing):
            if not isinstance(sample, dict) or sample.get('time') != location['time']:
                raise ValueError('route/pacing time mismatch')
            point(location)
            for key in COUNTERS:
                if type(sample.get(key)) is not int or sample[key] < 0:
                    raise ValueError(f'invalid route counter: {key}')
            for key in MEASURES:
                numeric(sample.get(key), key)
            if (sample['dash_activations'] > sample['dash_requests'] or sample['dash_requests'] > sample['steps']
                    or sample['command_reversals'] > sample['steps'] or sample['dash_ready_seconds'] > sample['active_seconds'] + .002
                    or abs(sample['active_seconds'] - sample['steps'] * source['fixed_step']) > .002
                    or sample['active_seconds'] > sample['time'] + .02
                    or sample['travel_m'] > 27 * sample['active_seconds'] + .03):
                raise ValueError('inconsistent route accounting')
            if previous:
                if any(sample[k] < previous[k] for k in (*COUNTERS, *MEASURES)):
                    raise ValueError('route totals decrease')
                delta_time = sample['active_seconds'] - previous['active_seconds']
                travel = sample['travel_m'] - previous['travel_m']
                if travel > 27 * delta_time + .03:
                    raise ValueError('travel exceeds actual dash speed budget')
                if (math.dist(point(previous_location), point(location)) > travel + .03
                        or sample['dash_activations'] - previous['dash_activations'] > sample['dash_requests'] - previous['dash_requests']
                        or sample['dash_requests'] - previous['dash_requests'] > sample['steps'] - previous['steps']
                        or sample['command_reversals'] - previous['command_reversals'] > sample['steps'] - previous['steps']
                        or sample['dash_ready_seconds'] - previous['dash_ready_seconds'] > delta_time + .002
                        or delta_time > sample['time'] - previous['time'] + .03):
                    raise ValueError('inconsistent route interval')
            previous, previous_location = sample, location
        original = next(c for c in base['cases'] if c['seed'] == case['seed'] and c['policy'] == case['bot_policy'])
        gap = original['longest_gap']
        indexes = [i for i, s in enumerate(pacing) if gap['start'] <= s['time'] <= gap['end']]
        summary = None
        if len(indexes) >= 2:
            first, last = indexes[0], indexes[-1]
            a, b = route[first], route[last]
            summary = {key: round(b[key] - a[key], 3) for key in (*COUNTERS, *MEASURES)}
            summary.update(start=a['time'], end=b['time'], net_m=round(math.dist(point(pacing[first]), point(pacing[last])), 3))
            positions = [point(pacing[i]) for i in indexes]
            summary['sampled_footprint_diagonal_m'] = round(math.hypot(max(p[0] for p in positions)-min(p[0] for p in positions), max(p[1] for p in positions)-min(p[1] for p in positions)), 3)
            low_net = []
            for i, j in zip(indexes, indexes[1:]):
                distance = route[j]['travel_m'] - route[i]['travel_m']
                net = math.dist(point(pacing[i]), point(pacing[j]))
                if 4 <= route[j]['time'] - route[i]['time'] <= 6 and distance >= 5 and net < .75:
                    low_net.append({'start': route[i]['time'], 'end': route[j]['time'], 'travel_m': round(distance, 3), 'net_m': round(net, 3)})
            summary['low_net_intervals'] = low_net
            if summary['net_m'] > summary['travel_m'] + .03:
                raise ValueError('net displacement exceeds recorded travel')
        cases.append({'seed': case['seed'], 'policy': case['bot_policy'], 'outcome': case['outcome'],
                      'longest_gap_seconds': gap['seconds'], 'observed_route_window': summary,
                      'total_dash_requests': route[-1]['dash_requests'], 'total_dash_activations': route[-1]['dash_activations']})
    cases.sort(key=lambda c: (c['seed'], c['policy']))
    return {'schema': 1, 'status': 'observed', 'godot': base['godot'], 'fixed_step': base['fixed_step'], 'cases': cases, 'limitations': LIMITATIONS}


def markdown(report):
    lines = ['# Arcstorm route observations', '', *['- ' + s for s in LIMITATIONS], '',
             '| Seed / policy | Gap (s) | Observed (s) | Travel / net (m) | Reversals | Dash requests / activated | Ready (s) | Low net intervals |',
             '|---|---:|---:|---:|---:|---:|---:|---:|']
    for c in report['cases']:
        w = c['observed_route_window']
        if w is None:
            lines.append(f'| {c["seed"]} / {c["policy"]} | {c["longest_gap_seconds"]:.2f} | unobserved | unobserved | unobserved | unobserved | unobserved | unobserved |')
        else:
            lines.append(f'| {c["seed"]} / {c["policy"]} | {c["longest_gap_seconds"]:.2f} | {w["active_seconds"]:.2f} | {w["travel_m"]:.2f} / {w["net_m"]:.2f} | {w["command_reversals"]} | {w["dash_requests"]} / {w["dash_activations"]} | {w["dash_ready_seconds"]:.2f} | {len(w["low_net_intervals"])} |')
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        raw = args.input.read_bytes(); report = analyze_routes(json.loads(raw))
        report['source_sha256'] = hashlib.sha256(raw).hexdigest()
        args.output.mkdir(parents=True, exist_ok=True)
        (args.output/'route-analysis.json').write_text(json.dumps(report, indent=2, allow_nan=False)+'\n')
        (args.output/'ROUTE_REPORT.md').write_text(markdown(report))
    except (OSError, ValueError, TypeError, KeyError) as error:
        parser.exit(2, f'ROUTE_REPORT_ERROR: {error}\n')
    print(f'ROUTE_REPORT observed cases={len(report["cases"])}')


if __name__ == '__main__':
    main()
