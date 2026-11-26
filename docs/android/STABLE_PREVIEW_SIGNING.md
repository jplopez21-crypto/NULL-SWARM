# Stable preview installation and updates

The existing CI phone APK uses a newly generated debug key on every runner. Android cannot update an installed package with a different signer. The old signing keys were disposable and are not recoverable from APKs. Do not uninstall the working game to test this configuration; uninstalling deletes its private saves.

The new manual **Build stable preview APK** workflow uses `com.nullswarm.game.preview` / **NULL SWARM Preview**. Its initial install coexists with Development/Corruption builds; their saves stay separate. Subsequent Preview builds use the same pinned certificate and increasing version codes. There is no automatic migration of previous private saves.

## One-time owner setup

This requires access to GitHub environment secrets, which the connected GitHub repository tools do not provide. No owner signing key was generated or uploaded by this session.

1. On a trusted computer, outside the repository, create a dedicated preview key (Java keytool prompts for its password):

   ```sh
   keytool -genkeypair -storetype PKCS12 -keystore null-swarm-preview.p12 -alias preview -keyalg RSA -keysize 3072 -validity 10000 -dname "CN=NULL SWARM Preview"
   ```

   Keep two encrypted backups of this keystore and its password. PKCS12 uses the same store/key password. Never regenerate the key when updating Preview.

2. In [repository environment settings](https://github.com/jplopez21-crypto/NULL-SWARM/settings/environments), create `development-signing`. Restrict deployments to `main` and `development/android-validation`; apply environment protection appropriate to repository access. Add these environment secrets:

   | Secret | Value |
   | --- | --- |
   | `ANDROID_DEV_KEYSTORE_BASE64` | Base64 of the complete `.p12` file, without line breaks |
   | `ANDROID_DEV_STORE_PASSWORD` | The keystore password |
   | `ANDROID_DEV_KEY_ALIAS` | `preview` |
   | `ANDROID_DEV_CERT_SHA256` | SHA-256 certificate fingerprint from `keytool -list -v -keystore null-swarm-preview.p12 -alias preview` |

   Encode the file locally with Python (`base64.b64encode(Path(...).read_bytes()).decode()`), then paste directly into GitHub's secret form. Do not send key bytes/passwords through chat, commit them, or upload them as artifacts. The fingerprint is public metadata; the key and password are private.

3. The new workflow must first be registered on the default branch through the reviewed PR. In Actions, manually run **Build stable preview APK** on the intended reviewed branch. PRs never trigger this secret-bearing workflow. It intentionally fails if any secret is missing or its key differs from the fingerprint.

4. Download `null-swarm-stable-preview-apk`; extract and install `android/null-swarm-preview-debug.apk`. Retain `SIGNING_IDENTITY.json` as public identity/version metadata. Compare its certificate fingerprint with the previously installed Preview's metadata on later updates. Do not rename/reset the workflow version sequence when delivering updates; version codes must remain monotonic.

## Safeguards and verification

- Keytool checks the actual keystore certificate before export; apksigner verifies the APK signature and exact single-signer fingerprint afterward.
- No random signing fallback. Signing files are private temporary files, excluded from uploads and removed in the workflow's always-run cleanup.
- Config and keystore passwords are supplied through environment secrets, never command-line passwords or logs.
- Ordinary development CI remains disposable smoke-build infrastructure; it is not the stable Preview distribution channel.
- Seven tests use a temporary, disposable test key to check missing/malformed credentials, incorrect passwords/certificates, successive versions/identity, private file modes, and post-export signer rejection. They do not provision the real key or prove an actual APK upgrade.
- Pending acceptance: provision secrets, export the first Preview, install it, then install a second signed Preview with `adb install -r` and confirm saved settings/progression survive. Physical-device upgrades have not been tested.
- This is debug preview signing, not Google Play release signing. Play Protect can still scan sideloaded builds. The screenshot showed an in-progress scan; it did not establish the cause of its delay. Stable signing does not bypass scanning.
