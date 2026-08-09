# Contributing to Hymnal Tool

Thanks for helping improve Hymnal Tool.

## Before you start

- Search existing issues before filing a new one.
- Keep changes focused and describe the user-facing outcome.
- Do not add copyrighted lyrics or tunes without redistribution permission.
- Include source and rights metadata for every proposed catalog entry.

## Development workflow

1. Install the current stable Flutter SDK.
2. Run `flutter pub get`.
3. Create a branch from `main`.
4. Make the change and add or update tests.
5. Run:

   ```sh
   dart format --output=none --set-exit-if-changed lib test tool
   flutter analyze
   flutter test
   flutter build web --release
   ```

6. Open a pull request explaining what changed and how it was verified.

Please use respectful, constructive language in all project discussions.
