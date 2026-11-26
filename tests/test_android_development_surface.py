import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

TOOLS = Path(__file__).parents[1] / 'tools/android_surface'
sys.path.insert(0, str(TOOLS))
import prepare_development as prepare
import verify_development_apk as verify


class DevelopmentSurfaceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.preset = self.root / 'export_presets.cfg'
        self.original = b'[preset.0.options]\ngradle_build/use_gradle_build=true\npackage/unique_name="private.identity"\n'
        self.preset.write_bytes(self.original)
        self.jar = self.root / 'android.jar'; self.jar.touch()
        self.aar = self.root / prepare.AAR; self.aar.parent.mkdir(parents=True)
        self.output = self.root / 'receipt'; self.output.mkdir()

    def receipt(self):
        return {'variant': 'latched', 'upstream_git_blob': prepare.surface.UPSTREAM_BLOB,
                'original_aar_sha256': prepare.PRISTINE_AAR_SHA256,
                'modified_aar_sha256': prepare.surface.digest(b'patched'),
                'compiled_source_sha256': prepare.surface.digest(prepare.surface.patched_source(prepare.surface.SOURCE.read_bytes(), 'latched')),
                'nonclass_aar_entries_unchanged': True}

    def test_bootstrap_failure_restores_exact_identity_and_presets(self):
        with patch.object(prepare.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'godot')):
            with self.assertRaises(subprocess.CalledProcessError):prepare.install_template(self.root, 'godot')
        self.assertEqual(self.preset.read_bytes(), self.original)

    def test_engine_version_drift_cannot_modify_aar(self):
        self.aar.write_bytes(b'unknown')
        with patch.object(prepare.subprocess, 'check_output', return_value='4.7.2.stable.official.hash'):
            with self.assertRaises(ValueError):prepare.prepare(self.root, self.jar, self.output)
        self.assertEqual(self.aar.read_bytes(), b'unknown')

    def test_missing_sdk_rejected_before_bootstrap(self):
        with patch.object(prepare.subprocess, 'run') as run:
            with self.assertRaises(ValueError):prepare.prepare(self.root, self.root/'missing.jar', self.output)
            run.assert_not_called()
        self.assertEqual(self.preset.read_bytes(), self.original)

    def test_unrecognized_aar_cannot_be_overwritten(self):
        self.aar.write_bytes(b'unreviewed-native-code')
        with patch.object(prepare.subprocess, 'check_output', return_value='4.6.3.stable.official.hash'):
            with self.assertRaises(ValueError):prepare.prepare(self.root, self.jar, self.output)
        self.assertEqual(self.aar.read_bytes(), b'unreviewed-native-code')

    def test_receipt_reuse_is_idempotent_but_rejects_tampered_aar(self):
        self.aar.write_bytes(b'patched');receipt=self.receipt()
        (self.output/'surface-build.json').write_text(json.dumps(receipt))
        with patch.object(prepare.subprocess, 'check_output', return_value='4.6.3.stable.official.hash'),patch.object(prepare.surface, 'rebuild') as rebuild:
            self.assertEqual(prepare.prepare(self.root, self.jar, self.output), receipt)
            rebuild.assert_not_called()
            self.aar.write_bytes(b'tampered')
            with self.assertRaises(ValueError):prepare.prepare(self.root, self.jar, self.output)
            rebuild.assert_not_called()
        self.assertEqual(self.preset.read_bytes(), self.original)

    def test_clean_aar_uses_latched_variant_and_preserves_preset(self):
        self.aar.write_bytes(b'pristine')
        with patch.object(prepare, 'PRISTINE_AAR_SHA256', prepare.surface.digest(b'pristine')),patch.object(prepare.subprocess, 'check_output', return_value='4.6.3.stable.official.hash'),patch.object(prepare.surface, 'rebuild', return_value={'ok': True}) as rebuild:
            self.assertEqual(prepare.prepare(self.root, self.jar, self.output), {'ok':True})
            rebuild.assert_called_once_with(self.aar, self.jar, self.output, 'latched')
        self.assertEqual(self.preset.read_bytes(), self.original)

    def apk(self, marker=True, engine=b'engine', license=True):
        data=io.BytesIO()
        with zipfile.ZipFile(data,'w') as z:
            z.writestr('classes.dex',b'mSurfaceRecreatePending' if marker else b'official')
            z.writestr('lib/arm64-v8a/libgodot_android.so',engine)
            z.writestr('lib/arm64-v8a/libc++_shared.so',b'c++')
            prefix='assets/resources/licenses/android_surface/'
            z.writestr(prefix+'Apache-2.0.txt',(TOOLS/'Apache-2.0.txt').read_bytes() if license else b'bad')
            z.writestr(prefix+'NOTICE.txt',(TOOLS.parents[1]/'resources/licenses/android_surface/NOTICE.txt').read_bytes())
        p=self.root/'test.apk';p.write_bytes(data.getvalue());return p

    def test_export_gate_rejects_missing_patch_native_drift_and_wrong_abi(self):
        r=self.receipt();r['native_libraries_sha256']={
            'jni/arm64-v8a/libgodot_android.so':prepare.surface.digest(b'engine'),
            'jni/arm64-v8a/libc++_shared.so':prepare.surface.digest(b'c++')}
        path=self.output/'surface-build.json';path.write_text(json.dumps(r))
        self.assertEqual(verify.verify(self.apk(),path,'arm64-v8a')['status'],'passed')
        for kwargs in [{'marker':False},{'engine':b'changed-native'},{'license':False}]:
            with self.assertRaises(ValueError):verify.verify(self.apk(**kwargs),path,'arm64-v8a')
        with self.assertRaises(ValueError):verify.verify(self.apk(),path,'x86_64')


if __name__ == '__main__':unittest.main()
