import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import test_detour_probe as fixtures

sys.path.insert(0, str(Path(__file__).parents[1]/'tools'))
from report_detour_holdout import KIND, POLICY_SOURCES, PROFILES, report


class DetourHoldoutTests(unittest.TestCase):
    def source(self):
        source = fixtures.DetourProbeTests().source()
        originals = source['cases'][:4]
        source.update(kind=KIND, candidate_source_sha256=POLICY_SOURCES['tests/detour_bot.gd'], policy_sources_sha256=POLICY_SOURCES.copy(), cases=[])
        for profile in PROFILES:
            for old in originals:
                case = copy.deepcopy(old);case['profile'] = profile;case['seed'] = {101:606,202:707}[case['seed']]
                source['cases'].append(case)
        return source

    def test_complete_matrix_preserves_profile_pairs_and_source(self):
        source = self.source();before = copy.deepcopy(source);result = report(source)
        self.assertEqual((result['runs'], result['pairs'], len(result['cohorts'])), (12,6,3))
        self.assertEqual([c['profile'] for c in result['cohorts']], list(PROFILES))
        self.assertTrue(all(len(c['cases'])==4 and [p['seed'] for p in c['pairs']]==[606,707] for c in result['cohorts']))
        self.assertEqual(source, before)

    def test_policy_freeze_is_required_and_pins_all_inherited_sources(self):
        for name in POLICY_SOURCES:
            source = self.source();source['policy_sources_sha256'][name] = '0'*64
            with self.assertRaisesRegex(ValueError, 'freeze'):report(source)
        source = self.source();source['candidate_source_sha256'] = '0'*64
        with self.assertRaises(ValueError):report(source)

    def test_missing_duplicate_unknown_profile_and_design_seed_rejected(self):
        source = self.source();source['cases'].pop()
        with self.assertRaises(ValueError):report(source)
        for update in [{'profile':'electric'},{'seed':101},{'research':{'hull':1}}]:
            source = self.source();source['cases'][0].update(update)
            with self.assertRaises(ValueError):report(source)
        source = self.source();source['cases'][1] = copy.deepcopy(source['cases'][0])
        with self.assertRaises(ValueError):report(source)

    def test_conditions_and_fresh_route_accounting_are_validated_per_cohort(self):
        source = self.source();source['cases'][5]['route_trace'][1]['dash_activations'] = 1
        with self.assertRaises(ValueError):report(source)
        source = self.source();source['cases'][9]['fixture'] = 'earned kit'
        with self.assertRaises(ValueError):report(source)

    def test_mixed_outcomes_are_observations_and_keep_signed_deltas(self):
        source = self.source();source['cases'][1]['outcome'] = 'victory'
        source['cases'][1]['xp_collected'] = 2;source['cases'][1]['pacing_trace'][-1].update(collected=2,dropped=19)
        result = report(source);pair = result['cohorts'][0]['pairs'][0]
        self.assertEqual((pair['value_aware_outcome'],pair['detour_outcome']),('defeat','victory'))
        self.assertEqual(pair['detour_minus_value_aware']['xp_collected'],-1)
        self.assertEqual(result['cohorts'][1]['pairs'][0]['detour_outcome'],'defeat')

    def test_cli_reports_frozen_matrix_and_rejects_design_input(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp);source = root/'source.json';source.write_text(json.dumps(self.source()))
            cmd = [sys.executable,str(Path(__file__).parents[1]/'tools/report_detour_holdout.py'),'--input',str(source),'--output',str(root/'out')]
            result = subprocess.run(cmd,capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertIn('cases=12 pairs=6 cohorts=3',result.stdout)
            self.assertIn('kinetic',(root/'out/HOLDOUT_REPORT.md').read_text())
            source.write_text(json.dumps(fixtures.DetourProbeTests().source()))
            self.assertEqual(subprocess.run(cmd,capture_output=True).returncode,2)
