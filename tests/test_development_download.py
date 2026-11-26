"""Synthetic archives/API records only; no real APK, signature or device acceptance."""
import copy
import io
import json
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).parents[1] / 'tools'))
import publish_development_download as delivery


def zipped(entries):
    data = io.BytesIO()
    with zipfile.ZipFile(data, 'w') as z:
        for name, body in entries.items():
            z.writestr(name, body)
    return data.getvalue()


class DevelopmentDownloadTests(unittest.TestCase):
    def setUp(self):
        self.m = json.loads((Path(__file__).parents[1] / '.github/development-download.json').read_text())
        self.runs = [{'name': name, 'id': identity, 'head_sha': self.m['source_commit'],
                      'head_branch': self.m['source_branch'], 'status': 'completed', 'conclusion': 'success'}
                     for name, identity in self.m['runs'].items()]
        self.artifact = {'id': self.m['artifact_id'], 'name': 'null-swarm-development-apk', 'expired': False,
                         'size_in_bytes': self.m['artifact_bytes'], 'digest': 'sha256:' + self.m['artifact_sha256'],
                         'workflow_run': {'id': self.m['runs']['Validate and build Android'], 'head_sha': self.m['source_commit']}}
        self.release = {'tag_name': self.m['release_tag'], 'target_commitish': self.m['source_commit'],
                        'prerelease': True, 'draft': True, 'assets': [{'name': self.m['asset_name'],
                        'state': 'uploaded', 'size': self.m['apk_bytes'], 'digest': 'sha256:' + self.m['apk_sha256'],
                        'browser_download_url': 'https://github.com/' + self.m['repository'] + '/releases/download/' + self.m['release_tag'] + '/' + self.m['asset_name']}]}

    def test_valid_pinned_policy_and_records(self):
        delivery.validate_manifest(self.m)
        delivery.validate_runs(self.m, self.runs)
        delivery.validate_artifact(self.m, self.artifact)
        self.assertEqual(delivery.verified_asset(self.m, self.release)['name'], self.m['asset_name'])

    def test_manifest_cannot_target_main_or_other_repository(self):
        for key, value in [('repository', 'elsewhere/game'), ('source_branch', 'main'),
                           ('source_commit', 'main'), ('release_tag', 'v1.0'), ('asset_name', '../game.apk'),
                           ('apk_sha256', 'invalid'), ('runs', {})]:
            candidate = copy.deepcopy(self.m); candidate[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                delivery.validate_manifest(candidate)

    def test_all_five_gates_must_match_successful_source(self):
        for key, value in [('head_sha', '0' * 40), ('head_branch', 'main'), ('status', 'in_progress'),
                           ('conclusion', 'failure'), ('id', 1), ('name', 'unrelated test')]:
            candidate = copy.deepcopy(self.runs); candidate[0][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                delivery.validate_runs(self.m, candidate)
        with self.assertRaises(ValueError):
            delivery.validate_runs(self.m, self.runs[:-1])

    def test_artifact_identity_and_provenance_are_required(self):
        for key, value in [('id', 1), ('name', 'other'), ('expired', True), ('size_in_bytes', 1),
                           ('digest', 'sha256:' + '0' * 64), ('workflow_run', {}), ('expired', None)]:
            candidate = copy.deepcopy(self.artifact); candidate[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                delivery.validate_artifact(self.m, candidate)

    def archive_fixture(self, extra=None):
        entries = {'AndroidManifest.xml': b'synthetic', 'classes.dex': b'synthetic',
                   'assets/project.binary': b'synthetic', 'lib/arm64-v8a/libgodot_android.so': b'synthetic'}
        entries.update(extra or {})
        apk = zipped(entries)
        archive = zipped({self.m['apk_entry']: apk})
        m = copy.deepcopy(self.m)
        m.update(artifact_bytes=len(archive), artifact_sha256=hashlib.sha256(archive).hexdigest(),
                 apk_bytes=len(apk), apk_sha256=hashlib.sha256(apk).hexdigest())
        return m, archive, apk

    def test_extracts_exact_payload_without_rebuilding(self):
        m, archive, apk = self.archive_fixture()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); source = root / 'input.zip'; source.write_bytes(archive)
            target = delivery.extract_verified_apk(m, source, root)
            self.assertEqual(target.read_bytes(), apk)

    def test_tampering_never_writes_the_apk(self):
        m, archive, _ = self.archive_fixture()
        for changed in [archive + b'x', b'not a zip']:
            with tempfile.TemporaryDirectory() as directory:
                root = Path(directory); source = root / 'input.zip'; source.write_bytes(changed)
                with self.assertRaises(ValueError):
                    delivery.extract_verified_apk(m, source, root)
                self.assertFalse((root / m['asset_name']).exists())
        m['apk_sha256'] = '0' * 64
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); source = root / 'input.zip'; source.write_bytes(archive)
            with self.assertRaises(ValueError):
                delivery.extract_verified_apk(m, source, root)

    def test_excluded_source_assets_are_rejected(self):
        m, archive, _ = self.archive_fixture({'assets/tests/private.gd': b'synthetic'})
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); source = root / 'input.zip'; source.write_bytes(archive)
            with self.assertRaises(ValueError):
                delivery.extract_verified_apk(m, source, root)
            self.assertFalse((root / m['asset_name']).exists())

    def test_release_and_uploaded_asset_must_match(self):
        for key, value in [('tag_name', 'v1.0'), ('target_commitish', 'main'), ('prerelease', False), ('assets', [])]:
            candidate = copy.deepcopy(self.release); candidate[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                delivery.verified_asset(self.m, candidate)
        for key, value in [('size', 1), ('state', 'new'), ('digest', None), ('browser_download_url', 'https://other.example/game.apk')]:
            candidate = copy.deepcopy(self.release); candidate['assets'][0][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                delivery.verified_asset(self.m, candidate)

    def test_failed_gate_cannot_reach_publication_or_download(self):
        wrong = copy.deepcopy(self.runs); wrong[0]['conclusion'] = 'failure'
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(delivery.subprocess, 'check_output', side_effect=[json.dumps(r) for r in wrong]), patch.object(delivery.subprocess, 'run') as run:
                with self.assertRaises(ValueError):
                    delivery.publish(self.m, Path(directory))
                run.assert_not_called()
