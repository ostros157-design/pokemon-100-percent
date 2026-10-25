# Testing and verification status

Last updated: 2026-10-25

This file records only evidence currently available. A result reported by the project owner is labelled as manual verification; it is not represented as an automated test.

## Manual checks reported by the project owner

| Check | Result | Evidence |
|---|---|---|
| Resolve Flutter dependencies | Passed | Terminal output ended with `Got dependencies!`. |
| Build Android release APK | Passed at least once | Terminal output showed `Built build/app/outputs/flutter-apk/app-release.apk` (48.2 MB). |
| Install and launch updated APK on console | Passed | Project owner confirmed it worked. |
| Profile and caught-Pokémon changes | Passed manually | Project owner confirmed the updated app worked. |
| Caught status survives app restart | Passed manually | Project owner confirmed the Pokémon remained marked after closing and reopening the app. |
| Guide progress survives leaving/re-entering the guide and app restart | Passed in an earlier manual check | Previously reported by the project owner. |

## Known failures and unverified areas

- A later `flutter build apk` attempt crashed in the Dart runtime with `Could not start thread DartWorker`. This is an observed tooling/runtime failure; its cause is unknown and it does not alone prove an application-code defect.
- `flutter doctor` reported that Flutter and Dart are not on PATH. Commands can still be run using the full Flutter SDK path.
- `flutter doctor` reported Android license status as unknown. A later APK build proceeded and accepted required Android SDK component licenses.
- Chrome and Visual Studio were not found. These are not required for an Android APK build unless web or Windows desktop targets are needed.
- The existing `test/widget_test.dart` was previously found to reference a missing `package:pokemon_100/main.dart` / `MyApp`. Automated test status is therefore not confirmed as passing.
- A full `flutter analyze` run has not been confirmed as passing.
- No automated integration test currently proves profile totals, persistence, or cross-module behavior.

## Recommended next checks

1. Run `flutter analyze` and record the exact output; separate existing test-fixture problems from app-source diagnostics.
2. Run `flutter test`; fix or replace the stale widget test before treating the test suite as green.
3. Verify profile totals against a small known example: complete one guide step, catch one Pokémon, and confirm the numerator and percentage change as expected.
4. Verify caught status and guide progress after a full app restart.
5. Repeat the release build once the Dart runtime crash is understood or shown to be transient.

Do not mark a check as passed until its output or a clear manual result is available.
