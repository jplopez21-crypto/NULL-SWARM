#!/usr/bin/env python3
"""Redistribute a pinned, already tested debug APK; never sign or rebuild it."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile

GATES = {'Validate and build Android', 'Repeatable gameplay QA', 'Android Mobile renderer smoke',
         'Android emulator runtime', 'Android Surface recovery investigation'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate_manifest(m):
    require(m.get('repository') == 'jplopez21-crypto/NULL-SWARM', 'Unexpected repository')
    require(re.fullmatch(r'[0-9a-f]{40}', m.get('source_commit', '')), 'Invalid source commit')
    require(m.get('source_branch') == 'development/android-validation', 'Unexpected source branch')
    require(set(m.get('runs', {})) == GATES and len(set(m['runs'].values())) == 5, 'Five distinct CI gates required')
    require(m.get('release_tag') == 'development-' + m['source_commit'][:7], 'Only the source-specific development tag is allowed')
    require(m.get('asset_name') == 'NULL-SWARM-debug.apk', 'Unexpected asset name')
    require(m.get('apk_entry') == 'android/null-swarm-development-debug.apk', 'Unexpected APK entry')
    for key in ['artifact_sha256', 'apk_sha256']:
        require(re.fullmatch(r'[0-9a-f]{64}', m.get(key, '')), 'Invalid checksum')


def validate_runs(m, runs):
    require(len(runs) == 5, 'Incomplete CI results')
    require({r.get('name') for r in runs} == GATES, 'Wrong CI gates')
    for run in runs:
        require(run.get('id') == m['runs'].get(run.get('name')), 'Wrong CI run')
        require(run.get('head_sha') == m['source_commit'] and run.get('head_branch') == m['source_branch'], 'CI source mismatch')
        require(run.get('status') == 'completed' and run.get('conclusion') == 'success', 'CI is not successful')


def validate_artifact(m, artifact):
    require(artifact.get('id') == m['artifact_id'] and artifact.get('name') == 'null-swarm-development-apk', 'Wrong artifact')
    require(artifact.get('expired') is False, 'Artifact unavailable')
    require(artifact.get('size_in_bytes') == m['artifact_bytes'] and artifact.get('digest') == 'sha256:' + m['artifact_sha256'], 'Artifact integrity metadata mismatch')
    run = artifact.get('workflow_run', {})
    require(run.get('id') == m['runs']['Validate and build Android'] and run.get('head_sha') == m['source_commit'], 'Artifact source mismatch')


def extract_verified_apk(m, archive, output):
    require(archive.stat().st_size == m['artifact_bytes'] and hashlib.sha256(archive.read_bytes()).hexdigest() == m['artifact_sha256'], 'Downloaded archive mismatch')
    with zipfile.ZipFile(archive) as z:
        require(z.testzip() is None and len(z.namelist()) == len(set(z.namelist())), 'Invalid archive')
        require(m['apk_entry'] in z.namelist(), 'APK entry missing')
        body = z.read(m['apk_entry'])
    require(len(body) == m['apk_bytes'] and hashlib.sha256(body).hexdigest() == m['apk_sha256'], 'APK mismatch')
    import io
    with zipfile.ZipFile(io.BytesIO(body)) as z:
        require(z.testzip() is None, 'Corrupted APK')
        require({'AndroidManifest.xml', 'classes.dex', 'assets/project.binary', 'lib/arm64-v8a/libgodot_android.so'}.issubset(z.namelist()), 'Wrong APK contents or ABI')
        require(not any(n.startswith(('assets/tests/', 'assets/tools/', 'assets/docs/')) for n in z.namelist()), 'Development files leaked into APK')
    apk = output / m['asset_name']
    apk.write_bytes(body)
    return apk


def validate_release(m, release):
    require(release.get('tag_name') == m['release_tag'] and release.get('target_commitish') == m['source_commit'], 'Release source mismatch')
    require(release.get('prerelease') is True, 'Only a development prerelease is allowed')


def verified_asset(m, release):
    validate_release(m, release)
    matches = [a for a in release.get('assets', []) if a.get('name') == m['asset_name']]
    require(len(matches) == 1, 'Missing or ambiguous release asset')
    asset = matches[0]
    require(asset.get('state') == 'uploaded' and asset.get('size') == m['apk_bytes'] and asset.get('digest') == 'sha256:' + m['apk_sha256'], 'Uploaded asset mismatch')
    require(asset.get('browser_download_url', '').startswith('https://github.com/' + m['repository'] + '/releases/download/' + m['release_tag'] + '/'), 'Unexpected download URL')
    return asset


def publish(m, output):
    repo = m['repository']
    def api(path):
        return json.loads(subprocess.check_output(['gh', 'api', 'repos/' + repo + '/' + path], text=True))
    runs = [api('actions/runs/' + str(i)) for i in m['runs'].values()]
    validate_runs(m, runs)
    validate_artifact(m, api('actions/artifacts/' + str(m['artifact_id'])))
    archive = output / 'artifact.zip'
    with archive.open('wb') as handle:
        subprocess.run(['gh', 'api', 'repos/' + repo + '/actions/artifacts/' + str(m['artifact_id']) + '/zip'], stdout=handle, check=True)
    apk = extract_verified_apk(m, archive, output)
    receipt = {**m, 'status': 'payload_verified', 'gates': [{'name': r['name'], 'id': r['id'], 'url': r['html_url']} for r in runs],
               'scope': 'Exact CI-signed debug APK; no rebuild, re-signing or new physical-device acceptance.'}
    (output / 'VERIFICATION.json').write_text(json.dumps(receipt, indent=2) + '\n')
    (output / 'SHA256SUMS').write_text(m['apk_sha256'] + '  ' + apk.name + '\n')
    notes = output / 'notes.md'
    notes.write_text('Verified Android development build from ' + m['source_commit'] + '.\n\n'
                     'Download NULL-SWARM-debug.apk directly below. No Actions ZIP or GitHub sign-in is required.\n\n'
                     'All five listed CI gates passed. This is a development prerelease, not a Google Play release. '
                     'Physical-phone performance remains unverified. Back up progression before replacing rotating-debug-signed installs.\n\n'
                     'SHA256: ' + m['apk_sha256'] + '\n')
    tag = m['release_tag']
    existing = subprocess.run(['gh', 'api', 'repos/' + repo + '/releases/tags/' + tag], text=True, capture_output=True)
    if existing.returncode == 0:
        release = json.loads(existing.stdout)
        validate_release(m, release)
        if not release['draft']:
            return verified_asset(m, release)
    else:
        require('404' in existing.stderr, 'Cannot verify existing release state')
        subprocess.run(['gh', 'release', 'create', tag, '--repo', repo, '--target', m['source_commit'], '--draft', '--prerelease',
                        '--title', 'NULL//SWARM development APK - useful rerolls', '--notes-file', str(notes)], check=True)
    subprocess.run(['gh', 'release', 'upload', tag, str(apk), str(output / 'SHA256SUMS'), str(output / 'VERIFICATION.json'), '--repo', repo, '--clobber'], check=True)
    verified_asset(m, api('releases/tags/' + tag))
    subprocess.run(['gh', 'release', 'edit', tag, '--repo', repo, '--draft=false', '--prerelease', '--latest=false'], check=True)
    release = api('releases/tags/' + tag)
    require(release.get('draft') is False, 'Release is still a draft')
    return verified_asset(m, release)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--publish', action='store_true', required=True)
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text())
    validate_manifest(manifest)
    require(os.environ.get('GH_TOKEN'), 'GitHub token is required')
    args.output.mkdir(parents=True, exist_ok=True)
    asset = publish(manifest, args.output)
    (args.output / 'publish-result.json').write_text(json.dumps(asset, indent=2) + '\n')
    print('DEVELOPMENT_APK_DOWNLOAD', asset['browser_download_url'], flush=True)


if __name__ == '__main__':
    main()
