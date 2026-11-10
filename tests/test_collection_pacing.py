import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parents[1] / 'tools'))
from report_collection_pacing import POLICIES, SEEDS, analyze, describe_case, longest_gap


class CollectionPacingTests(unittest.TestCase):
    def case(self, seed=101, policy='cautious'):
        return {'seed': seed, 'bot_policy': policy, 'profile': 'arcstorm', 'kit': 'vanguard',
                'fixture': 'new player', 'pickup_mode': 'local', 'link_policy': 'clean', 'research': {},
                'outcome': 'defeat', 'survived_seconds': 10., 'level': 1, 'xp_collected': 3, 'uncollected_xp': 17,
                'upgrade_choices': [{'at': 2., 'id': 'damage'}, {'at': 3., 'id': 'reroll'}, {'at': 7., 'id': 'arc'}],
                'longest_upgrade_gap_seconds': 5., 'pacing_trace': [
                    {'time': 0., 'dropped': 10, 'collected': 0, 'cold_xp': 10, 'attracted_xp': 0,
                     'cold_xp_within_16m': 0, 'nearest_cold_m': 20., 'pending': 0, 'level': 1, 'xp': 0},
                    {'time': 5., 'dropped': 12, 'collected': 2, 'cold_xp': 10, 'attracted_xp': 0,
                     'cold_xp_within_16m': 10, 'nearest_cold_m': 3., 'pending': 0, 'level': 1, 'xp': 2},
                    {'time': 10., 'dropped': 20, 'collected': 3, 'cold_xp': 17, 'attracted_xp': 0,
                     'cold_xp_within_16m': 0, 'nearest_cold_m': 20., 'pending': 1, 'level': 1, 'xp': 3}]}

    def source(self):
        return {'schema': 1, 'kind': 'normal-rules Arcstorm collection probe', 'failures': [],
                'godot': '4.6.3', 'fixed_step': 1/60,
                'cases': [self.case(s, p) for s in SEEDS for p in POLICIES]}

    def test_gaps_ignore_rerolls_and_include_start_and_tail(self):
        self.assertEqual(longest_gap(self.case()['upgrade_choices'], 10.), {'start': 2., 'end': 7., 'seconds': 5.})
        self.assertEqual(longest_gap([], 10.)['seconds'], 10.)
        self.assertEqual(longest_gap([{'at': 2., 'id': 'arc'}], 10.)['start'], 2.)

    def test_window_uses_actual_samples_and_preserves_xp_proximity(self):
        g = describe_case(self.case())['longest_gap']
        self.assertEqual(g['samples'], 1)
        self.assertEqual(g['samples_with_nearby_cold_xp'], 1)
        self.assertEqual(g['nearest_cold_median'], 3.)
        self.assertEqual(g['sampled_collected_delta'], 0)

    def test_absent_cold_pickup_is_unobserved_not_zero_distance(self):
        case = self.case(); sample = case['pacing_trace'][1]
        sample.update(dropped=2, cold_xp=0, cold_xp_within_16m=0, nearest_cold_m=-1)
        self.assertIsNone(describe_case(case)['longest_gap']['nearest_cold_median'])

    def test_pairs_keep_exact_seeds_and_report_signed_deltas(self):
        source = self.source()
        source['cases'][1].update(outcome='victory', xp_collected=10)
        source['cases'][1]['pacing_trace'][-1].update(collected=10, dropped=27)
        result = analyze(source)
        self.assertEqual(len(result['pairs']), 4)
        self.assertEqual(result['pairs'][0]['value_aware_outcome'], 'victory')
        self.assertEqual(result['pairs'][0]['value_aware_minus_cautious']['xp_collected'], 7)

    def test_duplicate_missing_or_mismatched_starting_conditions_fail(self):
        for changes in [{'profile': 'halo'}, {'kit': 'engineer'}, {'research': {'hull': 1}},
                        {'seed': 999}, {'bot_policy': 'unknown'}, {'pickup_mode': 'global'}]:
            source = self.source(); source['cases'][0].update(changes)
            with self.assertRaises(ValueError):analyze(source)
        source = self.source(); source['cases'][1] = copy.deepcopy(source['cases'][0])
        with self.assertRaisesRegex(ValueError, 'duplicate'):analyze(source)
        source['cases'].pop()
        with self.assertRaises(ValueError):analyze(source)

    def test_trace_accounting_order_and_reported_gap_must_agree(self):
        for changes in [{'dropped': 100}, {'collected': 100}, {'cold_xp_within_16m': 11}, {'time': -1}, {'nearest_cold_m': 30}]:
            case = self.case(); case['pacing_trace'][1].update(changes)
            with self.assertRaises(ValueError):describe_case(case)
        case = self.case(); case['longest_upgrade_gap_seconds'] = 6.
        with self.assertRaisesRegex(ValueError, 'disagrees'):describe_case(case)
        case = self.case(); case['xp_collected'] = 4
        with self.assertRaisesRegex(ValueError, 'final trace'):describe_case(case)
        with self.assertRaises(ValueError):longest_gap([{'at': 11., 'id': 'arc'}], 10.)

    def test_invalid_numbers_incomplete_trace_or_failed_source_fail(self):
        for changes in [{'survived_seconds': float('nan')}, {'level': True}, {'pacing_trace': []}, {'seed': True}]:
            case = self.case(); case.update(changes)
            with self.assertRaises(ValueError):describe_case(case)
        source = self.source(); source['failures'] = ['accounting error']
        with self.assertRaises(ValueError):analyze(source)
        source = self.source(); source['fixed_step'] = 0
        with self.assertRaises(ValueError):analyze(source)

    def test_reporting_does_not_mutate_inputs_or_promote_defeats_to_failures(self):
        source = self.source(); before = copy.deepcopy(source)
        self.assertEqual(analyze(source)['status'], 'observed')
        self.assertEqual(source, before)

    def test_cli_generates_both_reports_and_rejects_incomplete_input(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); path = root / 'input.json'; path.write_text(json.dumps(self.source()))
            tool = Path(__file__).parents[1] / 'tools/report_collection_pacing.py'
            cmd = [sys.executable, str(tool), '--input', str(path), '--output', str(root/'out')]
            result = subprocess.run(cmd, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('Nearby cold XP samples', (root/'out/ARCSTORM_COLLECTION_REPORT.md').read_text())
            self.assertEqual(len(json.loads((root/'out/arcstorm-collection-analysis.json').read_text())['pairs']), 4)
            path.write_text('{}')
            self.assertEqual(subprocess.run(cmd, capture_output=True).returncode, 2)


if __name__ == '__main__':unittest.main()
