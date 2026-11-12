#!/usr/bin/env python3
"""Prepare the pinned Java surface repair for development/preview debug exports."""
import argparse
from configparser import ConfigParser
import json
from pathlib import Path
import subprocess
import tempfile

import rebuild_surface_aar as surface

# Official 4.6.3 source-template debug AAR, verified on both diagnostic workers.
PRISTINE_AAR_SHA256 = 'a0d9c91163a2749531009099279525abc26f988d2f6b66f2840c60fa4f41e9c1'
AAR = Path('android/build/libs/debug/godot-lib.template_debug.aar')


def install_template(project, godot):
    """Bootstrap with the official non-Gradle exporter; restore exact preset bytes."""
    preset = project / 'export_presets.cfg'
    original = preset.read_bytes()
    config = ConfigParser(interpolation=None)
    config.optionxform = str
    config.read_string(original.decode())
    config['preset.0.options']['gradle_build/use_gradle_build'] = 'false'
    try:
        with preset.open('w') as target:
            config.write(target)
        with tempfile.TemporaryDirectory(prefix='null-swarm-template-') as tmp:
            subprocess.run([godot, '--headless', '--path', str(project),
                            '--install-android-build-template', '--export-debug', 'Android',
                            str(Path(tmp) / 'bootstrap.apk')], check=True, timeout=180)
    finally:
        preset.write_bytes(original)


def prepare(project, android_jar, output, godot='godot'):
    project, android_jar, output = project.resolve(), android_jar.resolve(), output.resolve()
    if not android_jar.is_file():
        raise ValueError('Missing Android SDK android.jar')
    version = subprocess.check_output([godot, '--version'], text=True).strip()
    if not version.startswith('4.6.3.stable.'):
        raise ValueError('Surface integration requires the reviewed Godot 4.6.3 stable version')
    aar = project / AAR
    if not aar.is_file():
        install_template(project, godot)
    current = surface.digest(aar.read_bytes())
    receipt_file = output / 'surface-build.json'
    expected_source = surface.digest(surface.patched_source(surface.SOURCE.read_bytes(), 'latched'))
    if current != PRISTINE_AAR_SHA256:
        # Idempotent local/editor preparation requires a matching receipt, not just a marker.
        receipt = json.loads(receipt_file.read_text()) if receipt_file.is_file() else {}
        if not (receipt.get('original_aar_sha256') == PRISTINE_AAR_SHA256
                and receipt.get('modified_aar_sha256') == current
                and receipt.get('compiled_source_sha256') == expected_source
                and receipt.get('upstream_git_blob') == surface.UPSTREAM_BLOB
                and receipt.get('variant') == 'latched'):
            raise ValueError('Unrecognized Android AAR; reinstall clean 4.6.3 source templates and prepare again')
        return receipt
    return surface.rebuild(aar, android_jar, output, 'latched')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path('.'))
    parser.add_argument('--android-jar', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--godot', default='godot')
    args = parser.parse_args()
    result = prepare(args.project, args.android_jar, args.output, args.godot)
    print('DEVELOPMENT_SURFACE_READY', result['modified_aar_sha256'])


if __name__ == '__main__':
    main()
