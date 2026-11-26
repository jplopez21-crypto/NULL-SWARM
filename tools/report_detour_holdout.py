#!/usr/bin/env python3
"""Audit the frozen collector policy on a separately declared validation matrix."""
import argparse
import hashlib
import json
from pathlib import Path
from report_detour_probe import report as cohort_report

SEEDS = (606, 707)
PROFILES = ('arcstorm', 'halo', 'kinetic')
KIND = 'normal-rules detour holdout'
POLICY_SOURCES = {
    'tests/detour_bot.gd': '8258fe6d9cb81f4e38da6c81a767ecb70fd8b16c85c62caa87889cb8673fe39a',
    'tests/value_aware_bot.gd': 'd0761cead0d6e7012feff3f1ca148a9ccf9b28b8e032e1ca396d9622ff8ec893',
    'tests/bot_driver.gd': '78f227a043c340a49a00f62b6da87038ffdc04e6b2b745fe0e05d31bb2ce96bf',
}
LIMITS = [
    'Two new seeds (606/707), three separately reported upgrade profiles, two policies: twelve runs/six matched pairs.',
    'All three policy source hashes are pinned before observing this matrix; candidate/reference code and parameters are unchanged.',
    'New Vanguard/no research, normal controls and combat. Upgrade preferences match within each profile; different movement changes enemies, offers and later choices.',
    'Validation applies to this frozen candidate. These seeds cannot be called held-out again after tuning against their results.',
    'Defeats and mixed deltas remain observations. Two seeds per profile do not establish population win rates, human enjoyment or safe routes.',
    'Original design cases and canonical matrices stay separate. Route windows cover each run’s own longest gap; they differ in timing/length.',
]


def report(source):
    if (not isinstance(source, dict) or source.get('kind') != KIND or source.get('schema') != 1
            or source.get('failures') != [] or not isinstance(source.get('cases'), list) or len(source['cases']) != 12):
        raise ValueError('incomplete or unsupported holdout matrix')
    if (source.get('policy_sources_sha256') != POLICY_SOURCES
            or source.get('candidate_source_sha256') != POLICY_SOURCES['tests/detour_bot.gd']):
        raise ValueError('policy source freeze mismatch')
    if any(not isinstance(c, dict) or c.get('profile') not in PROFILES for c in source['cases']):
        raise ValueError('unknown holdout profile')
    cohorts = []
    for profile in PROFILES:
        subset = {**source, 'cases': [c for c in source['cases'] if c['profile']==profile]}
        cohort = cohort_report(subset, SEEDS, profile, KIND)
        cohort.pop('limitations')  # Design-seed limits are replaced by this validation scope.
        cohorts.append({'profile': profile, **cohort})
    return {'schema': 1, 'status': 'observed', 'godot': source['godot'], 'fixed_step': source['fixed_step'],
            'policy_sources_sha256': POLICY_SOURCES.copy(), 'runs': 12, 'pairs': 6, 'cohorts': cohorts, 'limitations': LIMITS}


def markdown(result):
    lines = ['# Frozen collector validation', '', *['- '+s for s in LIMITS], '',
             '| Profile | Seed | Reference outcome | Candidate outcome | Reference / candidate gap (s) | Candidate minus reference XP | Candidate minus reference gap (s) |',
             '|---|---:|---|---|---:|---:|---:|']
    for group in result['cohorts']:
        for pair in group['pairs']:
            a,b=[next(c for c in group['cases'] if c['seed']==pair['seed'] and c['policy']==p) for p in ('value_aware','detour')]
            delta = pair['detour_minus_value_aware']
            lines.append(f'| {group["profile"]} | {pair["seed"]} | {a["outcome"]} | {b["outcome"]} | {a["longest_gap"]["seconds"]:.2f} / {b["longest_gap"]["seconds"]:.2f} | {delta["xp_collected"]:+d} | {delta["longest_gap_seconds"]:+.2f} |')
    return '\n'.join(lines)+'\n'


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    args = p.parse_args()
    try:
        raw = args.input.read_bytes(); result = report(json.loads(raw))
        result['source_sha256'] = hashlib.sha256(raw).hexdigest()
        args.output.mkdir(parents=True, exist_ok=True)
        (args.output/'holdout-analysis.json').write_text(json.dumps(result, indent=2, allow_nan=False)+'\n')
        (args.output/'HOLDOUT_REPORT.md').write_text(markdown(result))
    except (OSError, ValueError, TypeError, KeyError) as error:
        p.exit(2, f'HOLDOUT_REPORT_ERROR: {error}\n')
    print('HOLDOUT_REPORT observed cases=12 pairs=6 cohorts=3')


if __name__ == '__main__':
    main()
