#!/usr/bin/env python3
"""Report the explicit alternate collector experiment without replacing reference bots."""
import argparse
import hashlib
import json
from pathlib import Path
from report_collection_pacing import SEEDS, analyze
from report_route_pacing import analyze_routes

POLICIES = ('value_aware', 'detour')
KIND = 'normal-rules detour experiment'
LIMITS = [
    'Four fixed seeds from the earlier investigation, not held-out validation; identical new Vanguard/no-research conditions and inherited upgrade preferences. Only navigation differs.',
    'Detour commits to a bounded five-metre waypoint after sixteen low-net decisions, yields to inherited danger dashes and cancels obstructed paths.',
    'Existing cautious/value-aware bots and canonical gameplay tests are unchanged; no grants, immunity, teleports or combat RNG writes.',
    'Movement can change adaptive enemies, offers, chosen upgrades and outcomes. This does not isolate one combat or weapon effect.',
    'Route windows cover each policy’s own longest gap and can differ in timing/length; raw reversal counts are not equal-duration comparisons.',
    'Predicted clearance and short commitments are not safety guarantees. Defeats are observations; four seeds do not establish human fun or balance.',
]


def report(source, seeds=SEEDS, profile='arcstorm', kind=KIND):
    collection = analyze(source, POLICIES, kind, seeds, profile)
    routes = analyze_routes(source, POLICIES, kind, seeds, profile)
    detours = []
    for case in source['cases']:
        if case['bot_policy'] != 'detour':
            if 'detours' in case:
                raise ValueError('reference case contains experimental counters')
            continue
        counters = case.get('detours')
        if (not isinstance(counters, dict) or set(counters) != {'started', 'cancelled'}
                or any(type(n) is not int or n < 0 for n in counters.values())
                or counters['cancelled'] > counters['started']):
            raise ValueError('invalid detour accounting')
        detours.append({'seed': case['seed'], **counters})
    return {'schema': 1, 'status': 'observed', 'godot': collection['godot'], 'fixed_step': collection['fixed_step'],
            'cases': collection['cases'], 'pairs': collection['pairs'], 'routes': routes['cases'],
            'detours': sorted(detours, key=lambda c: c['seed']), 'limitations': LIMITS}


def markdown(result):
    lines = ['# Alternate collector experiment', '', *['- '+s for s in LIMITS], '',
             '| Seed | Policy | Outcome | XP collected | Longest gap (s) | Route window (s) | Reversals | Detours started / cancelled |',
             '|---:|---|---|---:|---:|---:|---:|---:|']
    for case in result['cases']:
        route = next(r for r in result['routes'] if r['seed']==case['seed'] and r['policy']==case['policy'])['observed_route_window']
        counters = next((r for r in result['detours'] if r['seed']==case['seed']), None) if case['policy']=='detour' else None
        window = 'unobserved' if route is None else f'{route["active_seconds"]:.2f}'
        reversals = 'unobserved' if route is None else str(route['command_reversals'])
        counts = 'reference' if counters is None else f'{counters["started"]} / {counters["cancelled"]}'
        lines.append(f'| {case["seed"]} | {case["policy"]} | {case["outcome"]} | {case["xp_collected"]} | {case["longest_gap"]["seconds"]:.2f} | {window} | {reversals} | {counts} |')
    lines += ['', '| Seed | Detour minus reference collected XP | Detour minus reference longest gap (s) |', '|---:|---:|---:|']
    for pair in result['pairs']:
        delta = pair['detour_minus_value_aware']
        lines.append(f'| {pair["seed"]} | {delta["xp_collected"]:+d} | {delta["longest_gap_seconds"]:+.2f} |')
    return '\n'.join(lines)+'\n'


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input', required=True, type=Path)
    p.add_argument('--output', required=True, type=Path)
    args = p.parse_args()
    try:
        raw = args.input.read_bytes(); result = report(json.loads(raw))
        result['source_sha256'] = hashlib.sha256(raw).hexdigest()
        args.output.mkdir(parents=True, exist_ok=True)
        (args.output/'detour-analysis.json').write_text(json.dumps(result, indent=2, allow_nan=False)+'\n')
        (args.output/'DETOUR_REPORT.md').write_text(markdown(result))
    except (OSError, ValueError, TypeError, KeyError) as error:
        p.exit(2, f'DETOUR_REPORT_ERROR: {error}\n')
    print(f'DETOUR_REPORT observed cases={len(result["cases"])} pairs={len(result["pairs"])}')


if __name__ == '__main__':
    main()
