import importlib.util
from configparser import ConfigParser
from pathlib import Path
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('emulator_export',Path(__file__).parents[1]/'tools/configure_emulator_export.py')
export=importlib.util.module_from_spec(spec);spec.loader.exec_module(export)

class EmulatorExportTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name)
        (self.root/'export_presets.cfg').write_text('[preset.0.options]\narchitectures/arm64-v8a=true\nversion/code=7\nkeystore/debug="unchanged-keystore"\ngradle_build/use_gradle_build=true\n')
        (self.root/'project.godot').write_text('[rendering]\nrenderer/rendering_method="mobile"\nrenderer/rendering_method.mobile="mobile"\nrenderer/rendering_method.web="gl_compatibility"\n')

    def config(self):
        c=ConfigParser(interpolation=None);c.read(self.root/'export_presets.cfg');return c['preset.0.options']

    def test_default_compatibility_preserves_identity_settings_and_other_targets(self):
        self.assertEqual(export.configure(self.root),'com.nullswarm.game.emulatorqa')
        c=self.config();self.assertEqual(c['architectures/arm64-v8a'],'false');self.assertEqual(c['architectures/x86_64'],'true')
        self.assertEqual(c['keystore/debug'],'"unchanged-keystore"');self.assertEqual(c['version/code'],'7');self.assertEqual(c['gradle_build/use_gradle_build'],'true')
        self.assertIn('renderer/rendering_method.web="gl_compatibility"',(self.root/'project.godot').read_text())

    def test_mobile_is_explicit_and_repeated_configuration_is_idempotent(self):
        self.assertEqual(export.configure(self.root,'mobile'),'com.nullswarm.game.mobileqa')
        first=(self.root/'project.godot').read_bytes();export.configure(self.root,'mobile');self.assertEqual(first,(self.root/'project.godot').read_bytes())
        self.assertEqual(first.count(b'[qa]'),1);self.assertIn(b'renderer/rendering_method.mobile="mobile"',first)
        export.configure(self.root);self.assertIn(b'renderer/rendering_method="gl_compatibility"',(self.root/'project.godot').read_bytes())

    def test_frame_pacing_workaround_is_explicit_mobile_only_and_idempotent(self):
        p=self.root/'project.godot';p.write_text('[display]\n'+p.read_text())
        export.configure(self.root,'mobile')
        self.assertNotIn('window/frame_pacing/android/enable_frame_pacing',p.read_text())
        export.configure(self.root,'mobile',True)
        self.assertEqual(p.read_text().count('window/frame_pacing/android/enable_frame_pacing=false'),1)
        first=p.read_bytes();export.configure(self.root,'mobile',True);self.assertEqual(first,p.read_bytes())
        preset=(self.root/'export_presets.cfg').read_bytes()
        with self.assertRaises(ValueError):export.configure(self.root,'gl_compatibility',True)
        self.assertEqual(first,p.read_bytes());self.assertEqual(preset,(self.root/'export_presets.cfg').read_bytes())

    def test_unsupported_renderer_never_writes_configs(self):
        before=[(self.root/n).read_bytes() for n in ['project.godot','export_presets.cfg']]
        with self.assertRaises(ValueError):export.configure(self.root,'unsupported')
        self.assertEqual(before,[(self.root/n).read_bytes() for n in ['project.godot','export_presets.cfg']])

    def test_missing_anchor_refuses_both_writes(self):
        project=self.root/'project.godot';project.write_text('[rendering]\nrenderer/rendering_method="mobile"\n')
        before=project.read_bytes();preset=(self.root/'export_presets.cfg').read_bytes()
        with self.assertRaises(ValueError):export.configure(self.root,'mobile')
        self.assertEqual(project.read_bytes(),before);self.assertEqual((self.root/'export_presets.cfg').read_bytes(),preset)

if __name__=='__main__':unittest.main()
