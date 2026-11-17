# Local Android mutation coverage handoff

The feature is implemented and locally committed. Latest Nov 17 validation passes 112 Python tests and all fifteen strict Godot suites after tightening exact card-effect acceptance. It has not been published or executed on Android. No new APK or earned-mutation acceptance is claimed. Original 108-test receipts remain historical evidence for the initial feature.

The remote development branch remains at `189525255657af69c150b4b8d3e5b4b2b53dfc6f` (tree `b6696a4f94338946981e391f37b53fbeb0ef16b4`). The equivalent local base is `0ceefb51975513530b6cb54d456316ea4dbd7d4e`. Feature commit `8b4f80f59748a0a3032dae9b88a376bb10e99189` has tree `7190edc61360abe779aa5b2651ed6039e1364b66`. Subsequent local documentation records the publishing blocker.

The patch artifact includes the feature and blocker documentation and can be imported with `git am` from an isolated checkout of the remote base. It changes Python test/observation code, Mobile workflow configuration and documentation; Godot gameplay and shipping settings remain unchanged. Main is unmerged. Artifact hashes and actual import verification are retained beside the patch in the execution workspace.

Once publishing works, run the configured workflows. The new `mobile-mutation` job is a bounded observation: `status: observed` can include a legal death, partial progress or budget expiry. Only `mutation_verified: true` with an earned transaction ledger, active equipped build text, positive Arcstorm damage and same-process persistence certifies completed mutation coverage. Existing Mobile smoke remains separate.

Local commands actually executed:

- `python3 -m unittest discover -s tests -p 'test_*.py'`
- `python3 tools/run_headless_checks.py`
- `python3 -m py_compile tools/android_runtime_smoke.py tools/mutation_observation.py`

The local environment has neither ADB nor KVM. GitHub reads work, but three publishing requests returned no result before interruption. See publish-blocker.json; no root cause or approval rejection has been established.

On Nov 15, a bounded no-op tree probe also returned no result within 45 seconds. Default CLI proxy connections are blocked by sandbox sockets; the additional-network read check remains unresolved. No ref change was requested by the probe. Authentication and backend cause remain unconfirmed.

Offline compatibility replay now passes three recorded upgrade transactions and four fresh offer panels from the prior verified Mobile artifact (run 43322607040/artifact 13992201255). The new helpers correctly reject an unevolved build that lists Arcstorm only in its recipe guide. Replay selection outputs are hypothetical, and no new Android touches or mutation occurred. See archived-replay.json for the input hash, source, actual card text and limits.

Nov 17 adds a reproduced-before/fixed-after test flaw: a claimed card tap must increment that card's rank, rather than merely one visible upgrade. The mutation driver now checks this immediately and its ledger verifies it again. All base/evolved/passive/repair titles are mapped; unknown/disabled/missing/ambiguous cards fail closed. Four added regressions pass, with archived actual speed/thermal/drone transactions still accepted and a synthetic wrong-card claim rejected. See card-effect-verification.json and archived-card-effects.json. No real app misrouting bug was demonstrated. A bounded no-op publishing probe remains unresolved; remote refs are unchanged.
