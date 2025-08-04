# How to Publish to pub.dev

Here are the steps to publish your Flutter package to [pub.dev](https://pub.dev).

## 1. Update `pubspec.yaml`

Before publishing, make sure your `pubspec.yaml` file is complete. The following fields are particularly important:

*   `name`: The name of your package.
*   `description`: A short description of what your package does.
*   `version`: The version number of your package. Follow [semantic versioning](https://semver.org/).
*   `homepage`: A URL to the homepage of your package (usually the GitHub repository).
*   `repository`: A URL to the source code repository of your package.

I have already updated your `pubspec.yaml` with placeholder values for `homepage` and `repository`. **You must change these to your actual repository URL.**

## 2. Update `CHANGELOG.md`

For each new version you publish, you should add an entry to your `CHANGELOG.md` file. This file should describe the changes made in the new version.

Example `CHANGELOG.md`:

```markdown
## 0.0.1

* Initial release of the smart phone number field.
```

## 3. Check for a `LICENSE` file

Make sure you have a `LICENSE` file in the root of your project. This is important for legal reasons and is required by pub.dev. You can choose a license like MIT, BSD, or Apache.

## 4. Run the Dry Run

Before you publish, it's a good idea to run the publish command with the `--dry-run` flag. This will analyze your package and let you know if there are any issues that would prevent you from publishing, without actually publishing it.

```bash
flutter pub publish --dry-run
```

This command will check for things like a complete `pubspec.yaml`, a `CHANGELOG.md` file, and a `LICENSE` file.

## 5. Publish the Package

Once the dry run completes without any errors, you can publish your package for real.

```bash
flutter pub publish
```

This command will ask you to confirm that you want to publish, and then it will upload your package to pub.dev. You will need to be logged in with your Google account. If you are not logged in, the command will provide you with a URL to log in.

That's it! Your package will now be available on pub.dev.
