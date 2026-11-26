#!/usr/bin/env python3
"""Prepare a pinned preview identity. Never generate or substitute a signing key."""
import base64
from configparser import ConfigParser
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

REQUIRED = ('ANDROID_DEV_KEYSTORE_BASE64', 'ANDROID_DEV_STORE_PASSWORD',
            'ANDROID_DEV_KEY_ALIAS', 'ANDROID_DEV_CERT_SHA256')
PACKAGE = 'com.nullswarm.game.preview'


def fingerprint(value):
    value = value.replace(':', '').strip().lower()
    if not re.fullmatch('[0-9a-f]{64}', value):
        raise ValueError('Expected a SHA-256 certificate fingerprint')
    return value


def prepare(root, temporary, env):
    missing = [key for key in REQUIRED if not env.get(key)]
    if missing:
        raise ValueError('Missing signing configuration: ' + ', '.join(missing))
    expected = fingerprint(env['ANDROID_DEV_CERT_SHA256'])
    run_number = int(env['GITHUB_RUN_NUMBER'])
    if not 1 <= run_number <= 2000000000:
        raise ValueError('Invalid preview build sequence')
    raw = base64.b64decode(env['ANDROID_DEV_KEYSTORE_BASE64'], validate=True)
    if not 1 <= len(raw) <= 65536:
        raise ValueError('Invalid keystore size')
    temporary.mkdir(parents=True, exist_ok=True)
    key = temporary / 'preview-signing.p12'
    # Exclusive creation avoids overwriting any unrelated credentials.
    with key.open('xb') as handle:
        os.chmod(key, 0o600)
        handle.write(raw)
    try:
        result = subprocess.run(['keytool', '-exportcert', '-keystore', str(key),
                                 '-alias', env['ANDROID_DEV_KEY_ALIAS'],
                                 '-storepass:env', 'ANDROID_DEV_STORE_PASSWORD'],
                                env=env, capture_output=True, timeout=30, check=False)
        if result.returncode or hashlib.sha256(result.stdout).hexdigest() != expected:
            raise ValueError('Keystore credentials or pinned certificate do not match')
        config = ConfigParser(interpolation=None)
        config.optionxform = str
        config.read(root / 'export_presets.cfg')
        options = config['preset.0.options']
        options['package/unique_name'] = json.dumps(PACKAGE)
        options['package/name'] = json.dumps('NULL SWARM Preview')
        options['version/code'] = str(100000 + run_number)
        options['version/name'] = json.dumps('0.5-preview.' + str(run_number))
        with (root / 'export_presets.cfg').open('w') as handle:
            config.write(handle)
        settings = temporary / 'godot/editor_settings-4.6.tres'
        settings.parent.mkdir(parents=True, exist_ok=True)
        values = {'android_sdk_path': env['ANDROID_HOME'], 'java_sdk_path': env['JAVA_HOME'],
                  'debug_keystore': str(key), 'debug_keystore_user': env['ANDROID_DEV_KEY_ALIAS'],
                  'debug_keystore_pass': env['ANDROID_DEV_STORE_PASSWORD']}
        with settings.open('w') as handle:
            os.chmod(settings, 0o600)
            handle.write('[gd_resource type="EditorSettings" format=3]\n[resource]\n')
            for name, value in values.items():
                handle.write('export/android/' + name + ' = ' + json.dumps(value) + '\n')
        return {'package': PACKAGE, 'version_code': 100000 + run_number,
                'certificate_sha256': expected, 'source_sha': env.get('GITHUB_SHA', '')}
    except BaseException:
        key.unlink(missing_ok=True)
        raise


def verify_apk(apksigner, apk, expected):
    result = subprocess.run([str(apksigner), 'verify', '--print-certs', str(apk)],
                            capture_output=True, text=True, timeout=30, check=False)
    certificates = re.findall(r'^Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]+)$',
                              result.stdout, re.MULTILINE)
    if result.returncode or certificates != [fingerprint(expected)]:
        raise ValueError('APK signature verification or pinned signer check failed')


if __name__ == '__main__':
    import sys
    try:
        if len(sys.argv) == 3 and sys.argv[1] == '--verify-apk':
            verify_apk(Path(os.environ['ANDROID_HOME']) / 'build-tools/35.0.1/apksigner',
                       sys.argv[2], os.environ['ANDROID_DEV_CERT_SHA256'])
        else:
            metadata = prepare(Path.cwd(), Path(os.environ['XDG_CONFIG_HOME']), os.environ.copy())
            output = Path('builds/android')
            output.mkdir(parents=True, exist_ok=True)
            (output / 'SIGNING_IDENTITY.json').write_text(json.dumps(metadata, indent=2) + '\n')
    except (ValueError, KeyError, OSError, subprocess.SubprocessError):
        # Never echo keystore bytes, passwords, or tool diagnostics containing credentials.
        print('Preview signing unavailable: configure all four environment secrets with the original pinned key.', file=sys.stderr)
        sys.exit(1)
