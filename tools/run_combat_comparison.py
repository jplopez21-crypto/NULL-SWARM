#!/usr/bin/env python3
"""Serial AB/BA comparison of two checkouts using the same sustained fixture."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--baseline', type=Path, required=True)
parser.add_argument('--candidate', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--order', choices=['abba', 'baab'], default='abba')
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
roots = {'baseline': args.baseline.resolve(), 'candidate': args.candidate.resolve()}
sources = {}
for name, root in roots.items():
    if not (root / 'project.godot').exists():
        raise SystemExit(f'Missing Godot project: {root}')
    sources[name] = {
        'commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
        'dirty': bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=root, text=True).strip()),
        'sha256': {path: hashlib.sha256((root / path).read_bytes()).hexdigest()
                   for path in ['systems/spatial_grid.gd', 'resources/enemy_definition.gd', 'systems/combat_world.gd', 'tests/run_benchmark.gd']},
    }

runs = []
fingerprints = None
order = ['baseline', 'candidate', 'candidate', 'baseline'] if args.order == 'abba' else ['candidate', 'baseline', 'baseline', 'candidate']
for index, name in enumerate(order):
    root = roots[name]
    log = args.output / f'{index + 1}-{name}.log'
    report_path = root / 'builds/qa/engineer-stress-report.json'
    report_path.unlink(missing_ok=True)
    with tempfile.TemporaryDirectory(prefix='null-swarm-comparison-') as isolated:
        env = os.environ.copy()
        for key in ['XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME']:
            env[key] = str(Path(isolated) / key)
        print(f'COMPARISON_START {index + 1} {name}', flush=True)
        with log.open('w') as handle:
            completed = subprocess.run(
                ['godot', '--headless', '--script', 'tests/run_benchmark.gd', '--', '--engineer-stress', '--phase-profile'],
                cwd=root, env=env, stdout=handle, stderr=subprocess.STDOUT, timeout=900)
    text = log.read_text()
    if completed.returncode or re.search(r'SCRIPT ERROR|^ERROR:|instances leaked|resources still in use', text, re.M):
        raise SystemExit(f'Failed benchmark: {log}')
    assert 'ENGINEER_STRESS_REPORT scenarios=6 failures=0' in text, f'Missing completion marker: {log}'
    report = json.loads(report_path.read_text())
    assert not report['failures'] and len(report['scenarios']) == 6
    current = {(s['requested_enemies'], s['quality']): s['gameplay_fingerprint'] for s in report['scenarios']}
    if fingerprints is None:
        fingerprints = current
    assert current == fingerprints, f'Gameplay changed in {name} run {index + 1}'
    runs.append({'variant': name, 'report': report})
    (args.output / f'{index + 1}-{name}.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f'COMPARISON_DONE {index + 1} {name} fingerprints=matched', flush=True)

rows = []
for key in fingerprints:
    values = {name: [s for run in runs if run['variant'] == name for s in run['report']['scenarios']
                     if (s['requested_enemies'], s['quality']) == key] for name in roots}
    row = {'enemies': key[0], 'quality': key[1], 'gameplay_fingerprint': fingerprints[key]}
    for name, samples in values.items():
        row[name] = {'mean_ms_runs': [s['mean_simulation_step_ms'] for s in samples],
                     'p95_ms_runs': [s['p95_simulation_step_ms'] for s in samples],
                     'median_mean_ms': statistics.median(s['mean_simulation_step_ms'] for s in samples),
                     'median_p95_ms': statistics.median(s['p95_simulation_step_ms'] for s in samples),
                     'mean_phase_ms': {phase: statistics.median(s['phase_profile']['mean_ms'][phase] for s in samples)
                                       for phase in samples[0]['phase_profile']['mean_ms']}}
    row['whole_fixture_mean_speedup'] = row['baseline']['median_mean_ms'] / row['candidate']['median_mean_ms']
    rows.append(row)
result = {'created_utc': datetime.now(timezone.utc).isoformat(), 'order': [r['variant'] for r in runs],
          'sources': sources, 'cases': rows, 'gameplay_parity': True,
          'limits': ['Two serial samples/version in AB/BA order on a shared local host; not a confidence interval.',
                     'Synthetic invulnerable/sustained load; whole-fixture timing includes player, pickups and refill.',
                     'Phase timing covers CombatWorld only and adds instrumentation overhead.',
                     'No rendering, Android/phone FPS or thermal claim; no hardware-dependent pass threshold.']}
(args.output / 'comparison.json').write_text(json.dumps(result, indent=2) + '\n')
print('COMPARISON_RESULT passed', flush=True)
