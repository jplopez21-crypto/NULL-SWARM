import copy
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('observation', Path(__file__).parents[1] / 'tools/lifecycle_observation.py')
observation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(observation)

class LifecycleObservationTests(unittest.TestCase):
    def setUp(self):
        self.before = dict(process=42, sample_ticks=100, rendered_frames=20, lifecycle={'foreground_generation': 1})
        self.returned = dict(process=42, sample_ticks=200, rendered_frames=22, state='paused', rendered_state='paused', panel=9, rendered_panel=9,
                             lifecycle={'foreground_generation': 3, 'rendered_generation': 3})

    def test_actual_fresh_return(self):
        self.assertTrue(observation.fresh_resumed_frame(self.before, self.returned))

    def test_stale_and_wrong_generation_rejected(self):
        for field, value in [('sample_ticks', 100), ('rendered_frames', 20), ('process', 43), ('rendered_state', 'playing'), ('rendered_panel', 8)]:
            candidate = copy.deepcopy(self.returned); candidate[field] = value
            with self.subTest(field=field): self.assertFalse(observation.fresh_resumed_frame(self.before, candidate))
        no_before = dict(self.before); no_before.pop('process')
        no_current = dict(self.returned); no_current.pop('process')
        self.assertFalse(observation.fresh_resumed_frame(no_before, no_current))
        for lifecycle in [{}, {'foreground_generation': 1, 'rendered_generation': 1}, {'foreground_generation': 3, 'rendered_generation': 1}]:
            candidate = copy.deepcopy(self.returned); candidate['lifecycle'] = lifecycle
            self.assertFalse(observation.fresh_resumed_frame(self.before, candidate))

    def test_freeze_checks_every_gameplay_field(self):
        snapshot = {key: 1 for key in observation.FROZEN_FIELDS}; snapshot['state'] = 'paused'
        self.assertTrue(observation.frozen_run(snapshot, snapshot))
        for key in observation.FROZEN_FIELDS:
            candidate = dict(snapshot); candidate[key] = 2
            with self.subTest(field=key): self.assertFalse(observation.frozen_run(snapshot, candidate))
        self.assertFalse(observation.frozen_run({}, {'state': 'paused'}))

    def test_app_only_warning_count_does_not_double_count_driver(self):
        log = '\n'.join(['11-06 12:00:00 42 50 E EGL_emulation: swapBuffers error 0x300d',
                         '11-06 12:00:00 42 50 W GLThread: eglSwapBuffers failed: EGL_BAD_SURFACE',
                         '11-06 12:00:00 99 50 W GLThread: eglSwapBuffers failed: EGL_BAD_SURFACE', 'bad line'])
        self.assertEqual(len(observation.app_egl_failures(log, 42)), 1)
        self.assertEqual(observation.app_egl_failures(log, 7), [])

if __name__ == '__main__': unittest.main()
