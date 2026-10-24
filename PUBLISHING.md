# Publishing to pub.dev

Releases are published by GitHub Actions using
[pub.dev automated publishing](https://dart.dev/tools/pub/automated-publishing).
No pub.dev credentials are stored in the repository: the workflow authenticates
with a short-lived OIDC token issued by GitHub.

## One-time setup

1. Open <https://pub.dev/packages/smart_phone_numb/admin> while signed in as an
   uploader of the package.
2. Under **Automated publishing**, click **Enable publishing from GitHub Actions** and set:
   - **Repository**: `madhudus/smart_phone_numb`
   - **Tag pattern**: `v{{version}}`
   - Optionally tick **Require GitHub Actions environment** and enter `pub.dev`.
     The publish workflow runs in that environment, so you can add required
     reviewers to it under **Settings → Environments** on GitHub.

## Releasing a new version

1. Bump `version` in `pubspec.yaml` and add an entry at the top of `CHANGELOG.md`.
2. Run the same checks as CI:

   ```bash
   flutter pub get
   dart format --set-exit-if-changed .
   flutter analyze
   flutter test
   flutter pub publish --dry-run
   ```

3. Merge the change to `main`.
4. Tag the release commit and push the tag:

   ```bash
   git tag v0.3.0
   git push origin v0.3.0
   ```

The [Publish to pub.dev](.github/workflows/publish.yml) workflow checks that the
tag matches the pubspec version, runs analysis and tests, and publishes.
Progress is visible in the repository's **Actions** tab.

## Manual fallback

If automated publishing is unavailable, publish from a local machine:

```bash
flutter pub publish
```
