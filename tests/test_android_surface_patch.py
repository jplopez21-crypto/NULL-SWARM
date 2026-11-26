import importlib.util
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec=importlib.util.spec_from_file_location('surface_patch',Path(__file__).parents[1]/'tools/android_surface/rebuild_surface_aar.py')
surface=importlib.util.module_from_spec(spec);spec.loader.exec_module(surface)

def archive(entries):
    data=io.BytesIO()
    with zipfile.ZipFile(data,'w') as z:
        for name, value in entries.items():z.writestr(name,value)
    return data.getvalue()

class SurfacePatchTests(unittest.TestCase):
    def test_exact_control_and_drift_guard(self):
        source=surface.SOURCE.read_bytes()
        self.assertEqual(surface.patched_source(source,'control'),source)
        for invalid in [source+b'\n',source.replace(b'mHasSurface',b'mHasSurfaceChanged',1)]:
            with self.assertRaises(ValueError):surface.patched_source(invalid,'latched')

    def test_patch_has_no_ui_wait_or_context_reset(self):
        source=surface.SOURCE.read_bytes();changed=surface.patched_source(source,'latched')
        self.assertNotEqual(source,changed)
        self.assertEqual(changed.count(b'mSurfaceRecreatePending = true;'),2)
        method=changed.split(b'private void consumePendingSurfaceChangeLocked() {',1)[1].split(b'private void guardedRun()',1)[0]
        self.assertIn(b'stopEglSurfaceLocked();',method)
        self.assertNotIn(b'stopEglContextLocked',method)
        self.assertNotIn(b'.wait(',method)
        self.assertNotIn(b'.join(',method)
        with self.assertRaises(ValueError):surface.patched_source(source,'unreviewed')

    def test_archive_replacement_is_exact(self):
        original=archive({'classes.jar':b'old','jni/x86_64/libgodot_android.so':b'engine','AndroidManifest.xml':b'manifest'})
        changed=surface.replace_entries(original,{'classes.jar':b'new'},lambda n:n=='classes.jar')
        with zipfile.ZipFile(io.BytesIO(changed)) as z:
            self.assertEqual(z.read('classes.jar'),b'new')
            self.assertEqual(z.read('jni/x86_64/libgodot_android.so'),b'engine')
            self.assertEqual(z.read('AndroidManifest.xml'),b'manifest')
        with self.assertRaises(ValueError):surface.replace_entries(original,{'missing':b'new'},lambda n:n=='classes.jar')

    def test_failed_compilation_never_changes_input_aar(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);aar=root/'godot-debug.aar'
            jar=archive({surface.PREFIX+'.class':b'\xca\xfe\xba\xbe\x00\x00\x00\x34'})
            original=archive({'classes.jar':jar,'jni/x86_64/libgodot_android.so':b'engine'})
            aar.write_bytes(original)
            with patch.object(surface.subprocess,'check_output',return_value='javac 21'),patch.object(surface.subprocess,'run',side_effect=subprocess.CalledProcessError(1,'javac')):
                with self.assertRaises(subprocess.CalledProcessError):surface.rebuild(aar,root/'android.jar',root/'output','latched')
            self.assertEqual(aar.read_bytes(),original)

if __name__=='__main__':unittest.main()
