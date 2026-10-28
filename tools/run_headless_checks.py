#!/usr/bin/env python3
"""Run isolated Godot checks and reject script failures even if Godot exits zero."""
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
out = root / 'builds/qa'
out.mkdir(parents=True, exist_ok=True)
suites = [
    ('gui-input', ['--script', 'tests/run_gui_input_tests.gd'], r'GUI_INPUT_RESULT checks=(\d+) failures=0'),
    ('audio', ['--script', 'tests/run_audio_tests.gd'], r'AUDIO_RESULT checks=(\d+) failures=0'),
    ('android-probe', ['--script', 'tests/run_probe_tests.gd'], r'PROBE_RESULT checks=(\d+) failures=0'),
    ('resources', ['--script', 'tests/validate_resources.gd'], r'RESOURCE_RESULT checks=(\d+) failures=0'),
    ('input', ['--script', 'tests/run_input_tests.gd'], r'INPUT_RESULT checks=(\d+) failures=0'),
    ('systems', ['--script', 'tests/run_tests.gd'], r'TEST_RESULT checks=(\d+) failures=0'),
    ('corruption', ['--script', 'tests/run_corruption_tests.gd'], r'CORRUPTION_RESULT checks=(\d+) failures=0'),
    ('ui-headless', ['--script', 'tests/run_ui_tests.gd'], r'UI_RESULT checks=(\d+) layouts=100 failures=0'),
    ('scene-smoke', ['--', '--smoke'], r'SCENE_SMOKE_OK'),
]
results = []
for name, arguments, expected in suites:
    log = out / f'{name}.log'
    with tempfile.TemporaryDirectory(prefix='null-swarm-check-') as isolated:
        env = os.environ.copy()
        for key, suffix in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
            env[key] = str(Path(isolated) / suffix)
        try:
            with log.open('w') as handle:
                run = subprocess.run(['godot', '--headless', '--path', str(root), *arguments], env=env,
                                     stdout=handle, stderr=subprocess.STDOUT, timeout=300, cwd=root)
            text = log.read_text()
            match = re.search(expected, text)
            errors = [line for line in text.splitlines() if re.search(r'SCRIPT ERROR|Parse Error|Failed to load|^ERROR:|ObjectDB instances leaked|resources still in use', line)]
            passed = run.returncode == 0 and match is not None and not errors
            results.append({'suite': name, 'status': 'passed' if passed else 'failed', 'exit_code': run.returncode,
                            'checks': int(match.group(1)) if match and match.lastindex else None, 'errors': errors})
        except subprocess.TimeoutExpired:
            results.append({'suite': name, 'status': 'failed', 'error': '300-second timeout'})
    print('HEADLESS_CASE', name, results[-1]['status'], flush=True)
report = {'suites': results, 'status': 'passed' if all(r['status'] == 'passed' for r in results) else 'failed'}
(out / 'headless-results.json').write_text(json.dumps(report, indent=2))
(out / 'HEADLESS_RESULTS.md').write_text('# Headless checks\n\n' + '\n'.join(f"- {r['suite']}: **{r['status']}**" for r in results) + '\n')
print('HEADLESS_RESULT', report['status'])
raise SystemExit(0 if report['status'] == 'passed' else 1)
