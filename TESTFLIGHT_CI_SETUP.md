# Setting up automated TestFlight deploys

`.github/workflows/testflight.yml` builds and uploads to TestFlight when you
push a tag like `v1.0.0`, or manually via the "Run workflow" button in the
GitHub Actions tab. It needs several secrets set in this repo's
**Settings → Secrets and variables → Actions** before it will work. All of
these require your Apple Developer / App Store Connect account — I can't
generate them for you.

## 1. App Store Connect API key (for uploading, no 2FA prompts)

1. appstoreconnect.apple.com → Users and Access → Integrations → App Store Connect API.
2. Generate a new key with **App Manager** role.
3. Note the **Key ID** and **Issuer ID** shown on that page.
4. Download the `.p8` file (Apple only lets you download it once).
5. Base64-encode it and save as a secret:
   ```bash
   base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
   ```
   Paste as secret `ASC_KEY_CONTENT_BASE64`.
6. Also set secrets `ASC_KEY_ID` (the Key ID) and `ASC_ISSUER_ID` (the Issuer ID).

## 2. Distribution certificate

1. In Xcode: Settings → Accounts → your Apple ID → Manage Certificates → **+ → Apple Distribution** (creates one if you don't have one).
2. Open Keychain Access, find the new "Apple Distribution: ..." certificate, expand it, select both the certificate and its private key, right-click → **Export 2 items…** → save as `dist.p12`, set an export password.
3. Base64-encode it:
   ```bash
   base64 -i dist.p12 | pbcopy
   ```
   Paste as secret `DIST_CERTIFICATE_P12_BASE64`.
4. Set secret `DIST_CERTIFICATE_PASSWORD` to the export password you chose.

## 3. Provisioning profile

1. developer.apple.com/account → Certificates, Identifiers & Profiles → Profiles → **+**.
2. Type: **App Store**. App ID: `com.hdeazy.selectless`. Select the distribution certificate from step 2.
3. Give it a name (e.g. `LessChoice AppStore`) and download the `.mobileprovision` file.
4. Base64-encode it:
   ```bash
   base64 -i LessChoice_AppStore.mobileprovision | pbcopy
   ```
   Paste as secret `PROVISIONING_PROFILE_BASE64`.
5. Set secret `PROVISIONING_PROFILE_NAME` to the **exact profile name** you gave it in step 3 (must match exactly, it's how Xcode picks the profile during export).

## 4. Misc secrets

- `CI_KEYCHAIN_PASSWORD` — any random password (e.g. `openssl rand -hex 16`), just used to protect the temporary CI keychain for the duration of the build.
- `BACKEND_BASE_URL` — `https://lesschoice-backend-798630052741.australia-southeast1.run.app`
- `APP_SHARED_SECRET` — the same production shared secret used to authenticate to the backend (check your local `Config.swift`, or regenerate one on the backend side and update both).

## Triggering a deploy

```bash
git tag v1.0.0
git push origin v1.0.0
```

Or use the "Run workflow" button under the Actions tab for an ad-hoc build
without tagging.

## First-app-record caveat

App Store Connect needs the app record (`com.hdeazy.selectless`) to already
exist under **My Apps** before the first upload will succeed — create it
manually once (My Apps → **+** → New App) before the first CI run.
