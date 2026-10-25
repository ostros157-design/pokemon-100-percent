# Changelog

Notable project changes are recorded here. Entries distinguish implementation changes from verification; a successful build does not by itself prove runtime behavior.

## Unreleased

### Profile progress and caught Pokémon
- Updated `pokemon100_flutter_prototype/pokemon100/lib/screens/profile_screen.dart` to calculate a global progress percentage from completed guide steps and caught Pokémon, using the currently available guide steps and Pokémon list as the denominator.
- Updated `pokemon100_flutter_prototype/pokemon100/lib/screens/pokemon_details_screen.dart` to let the user mark a Pokémon as caught or uncaught.
- Caught Pokémon IDs are stored in SharedPreferences under `caught_pokemon_ids`.
- Guide completion is stored under keys following `guide_progress_<gameId>_<guideId>`.

### Verification status
- **Manual verification reported by the project owner:** the updated APK installed and opened on the console; the profile/caught-Pokémon changes worked; caught status remained after closing and reopening the app.
- **Build evidence:** `flutter build apk` completed successfully at least once, producing `build/app/outputs/flutter-apk/app-release.apk`.
- **Known issue:** a later build attempt crashed inside the Dart runtime with `Could not start thread DartWorker`. This has not been diagnosed.
- Automated tests and a complete static analysis have not been confirmed as passing.

### Current scope and limitations
- The current guide data includes a Pokémon Let's Go, Pikachu! starter guide; the global percentage covers only the content currently present in the app, not every Pokémon game or all franchise completion goals.
- The Pokédex data currently covers the original 151 Pokémon.
- Achievements are not yet connected to the global progress calculation.
