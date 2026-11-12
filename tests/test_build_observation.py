import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).parents[1] / 'tools'))
import build_observation as observation


class BuildObservationTests(unittest.TestCase):
    def setUp(self):
        self.before = {key: 1 for key in observation.BUILD_FROZEN_FIELDS}
        self.before.update(state='paused', rendered_state='paused', process=42,
                           panel=9, rendered_panel=9, rendered_frames=20, sample_ticks=100,
                           ranks={'thermal': 1}, settings={'music': .35}, dash_readiness={'cooldown': 1.2})
        self.current = copy.deepcopy(self.before)
        self.current.update(panel=10, rendered_panel=10, rendered_frames=22, sample_ticks=300)

    def test_navigation_and_waiting_on_same_panel(self):
        self.assertTrue(observation.frozen_navigation(self.before, self.current))
        self.current.update(panel=9, rendered_panel=9)
        self.assertTrue(observation.frozen_navigation(self.before, self.current))

    def test_every_changed_or_missing_run_field_is_rejected(self):
        for key in observation.BUILD_FROZEN_FIELDS:
            changed = copy.deepcopy(self.current)
            changed[key] = {'changed': True} if isinstance(changed[key], dict) else 2
            missing = copy.deepcopy(self.current); del missing[key]
            with self.subTest(field=key):
                self.assertFalse(observation.frozen_navigation(self.before, changed))
                self.assertFalse(observation.frozen_navigation(self.before, missing))

    def test_stale_wrong_process_or_unrendered_panels_are_rejected(self):
        for key, value in [('process', 43), ('state', 'playing'), ('rendered_state', 'playing'),
                           ('panel', None), ('rendered_panel', 9), ('rendered_frames', 20), ('sample_ticks', 100)]:
            changed = copy.deepcopy(self.current); changed[key] = value
            with self.subTest(field=key):self.assertFalse(observation.frozen_navigation(self.before, changed))
        changed = copy.deepcopy(self.before); changed['rendered_panel'] = 8
        self.assertFalse(observation.frozen_navigation(changed, self.current))
        for panel in [0, False]:
            changed = copy.deepcopy(self.current); changed.update(panel=panel, rendered_panel=panel)
            self.assertFalse(observation.frozen_navigation(self.before, changed))
        self.assertFalse(observation.frozen_navigation({}, {}))


if __name__ == '__main__':unittest.main()
