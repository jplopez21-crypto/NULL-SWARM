import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).parents[1] / 'tools'))
import upgrade_observation as observation


class UpgradeObservationTests(unittest.TestCase):
    def setUp(self):
        self.before = {key: 1 for key in observation.UPGRADE_FROZEN_FIELDS}
        self.before.update(state='upgrading', rendered_state='upgrading', process=42,
                           level=2, pending=1, ranks={}, rendered_frames=20, sample_ticks=100,
                           panel=9, rendered_panel=9)
        self.current = copy.deepcopy(self.before)
        self.current.update(rendered_frames=22, sample_ticks=300)

    def test_actual_frozen_offer_and_every_mutated_field(self):
        self.assertTrue(observation.upgrade_frozen(self.before, self.current))
        for key in observation.UPGRADE_FROZEN_FIELDS:
            candidate = copy.deepcopy(self.current); candidate[key] = {'changed': 1} if key == 'ranks' else self.current[key] + 1
            with self.subTest(key=key):self.assertFalse(observation.upgrade_frozen(self.before, candidate))

    def test_missing_stale_wrong_process_and_unrendered_offer_are_rejected(self):
        for key, value in [('rendered_frames',20),('sample_ticks',100),('process',43),
                           ('rendered_state','playing'),('rendered_panel',8),('state','paused')]:
            candidate = copy.deepcopy(self.current); candidate[key] = value
            with self.subTest(key=key):self.assertFalse(observation.upgrade_frozen(self.before, candidate))
        self.assertFalse(observation.upgrade_frozen({}, self.current))

    def test_single_pick_new_existing_and_queued_rank(self):
        after = copy.deepcopy(self.current);after.update(state='playing',pending=0,ranks={'arc':1})
        self.assertEqual(observation.selected_rank(self.before, after),'arc')
        before = copy.deepcopy(self.before);before.update(pending=2,ranks={'arc':1})
        after.update(state='upgrading',pending=1,ranks={'arc':2})
        self.assertEqual(observation.selected_rank(before, after),'arc')

    def test_newly_earned_levels_after_resume_are_accounted_without_extra_picks(self):
        after = copy.deepcopy(self.current);after.update(level=3,pending=1,ranks={'arc':1})
        self.assertEqual(observation.selected_rank(self.before, after),'arc')
        after['ranks']['arc']=2
        self.assertIsNone(observation.selected_rank(self.before, after))

    def test_extra_rank_lost_choice_regression_and_invalid_data_are_rejected(self):
        good = copy.deepcopy(self.current);good.update(state='playing',pending=0,ranks={'arc':1})
        for changes in [{'ranks':{}},{'ranks':{'arc':2}},{'ranks':{'arc':1,'speed':1}},
                        {'ranks':{'arc':True}},{'pending':1},{'pending':-1},{'level':1},
                        {'level':True},{'process':43},{'state':'results'}]:
            candidate = copy.deepcopy(good);candidate.update(changes)
            with self.subTest(changes=changes):self.assertIsNone(observation.selected_rank(self.before,candidate))
        previous=copy.deepcopy(self.before);previous['ranks']={'rate':1}
        self.assertIsNone(observation.selected_rank(previous,good))
        self.assertIsNone(observation.selected_rank({},good))


if __name__=='__main__':unittest.main()
