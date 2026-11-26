import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parents[1] / 'tools'))
from report_playtest_balance import REPORTS, compare, distribution, load_runs, summarize


class BalanceReportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.case = {'profile': 'arcstorm', 'kit': 'vanguard', 'fixture': 'new player',
                     'bot_policy': 'cautious', 'pickup_mode': 'local', 'link_policy': 'clean',
                     'research': {}, 'seed': 101, 'outcome': 'defeat', 'survived_seconds': 100.,
                     'kills': 20, 'level': 3, 'xp_collected': 60, 'uncollected_xp': 40,
                     'first_level_seconds': 10., 'first_new_weapon_seconds': 10.,
                     'longest_upgrade_gap_seconds': 25., 'mutations': {'arcstorm': 90.},
                     'wall_seconds': 8., 'simulation_step_p95_ms': .2}

    def write(self, label, cases=None, **metadata):
        folder = self.root / label; folder.mkdir(exist_ok=True)
        for name in REPORTS:
            report = {'schema': 1, 'kind': 'normal-rules fixture', 'godot': '4.6.3',
                      'fixed_step': 1/60, 'failures': [], 'cases': cases if cases is not None else [self.case]}
            report.update(metadata)
            (folder / name).write_text(json.dumps(report))
        return folder

    def test_machine_timings_and_order_do_not_change_balance_observations(self):
        a = load_runs(self.write('a', [self.case, dict(self.case, seed=202)]))
        reordered = [dict(self.case, seed=202, wall_seconds=100), dict(self.case, simulation_step_p95_ms=999)]
        b = load_runs(self.write('b', reordered))
        result = compare(a, b)
        self.assertEqual(result['matched'], 8)
        self.assertEqual(result['changed_observations'], 0)
        self.assertEqual(result['added'], [])

    def test_missing_event_is_unobserved_and_excluded_from_median(self):
        source = load_runs(self.write('a', [dict(self.case, first_new_weapon_seconds=-1), dict(self.case, seed=202)]))
        group = summarize(source['cases'])[0]
        self.assertEqual(group['metrics']['first_new_weapon_seconds'], {'observed': 1, 'unobserved': 1, 'median': 10., 'minimum': 10., 'maximum': 10.})
        self.assertEqual(distribution(iter([None, None]))['median'], None)

    def test_outcome_pacing_and_mutation_changes_are_reported_without_failure(self):
        a = load_runs(self.write('a'))
        b = load_runs(self.write('b', [dict(self.case, outcome='time_limit', survived_seconds=120., first_new_weapon_seconds=-1, kills=21, mutations={})]))
        change = compare(a, b)['changes'][0]
        self.assertEqual(change['outcome'], {'before': 'defeat', 'after': 'time_limit'})
        self.assertEqual(change['metrics']['survived_seconds']['delta'], 20.)
        self.assertIsNone(change['metrics']['first_new_weapon_seconds']['delta'])
        self.assertEqual(change['mutations']['after'], {})

    def test_different_kits_policies_research_and_suites_never_pool(self):
        variants = [self.case, dict(self.case, kit='engineer'), dict(self.case, link_policy='redline'),
                    dict(self.case, bot_policy='collector'), dict(self.case, research={'hull': 1})]
        source = load_runs(self.write('a', variants))
        self.assertEqual(len(summarize(source['cases'])), 20)

    def test_duplicate_identity_is_rejected_including_reordered_research(self):
        a = dict(self.case, research={'hull': 1, 'speed': 2})
        b = dict(self.case, research={'speed': 2, 'hull': 1})
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            load_runs(self.write('a', [a, b]))

    def test_added_and_removed_seeds_are_explicit(self):
        a = load_runs(self.write('a'))
        b = load_runs(self.write('b', [dict(self.case, seed=202)]))
        result = compare(a, b)
        self.assertEqual(result['matched'], 0)
        self.assertEqual(len(result['added']), 4)
        self.assertEqual(len(result['removed']), 4)

    def test_incompatible_engine_step_or_report_kind_is_rejected(self):
        a = load_runs(self.write('a'))
        for changes in [{'godot': '4.7'}, {'fixed_step': 1/30}, {'kind': 'different normal-rules fixture'}]:
            with self.assertRaisesRegex(ValueError, 'incompatible'):
                compare(a, load_runs(self.write('b', **changes)))

    def test_failed_synthetic_empty_or_missing_reports_are_rejected(self):
        for changes in [{'failures': ['bad run']}, {'kind': 'synthetic stress'}, {'schema': True}, {'cases': []}, {'godot': ''}]:
            with self.assertRaises(ValueError):load_runs(self.write('bad', **changes))
        folder = self.write('missing'); (folder / REPORTS[0]).unlink()
        with self.assertRaises(FileNotFoundError):load_runs(folder)

    def test_invalid_counters_times_and_mutation_data_are_rejected(self):
        for changes in [{'kills': True}, {'level': 0}, {'xp_collected': -1}, {'survived_seconds': float('nan')},
                        {'first_level_seconds': -.5}, {'first_new_weapon_seconds': 101}, {'mutations': {'halo': 101}},
                        {'mutations': {'halo': True}}, {'research': {'hull': -1}}, {'seed': True}]:
            with self.assertRaises(ValueError, msg=str(changes)):
                load_runs(self.write('invalid', [dict(self.case, **changes)]))

    def test_mutation_reach_reports_unreached_runs_without_zero_time(self):
        cases = [self.case, dict(self.case, seed=202, mutations={})]
        group = summarize(load_runs(self.write('a', cases))['cases'])[0]
        self.assertEqual(group['mutations']['arcstorm']['observed'], 1)
        self.assertEqual(group['mutations']['arcstorm']['unobserved'], 1)
        self.assertEqual(group['mutations']['arcstorm']['median'], 90.)

    def test_cli_writes_real_outputs_and_returns_nonzero_for_invalid_input(self):
        source = self.write('a'); output = self.root / 'out'
        tool = Path(__file__).parents[1] / 'tools/report_playtest_balance.py'
        result = subprocess.run([sys.executable, str(tool), '--candidate', str(source), '--baseline', str(source), '--output', str(output)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads((output / 'balance-report.json').read_text())
        self.assertEqual(report['comparison']['matched'], 4)
        self.assertIn('defeat: 1', (output / 'BALANCE_REPORT.md').read_text())
        self.assertIn('Reached / runs', (output / 'BALANCE_REPORT.md').read_text())
        (source / REPORTS[0]).write_text('[]')
        bad = subprocess.run([sys.executable, str(tool), '--candidate', str(source), '--output', str(output)], capture_output=True, text=True)
        self.assertEqual(bad.returncode, 2)
        self.assertIn('BALANCE_REPORT_ERROR', bad.stderr)


if __name__ == '__main__':unittest.main()
