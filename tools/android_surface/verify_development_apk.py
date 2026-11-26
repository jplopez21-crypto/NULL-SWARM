#!/usr/bin/env python3
"""Reject unpatched debug exports and native/attribution drift before publication."""
import argparse
import json
from pathlib import Path
import zipfile

from prepare_development import PRISTINE_AAR_SHA256
import rebuild_surface_aar as surface


def verify(apk, receipt_file, abi):
    receipt = json.loads(receipt_file.read_text())
    if (receipt['original_aar_sha256'] != PRISTINE_AAR_SHA256
            or receipt['variant'] != 'latched'
            or receipt['compiled_source_sha256'] != surface.digest(surface.patched_source(surface.SOURCE.read_bytes(), 'latched'))
            or not receipt['nonclass_aar_entries_unchanged']):
        raise ValueError('Unreviewed surface build receipt')
    with zipfile.ZipFile(apk) as archive:
        if archive.testzip() is not None:
            raise ValueError('Corrupted APK')
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate APK entries')
        if not any(b'mSurfaceRecreatePending' in archive.read(n) for n in names if n.endswith('.dex')):
            raise ValueError('Surface repair is absent from exported DEX')
        native = {n: surface.digest(archive.read(n)) for n in names if n.startswith('lib/') and n.endswith('.so')}
        expected = {'lib/' + n.removeprefix('jni/'): digest
                    for n, digest in receipt['native_libraries_sha256'].items()
                    if n.startswith('jni/' + abi + '/')}
        if len(expected) != 2 or native != expected:
            raise ValueError('APK native engine/ABI differs from pinned official AAR')
        license_path = 'assets/resources/licenses/android_surface/'
        if archive.read(license_path + 'Apache-2.0.txt') != (surface.SOURCE.parents[1] / 'Apache-2.0.txt').read_bytes():
            raise ValueError('Missing or changed Apache license')
        if archive.read(license_path + 'NOTICE.txt') != (Path(__file__).parents[2] / 'resources/licenses/android_surface/NOTICE.txt').read_bytes():
            raise ValueError('Missing or changed surface attribution')
    return {'status': 'passed', 'apk_sha256': surface.digest(apk.read_bytes()),
            'apk_bytes': apk.stat().st_size, 'abi': abi, 'patched_dex': True,
            'native_libraries_sha256': native, 'native_engine_unchanged': True,
            'attribution': 'passed', 'scope': 'Development debug export; runtime recovery/physical testing recorded separately.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--receipt', type=Path, required=True)
    parser.add_argument('--abi', choices=['arm64-v8a', 'x86_64'], required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.apk, args.receipt, args.abi)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print('DEVELOPMENT_SURFACE_EXPORT', json.dumps(result))


if __name__ == '__main__':
    main()
