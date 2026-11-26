import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import test_route_pacing as fixtures

sys.path.insert(0, str(Path(__file__).parents[1]/'tools'))
from report_detour_probe import report, KIND
from report_collection_pacing import analyze


class DetourProbeTests(unittest.TestCase):
    def source(self):
        source = fixtures.RoutePacingTests().source();source['kind'] = KIND
        for case in source['cases']:
            case['bot_policy'] = 'detour' if case['bot_policy']=='value_aware' else 'value_aware'
            if case['bot_policy']=='detour':case['detours'] = {'started': 2, 'cancelled': 1}
        return source

    def test_exact_pairs_and_signed_deltas(self):
        result = report(self.source())
        self.assertEqual(len(result['cases']), 8)
        self.assertEqual(result['pairs'][0]['detour_minus_value_aware']['longest_gap_seconds'], 0)
        self.assertEqual(result['detours'][0], {'seed': 101, 'started': 2, 'cancelled': 1})

    def test_reference_and_experiment_schemas_stay_separate(self):
        with self.assertRaises(ValueError):report(fixtures.RoutePacingTests().source())
        with self.assertRaises(ValueError):analyze(self.source())

    def test_malformed_or_missing_counters_are_rejected(self):
        for counters in [None, {}, {'started': True, 'cancelled': 0}, {'started': 1, 'cancelled': 2},
                         {'started': -1, 'cancelled': 0}, {'started': 1, 'cancelled': 0, 'hidden': 1}]:
            source = self.source();source['cases'][1]['detours'] = counters
            with self.assertRaises(ValueError):report(source)
        source = self.source();source['cases'][0]['detours'] = {'started': 1, 'cancelled': 0}
        with self.assertRaises(ValueError):report(source)

    def test_missing_duplicate_changed_start_and_route_accounting_fail(self):
        source = self.source();source['cases'].pop()
        with self.assertRaises(ValueError):report(source)
        source = self.source();source['cases'][1] = copy.deepcopy(source['cases'][0])
        with self.assertRaises(ValueError):report(source)
        source = self.source();source['cases'][1]['research'] = {'hull': 1}
        with self.assertRaises(ValueError):report(source)
        source = self.source();source['cases'][1]['route_trace'][1]['dash_activations'] = 1
        with self.assertRaises(ValueError):report(source)

    def test_observations_preserve_losses_and_source(self):
        source = self.source();before = copy.deepcopy(source)
        result = report(source)
        self.assertTrue(all(c['outcome']=='defeat' for c in result['cases']))
        self.assertEqual(source, before)

    def test_cli_report_and_invalid_source_exit(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp);p = root/'source.json';p.write_text(json.dumps(self.source()))
            cmd = [sys.executable, str(Path(__file__).parents[1]/'tools/report_detour_probe.py'), '--input', str(p), '--output', str(root/'out')]
            result = subprocess.run(cmd, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('DETOUR_REPORT observed cases=8 pairs=4', result.stdout)
            self.assertIn('reference longest gap', (root/'out/DETOUR_REPORT.md').read_text())
            p.write_text('{}');failed = subprocess.run(cmd, capture_output=True, text=True)
            self.assertEqual(failed.returncode, 2)
