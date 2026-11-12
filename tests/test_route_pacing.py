import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import test_collection_pacing as fixtures

sys.path.insert(0, str(Path(__file__).parents[1] / 'tools'))
from report_route_pacing import analyze_routes


class RoutePacingTests(unittest.TestCase):
    def source(self):
        source = fixtures.CollectionPacingTests().source()
        source['route_schema'] = 1
        for case in source['cases']:
            case.update(upgrade_choices=[], longest_upgrade_gap_seconds=10.)
            route = []
            for i, p in enumerate(case['pacing_trace']):
                p['position'] = [i * .2, 0.]
                route.append({'time': p['time'], 'travel_m': i * 35., 'active_seconds': i * 5.,
                              'steps': i * 300, 'command_reversals': i * 42,
                              'dash_requests': 0, 'dash_activations': 0, 'dash_ready_seconds': i * 5.})
            case['route_trace'] = route
        return source

    def test_exposes_looping_travel_without_claiming_stationary_controls(self):
        result = analyze_routes(self.source())
        row = result['cases'][0]['observed_route_window']
        self.assertEqual((row['travel_m'], row['net_m'], row['command_reversals']), (70, .4, 84))
        self.assertEqual((row['dash_requests'], row['dash_activations'], row['dash_ready_seconds']), (0, 0, 10))
        self.assertEqual(len(row['low_net_intervals']), 2)

    def test_requires_complete_explicit_route_measurements(self):
        for schema in [None, True, 0, 2]:
            source = self.source(); source['route_schema'] = schema
            with self.assertRaises(ValueError):analyze_routes(source)
        source = self.source(); source['cases'][0].pop('route_trace')
        with self.assertRaises(ValueError):analyze_routes(source)

    def test_route_and_pacing_times_and_coverage_must_match(self):
        source = self.source(); source['cases'][0]['route_trace'].pop()
        with self.assertRaisesRegex(ValueError, 'coverage'):analyze_routes(source)
        source = self.source(); source['cases'][0]['route_trace'][1]['time'] += .02
        with self.assertRaisesRegex(ValueError, 'time mismatch'):analyze_routes(source)

    def test_rejects_invalid_decreasing_or_inconsistent_counters(self):
        for changes in [{'steps': True}, {'travel_m': float('inf')}, {'command_reversals': -1},
                        {'dash_activations': 1}, {'active_seconds': 4}, {'dash_ready_seconds': 6},
                        {'steps': 0}, {'travel_m': 1000}]:
            source = self.source(); source['cases'][0]['route_trace'][1].update(changes)
            with self.assertRaises(ValueError):analyze_routes(source)
        source = self.source(); source['cases'][0]['route_trace'][-1]['command_reversals'] = 1
        with self.assertRaisesRegex(ValueError, 'decrease'):analyze_routes(source)

    def test_rejects_impossible_interval_motion_and_delayed_activation(self):
        source = self.source(); source['cases'][0]['pacing_trace'][1]['position'] = [40., 0]
        with self.assertRaisesRegex(ValueError, 'interval'):analyze_routes(source)
        source = self.source(); route = source['cases'][0]['route_trace']
        route[0].update(dash_requests=1, steps=1, active_seconds=1/60, time=0.)
        route[1].update(dash_requests=1, dash_activations=1)
        with self.assertRaisesRegex(ValueError, 'interval'):analyze_routes(source)

    def test_partial_windows_remain_unobserved_and_boundaries_are_not_invented(self):
        source = self.source(); case = source['cases'][0]
        case.update(upgrade_choices=[{'at': 2., 'id': 'arc'}, {'at': 7., 'id': 'damage'}], longest_upgrade_gap_seconds=5.)
        self.assertIsNone(analyze_routes(source)['cases'][0]['observed_route_window'])

    def test_sampled_footprint_and_low_net_thresholds_are_separate(self):
        source = self.source(); source['cases'][0]['pacing_trace'][1]['position'] = [10., 0]
        row = analyze_routes(source)['cases'][0]['observed_route_window']
        self.assertEqual(row['net_m'], .4)
        self.assertEqual(row['sampled_footprint_diagonal_m'], 10.)
        self.assertEqual(row['low_net_intervals'], [])

    def test_preserves_input_and_valid_defeats(self):
        source = self.source(); before = copy.deepcopy(source)
        self.assertEqual(analyze_routes(source)['status'], 'observed')
        self.assertEqual(source, before)

    def test_cli_generates_reports_and_rejects_legacy_proximity_only_input(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); source = root/'input.json'; source.write_text(json.dumps(self.source()))
            tool = Path(__file__).parents[1]/'tools/report_route_pacing.py'
            cmd = [sys.executable, str(tool), '--input', str(source), '--output', str(root/'out')]
            result = subprocess.run(cmd, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('ROUTE_REPORT observed cases=8', result.stdout)
            self.assertIn('Travel / net', (root/'out/ROUTE_REPORT.md').read_text())
            source.write_text(json.dumps(fixtures.CollectionPacingTests().source()))
            failed = subprocess.run(cmd, text=True, capture_output=True)
            self.assertEqual(failed.returncode, 2)
            self.assertIn('missing route schema', failed.stderr)
