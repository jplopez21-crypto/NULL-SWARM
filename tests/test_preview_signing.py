import base64
from configparser import ConfigParser
import hashlib
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('signing', Path(__file__).parents[1] / 'tools/prepare_preview_signing.py')
signing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signing)


class SigningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixture = tempfile.TemporaryDirectory()
        key = Path(cls.fixture.name) / 'test.p12'
        cls.env = os.environ.copy()
        cls.env.update(ANDROID_DEV_STORE_PASSWORD='temporary-test-password', ANDROID_DEV_KEY_ALIAS='preview',
                       GITHUB_RUN_NUMBER='1', ANDROID_HOME='/sdk', JAVA_HOME='/jdk')
        subprocess.run(['keytool', '-genkeypair', '-storetype', 'PKCS12', '-keystore', str(key),
                        '-storepass:env', 'ANDROID_DEV_STORE_PASSWORD', '-alias', 'preview',
                        '-keyalg', 'RSA', '-keysize', '2048', '-validity', '2', '-dname', 'CN=Disposable Test'],
                       env=cls.env, capture_output=True, check=True)
        certificate = subprocess.check_output(['keytool', '-exportcert', '-keystore', str(key),
                                              '-storepass:env', 'ANDROID_DEV_STORE_PASSWORD', '-alias', 'preview'], env=cls.env)
        cls.env['ANDROID_DEV_KEYSTORE_BASE64'] = base64.b64encode(key.read_bytes()).decode()
        cls.env['ANDROID_DEV_CERT_SHA256'] = hashlib.sha256(certificate).hexdigest()

    @classmethod
    def tearDownClass(cls):
        cls.fixture.cleanup()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'export_presets.cfg').write_text('[preset.0.options]\npackage/unique_name="old"\n')
        self.env = self.env.copy()

    def prepare(self, suffix='config'):
        return signing.prepare(self.root, self.root / suffix, self.env)

    def test_missing_secret_fails_without_key(self):
        del self.env['ANDROID_DEV_KEYSTORE_BASE64']
        with self.assertRaises(ValueError): self.prepare()
        self.assertFalse((self.root / 'config').exists())

    def test_malformed_base64_rejected(self):
        self.env['ANDROID_DEV_KEYSTORE_BASE64'] = 'invalid!!!'
        with self.assertRaises(ValueError): self.prepare()

    def test_wrong_certificate_is_rejected_and_key_removed(self):
        self.env['ANDROID_DEV_CERT_SHA256'] = '0' * 64
        with self.assertRaises(ValueError): self.prepare()
        self.assertFalse((self.root / 'config/preview-signing.p12').exists())

    def test_wrong_password_rejected(self):
        self.env['ANDROID_DEV_STORE_PASSWORD'] = 'incorrect-test-password'
        with self.assertRaises(ValueError): self.prepare()
        self.assertFalse((self.root / 'config/preview-signing.p12').exists())

    def test_successive_versions_keep_identity_and_private_files(self):
        first = self.prepare()
        self.env['GITHUB_RUN_NUMBER'] = '2'
        second = self.prepare('next-config')
        self.assertEqual(first['certificate_sha256'], second['certificate_sha256'])
        self.assertEqual(first['package'], second['package'])
        self.assertGreater(second['version_code'], first['version_code'])
        for name in ['config/preview-signing.p12', 'config/godot/editor_settings-4.6.tres']:
            self.assertEqual((self.root / name).stat().st_mode & 0o777, 0o600)
        cfg = ConfigParser(); cfg.read(self.root / 'export_presets.cfg')
        self.assertEqual(cfg['preset.0.options']['package/unique_name'], '"com.nullswarm.game.preview"')
        self.assertNotIn(self.env['ANDROID_DEV_STORE_PASSWORD'], str(second))

    def test_invalid_version_rejected(self):
        self.env['GITHUB_RUN_NUMBER'] = '0'
        with self.assertRaises(ValueError): self.prepare()

    def test_apk_signer_must_match_pin_and_verify_successfully(self):
        expected = self.env['ANDROID_DEV_CERT_SHA256']
        result = subprocess.CompletedProcess([], 0, stdout='Signer #1 certificate SHA-256 digest: ' + expected + '\n')
        with patch.object(signing.subprocess, 'run', return_value=result):
            signing.verify_apk('apksigner', 'app.apk', expected)
            with self.assertRaises(ValueError): signing.verify_apk('apksigner', 'app.apk', '0' * 64)
        result.returncode = 1
        with patch.object(signing.subprocess, 'run', return_value=result):
            with self.assertRaises(ValueError): signing.verify_apk('apksigner', 'app.apk', expected)
