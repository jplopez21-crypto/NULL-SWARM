import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).parents[1] / 'tools'))
from input_delivery import describe_delivery


class InputDeliveryTests(unittest.TestCase):
    def setUp(self):
        self.before = {'process': 42, 'sample_ticks': 100, 'input_delivery': {
            'presses': 10, 'releases': 10, 'recent': [], 'window_focused': True}}
        self.after = copy.deepcopy(self.before)
        self.after['sample_ticks'] = 200
        self.after['input_delivery'].update(presses=11, releases=11, recent=[
            {'sequence': 21, 'index': 0, 'pressed': True, 'canceled': False, 'position': [640, 446], 'ticks': 120},
            {'sequence': 22, 'index': 0, 'pressed': False, 'canceled': False, 'position': [640, 446], 'ticks': 130}])

    def status(self, sample):
        return describe_delivery(self.before, sample, [640, 446])['status']

    def test_complete_target_pair_reports_delivery_without_claiming_menu_success(self):
        sample = copy.deepcopy(self.after)
        sample['state'] = 'paused'
        self.assertEqual(self.status(sample), 'delivered_at_target')
        sample['input_delivery']['recent'][0]['position'] = [640.5, 446.5]
        self.assertEqual(self.status(sample), 'delivered_at_target')

    def test_no_new_event_differs_from_press_without_release(self):
        untouched = copy.deepcopy(self.before); untouched['sample_ticks'] = 200
        self.assertEqual(self.status(untouched), 'not_observed_by_game')
        pressed = copy.deepcopy(self.after)
        pressed['input_delivery'].update(releases=10, recent=pressed['input_delivery']['recent'][:1])
        self.assertEqual(self.status(pressed), 'press_without_release')

    def test_canceled_touch_is_not_successful_delivery(self):
        self.after['input_delivery']['recent'][1]['canceled'] = True
        self.assertEqual(self.status(self.after), 'touch_canceled')

    def test_other_coordinates_and_mismatched_pointer_do_not_pass(self):
        elsewhere = copy.deepcopy(self.after)
        for event in elsewhere['input_delivery']['recent']:event['position'] = [10, 10]
        self.assertEqual(self.status(elsewhere), 'delivered_elsewhere')
        self.after['input_delivery']['recent'][1]['index'] = 1
        self.assertNotEqual(self.status(self.after), 'delivered_at_target')

    def test_stale_samples_restarted_process_or_missing_data_are_inconclusive(self):
        for changes in [{'sample_ticks': 100}, {'process': 43}, {'input_delivery': {}}, {'sample_ticks': True}]:
            sample = copy.deepcopy(self.after); sample.update(changes)
            self.assertEqual(self.status(sample), 'inconclusive')
        self.assertEqual(describe_delivery({}, {}, [0, 0])['status'], 'inconclusive')

    def test_counter_regression_missing_history_and_disagreement_are_inconclusive(self):
        for changes in [{'presses': 9}, {'releases': 10}, {'presses': True}, {'recent': []},
                        {'releases': 1000000000}, {'window_focused': 1}]:
            sample = copy.deepcopy(self.after); sample['input_delivery'].update(changes)
            self.assertEqual(self.status(sample), 'inconclusive')
        self.after['input_delivery']['recent'][1]['sequence'] = 23
        self.assertEqual(self.status(self.after), 'inconclusive')

    def test_invalid_event_geometry_order_or_time_is_inconclusive(self):
        for changes in [{'position': [float('nan'), 446]}, {'position': [640]}, {'pressed': 1},
                        {'index': 32}, {'sequence': 20}, {'ticks': 99}, {'ticks': 201}]:
            sample = copy.deepcopy(self.after); sample['input_delivery']['recent'][1].update(changes)
            self.assertEqual(self.status(sample), 'inconclusive', changes)

    def test_focus_is_observed_and_inputs_are_unchanged(self):
        self.after['input_delivery']['window_focused'] = False
        original = copy.deepcopy(self.after)
        observed = describe_delivery(self.before, self.after, [640, 446])
        self.assertFalse(observed['window_focused_after'])
        self.assertEqual(observed['status'], 'delivered_at_target')
        self.assertEqual(self.after, original)
        self.assertEqual(describe_delivery(self.before, self.after, [True, 446])['status'], 'inconclusive')


if __name__ == '__main__':unittest.main()
