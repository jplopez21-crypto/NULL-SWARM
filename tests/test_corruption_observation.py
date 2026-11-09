import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).parents[1] / 'tools'))
from corruption_observation import corruption_offer_frozen, corruption_navigation_preserved, redline_selected, redline_terms, same_offer_actions
from build_observation import BUILD_FROZEN_FIELDS
from upgrade_observation import UPGRADE_FROZEN_FIELDS


class CorruptionObservationTests(unittest.TestCase):
    def setUp(self):
        self.text = 'REDLINE SYNC\nGAIN: Weapon cycles +30%\nCOST: Maximum HP 100 -> 80'
        self.before = {key: 1 for key in UPGRADE_FROZEN_FIELDS}
        self.before.update(state='upgrading', rendered_state='upgrading', process=42, panel=9, rendered_panel=9,
                           rendered_frames=20, sample_ticks=100, level=5, pending=1, ranks={'arc': 1},
                           health={'current': 90, 'maximum': 100, 'shield': 10, 'max_shield': 30},
                           corruption={'accepted': [], 'next_level': 5, 'cycle_rate': 1., 'enemy_pace': 1., 'walk_rate': 1., 'extra_rounds': 0, 'extra_drones': 0})
        self.after = copy.deepcopy(self.before)
        self.after.update(state='playing', pending=0)
        self.after['health'].update(current=80, maximum=80)
        self.after['corruption'].update(accepted=['redline'], next_level=10, cycle_rate=1.3)

    def test_terms_are_observed_from_the_actual_card(self):
        self.assertEqual(redline_terms(self.text), {'before_max': 100, 'after_max': 80, 'cycle_gain': 30})
        for text in [None, 'PARASITIC HIVE', self.text.replace('100 -> 80', '80 -> 100'), self.text.replace('100 -> 80', '20 -> 0')]:
            self.assertIsNone(redline_terms(text))

    def navigation_samples(self):
        before = {key: 1 for key in BUILD_FROZEN_FIELDS}
        before.update(copy.deepcopy(self.before))
        before['buttons'] = [{'text': '01\nARC EMITTER', 'disabled': False},
                             {'text': 'REROLL / 2', 'disabled': False}]
        current = copy.deepcopy(before)
        current.update(panel=10, rendered_panel=10, rendered_frames=22, sample_ticks=200)
        return before, current

    def test_picker_navigation_requires_fresh_rendered_panels_and_unchanged_state(self):
        before, current = self.navigation_samples()
        self.assertTrue(corruption_navigation_preserved(before, current))
        for changes in [{'panel': 9, 'rendered_panel': 9}, {'rendered_panel': 9}, {'rendered_frames': 20},
                        {'sample_ticks': 100}, {'process': 43}, {'state': 'playing'}, {'rendered_state': 'playing'}]:
            changed = copy.deepcopy(current); changed.update(changes)
            self.assertFalse(corruption_navigation_preserved(before, changed), changes)

    def test_declining_cannot_spend_any_observed_gameplay_or_setting_field(self):
        before, current = self.navigation_samples()
        for key in BUILD_FROZEN_FIELDS:
            changed = copy.deepcopy(current); changed[key] = 'changed'
            self.assertFalse(corruption_navigation_preserved(before, changed), key)
            del changed[key]
            self.assertFalse(corruption_navigation_preserved(before, changed), key)

    def test_restored_actions_preserve_rerolls_costs_order_and_enabled_state(self):
        before, current = self.navigation_samples()
        current['buttons'][0]['rect'] = [10, 20, 300, 50]
        self.assertTrue(same_offer_actions(before, current))
        for buttons in [[{'text': '01\nRAIL LANCE', 'disabled': False}, current['buttons'][1]],
                        [current['buttons'][0], {'text': 'REROLL / 1', 'disabled': False}],
                        [dict(current['buttons'][0], disabled=True), current['buttons'][1]],
                        list(reversed(current['buttons'])), current['buttons'][:1]]:
            self.assertFalse(same_offer_actions(before, {'buttons': buttons}))

    def test_missing_or_malformed_offer_actions_cannot_pass(self):
        before, _ = self.navigation_samples()
        for buttons in [None, [], ['button'], [{'text': '', 'disabled': False}],
                        [{'text': '01', 'disabled': 0}], [{'disabled': False}]]:
            self.assertFalse(same_offer_actions(before, {'buttons': buttons}))
        self.assertFalse(same_offer_actions({}, {}))

    def test_frozen_offer_requires_fresh_frames_and_both_new_stat_fields(self):
        current = copy.deepcopy(self.before); current.update(rendered_frames=22, sample_ticks=200)
        self.assertTrue(corruption_offer_frozen(self.before, current))
        for key in ['health', 'corruption', 'rendered_frames', 'process']:
            altered = copy.deepcopy(current)
            if key in ['health', 'corruption']:del altered[key]
            else:altered[key] = 20 if key == 'rendered_frames' else 43
            self.assertFalse(corruption_offer_frozen(self.before, altered))

    def test_actual_cost_and_later_contact_damage_are_accepted(self):
        self.assertTrue(redline_selected(self.before, self.after, self.text))
        self.after['health']['current'] = 65
        self.assertTrue(redline_selected(self.before, self.after, self.text))
        self.before['health']['current'] = 40; self.after['health']['current'] = 35
        self.assertTrue(redline_selected(self.before, self.after, self.text))

    def test_new_xp_after_resuming_does_not_look_like_a_lost_choice(self):
        self.after.update(level=6, pending=1)
        self.assertTrue(redline_selected(self.before, self.after, self.text))
        self.after['pending'] = 2
        self.assertFalse(redline_selected(self.before, self.after, self.text))

    def test_missing_double_cost_healing_extra_link_or_rank_are_rejected(self):
        variants = []
        for hp in [{'current': 80, 'maximum': 100}, {'current': 60, 'maximum': 60}, {'current': 81, 'maximum': 80}]:
            sample = copy.deepcopy(self.after); sample['health'].update(hp); variants.append(sample)
        for changes in [{'accepted': ['redline', 'fracture']}, {'next_level': 5}, {'cycle_rate': 1.}, {'walk_rate': .88}]:
            sample = copy.deepcopy(self.after); sample['corruption'].update(changes); variants.append(sample)
        sample = copy.deepcopy(self.after); sample['ranks']['health'] = 1; variants.append(sample)
        for sample in variants:self.assertFalse(redline_selected(self.before, sample, self.text))

    def test_wrong_process_incomplete_and_invalid_counter_data_are_rejected(self):
        for changes in [{'process': 43}, {'health': {}}, {'corruption': {}}, {'pending': True}, {'level': 4}, {'state': 'results'}]:
            sample = copy.deepcopy(self.after); sample.update(changes)
            self.assertFalse(redline_selected(self.before, sample, self.text))
        self.assertFalse(redline_selected({}, {}, self.text))


if __name__ == '__main__':unittest.main()
