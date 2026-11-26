#!/usr/bin/env python3
"""Export a debug APK; retry only Maven Central HTTP 429 dependency failures."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time


def rate_limited(log):
    return (re.search(r'repo\.(?:maven\.apache\.org|maven\.org)', log) is not None
            and 'Received status code 429' in log
            and not re.search(r'SCRIPT ERROR|Parse Error|Failed to load', log))


def export_debug(apk, report_dir, runner=subprocess.run, sleeper=time.sleep):
    apk, report_dir = Path(apk), Path(report_dir)
    apk.parent.mkdir(parents=True, exist_ok=True)
    report_dir.mkdir(parents=True, exist_ok=True)
    report = {'status': 'failed', 'attempts': [],
              'scope': 'Debug export dependency retries only; not emulator or gameplay acceptance.'}
    code = 1
    for attempt in range(1, 4):
        print(f'ANDROID_DEBUG_EXPORT attempt={attempt}/3', flush=True)
        try:
            result = runner(['godot', '--headless', '--export-debug', 'Android', str(apk)],
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, errors='replace')
            log, code = result.stdout or '', result.returncode
        except OSError as error:
            log, code = str(error), 127
        (report_dir / f'attempt-{attempt}.log').write_text(log)
        print(log, flush=True)
        limited = code != 0 and rate_limited(log)
        output_exists = apk.is_file() and apk.stat().st_size > 0
        report['attempts'].append({'attempt': attempt, 'exit_code': code,
                                   'maven_429': limited, 'nonempty_apk': output_exists})
        if code == 0:
            report['status'] = 'passed' if output_exists else 'failed'
            code = 0 if output_exists else 1
            break
        if not limited or attempt == 3:
            break
        delay = 30 * attempt
        report['attempts'][-1]['retry_delay_seconds'] = delay
        print(f'Maven Central HTTP 429: retrying debug export in {delay}s', flush=True)
        sleeper(delay)
    (report_dir / 'export.json').write_text(json.dumps(report, indent=2) + '\n')
    print('ANDROID_DEBUG_EXPORT_RESULT', report['status'], 'attempts=', len(report['attempts']), flush=True)
    return code if code > 0 else (0 if report['status'] == 'passed' else 1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--report-dir', type=Path, required=True)
    args = parser.parse_args()
    return export_debug(args.output, args.report_dir)


if __name__ == '__main__':
    raise SystemExit(main())
