import contextlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parents[1] / 'tools'))
from export_android_debug import export_debug, rate_limited

LIMITED = "Could not GET 'https://repo.maven.apache.org/maven2/a.pom'. Received status code 429 from server: Too Many Requests"


class AndroidExportRetryTests(unittest.TestCase):
    def run_export(self, outcomes, create_output=True):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            apk, reports = root / 'debug.apk', root / 'reports'
            calls, waits = [], []

            def run(command, **kwargs):
                self.assertEqual(command, ['godot', '--headless', '--export-debug', 'Android', str(apk)])
                code, text = outcomes[len(calls)]
                calls.append(command)
                if code == 0 and create_output:
                    apk.write_bytes(b'explicit synthetic test output; not a real APK')
                return subprocess.CompletedProcess(command, code, stdout=text)

            with contextlib.redirect_stdout(io.StringIO()):
                code = export_debug(apk, reports, runner=run, sleeper=waits.append)
            report = json.loads((reports / 'export.json').read_text())
            self.assertEqual(len(list(reports.glob('attempt-*.log'))), len(calls))
            return code, report, waits

    def test_success_needs_one_attempt(self):
        code, report, waits = self.run_export([(0, 'export completed')])
        self.assertEqual((code, report['status'], len(report['attempts']), waits), (0, 'passed', 1, []))

    def test_rate_limit_retries_with_retained_failure(self):
        code, report, waits = self.run_export([(1, LIMITED), (0, 'export completed')])
        self.assertEqual((code, report['status'], waits), (0, 'passed', [30]))
        self.assertTrue(report['attempts'][0]['maven_429'])
        self.assertEqual(report['attempts'][0]['exit_code'], 1)

    def test_exhaustion_is_failure_after_three_attempts(self):
        code, report, waits = self.run_export([(1, LIMITED)] * 3)
        self.assertEqual((code, report['status'], len(report['attempts']), waits), (1, 'failed', 3, [30, 60]))

    def test_other_failures_are_not_retried(self):
        for log in ['compile failed', LIMITED.replace('429', '401'), 'SCRIPT ERROR: bad script\n' + LIMITED,
                    'Parse Error: bad resource\n' + LIMITED, 'HTTP 429 from an unrelated service']:
            with self.subTest(log=log):
                code, report, waits = self.run_export([(1, log)])
                self.assertEqual((code, report['status'], len(report['attempts']), waits), (1, 'failed', 1, []))

    def test_success_without_apk_is_rejected(self):
        code, report, waits = self.run_export([(0, 'no file')], create_output=False)
        self.assertEqual((code, report['status'], waits), (1, 'failed', []))

    def test_http_status_alone_cannot_claim_maven_rate_limit(self):
        self.assertFalse(rate_limited('Received status code 429'))
        self.assertFalse(rate_limited('https://repo.maven.apache.org connection failed'))
        self.assertTrue(rate_limited(LIMITED))
