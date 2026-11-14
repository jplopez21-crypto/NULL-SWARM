# Local Android mutation coverage handoff

The feature is implemented and locally committed, with 108 Python tests and all fifteen strict Godot suites passing. It has not been published or executed on Android. No new APK or earned-mutation acceptance is claimed.

The remote development branch remains at `189525255657af69c150b4b8d3e5b4b2b53dfc6f` (tree `b6696a4f94338946981e391f37b53fbeb0ef16b4`). The equivalent local base is `0ceefb51975513530b6cb54d456316ea4dbd7d4e`. Feature commit `8b4f80f59748a0a3032dae9b88a376bb10e99189` has tree `7190edc61360abe779aa5b2651ed6039e1364b66`. Subsequent local documentation records the publishing blocker.

The patch artifact includes the feature and blocker documentation and can be imported with `git am` from an isolated checkout of the remote base. It changes Python test/observation code, Mobile workflow configuration and documentation; Godot gameplay and shipping settings remain unchanged. Main is unmerged. Artifact hashes and actual import verification are retained beside the patch in the execution workspace.

Once publishing works, run the configured workflows. The new `mobile-mutation` job is a bounded observation: `status: observed` can include a legal death, partial progress or budget expiry. Only `mutation_verified: true` with an earned transaction ledger, active equipped build text, positive Arcstorm damage and same-process persistence certifies completed mutation coverage. Existing Mobile smoke remains separate.

Local commands actually executed:

- `python3 -m unittest discover -s tests -p 'test_*.py'`
- `python3 tools/run_headless_checks.py`
- `python3 -m py_compile tools/android_runtime_smoke.py tools/mutation_observation.py`

The local environment has neither ADB nor KVM. GitHub reads work, but three publishing requests returned no result before interruption. See publish-blocker.json; no root cause or approval rejection has been established.
