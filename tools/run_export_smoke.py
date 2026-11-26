#!/usr/bin/env python3
"""Launch only the assets actually shipped in an APK, without source-tree fallback."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import tempfile
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--output', type=Path, default=Path('builds/qa/export-smoke.json'))
    args = parser.parse_args()
    apk = args.apk.resolve()
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    log = output.with_suffix('.log')
    report = {'apk_sha256': hashlib.sha256(apk.read_bytes()).hexdigest(),
              'scope': 'Headless launch of exact APK assets in an isolated ZIP and user directory; no source files or excluded tests available. Not Android rendering/device acceptance.'}
    with tempfile.TemporaryDirectory(prefix='null-swarm-export-') as isolated:
        sandbox = Path(isolated)
        pack = sandbox / 'exported-assets.zip'
        names = []
        with zipfile.ZipFile(apk) as source, zipfile.ZipFile(pack, 'w', zipfile.ZIP_DEFLATED) as target:
            for name in source.namelist():
                if not name.startswith('assets/') or name.endswith('/'):
                    continue
                relative = name.removeprefix('assets/')
                path = PurePosixPath(relative)
                if path.is_absolute() or '..' in path.parts:
                    raise ValueError('Unsafe exported asset path')
                target.writestr(relative, source.read(name))
                names.append(relative)
        if 'project.binary' not in names:
            raise ValueError('APK contains no exported Godot project')
        report['asset_files'] = len(names)
        env = os.environ.copy()
        for key, folder in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
            env[key] = str(sandbox / folder)
        command = ['godot', '--headless', '--path', str(sandbox), '--main-pack', str(pack),
                   '--max-fps', '60', '--quit-after', '600', '--', '--smoke']
        try:
            with log.open('w') as handle:
                run = subprocess.run(command, cwd=sandbox, env=env, stdout=handle,
                                     stderr=subprocess.STDOUT, timeout=30)
            report['exit_code'] = run.returncode
        except subprocess.TimeoutExpired:
            report['exit_code'] = None
            report['timeout_seconds'] = 30
        text = log.read_text()
        report['scene_smoke_marker'] = 'SCENE_SMOKE_OK' in text
        report['errors'] = [line for line in text.splitlines() if re.search(
            r'SCRIPT ERROR|Parse Error|Failed to load|^ERROR:|ObjectDB instances leaked|resources still in use', line)]
        report['status'] = 'passed' if (report['exit_code'] == 0 and report['scene_smoke_marker']
                                        and not report['errors']) else 'failed'
    output.write_text(json.dumps(report, indent=2) + '\n')
    print('EXPORT_SMOKE_RESULT', report['status'], 'assets=', report['asset_files'], flush=True)
    if report['errors']:
        print('\n'.join(report['errors']), flush=True)
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
