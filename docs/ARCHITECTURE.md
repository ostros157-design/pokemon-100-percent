# Current application architecture

This document describes the implementation currently reported for the Flutter prototype. It is not a target architecture or a claim that every planned module is complete.

## Project location

Flutter application root:

`pokemon100_flutter_prototype/pokemon100/`

## Relevant files

| File | Responsibility |
|---|---|
| `lib/data/guides_data.dart` | Available guide data. Currently includes a Pokémon Let's Go, Pikachu! guide with 12 steps. |
| `lib/data/pokemon_data.dart` | Pokédex data for the original 151 Pokémon. |
| `lib/screens/guide_screen.dart` | Guide UI and persistence of completed steps. |
| `lib/screens/profile_screen.dart` | Reads available guide completion and caught-Pokémon data to display aggregate progress. |
| `lib/screens/pokemon_details_screen.dart` | Pokémon details UI and caught/uncaught action. |
| `lib/services/storage_service.dart` | Existing storage service; previously inspected implementation uses in-memory static variables. It should not be assumed to persist data across restarts. |

## Persistence

The current guide screen stores completed step indices in SharedPreferences using keys shaped like:

`guide_progress_<gameId>_<guideId>`

The caught-Pokémon collection is stored in SharedPreferences under:

`caught_pokemon_ids`

The caught-Pokémon collection is global rather than per-game.

The profile calculates progress from two kinds of objectives:
1. Completed guide steps from the guide data currently available in the app.
2. Pokémon marked as caught from the currently available Pokémon list.

The denominator is based on the currently available guide steps plus the Pokémon entries in the app. Consequently, the percentage is not yet a measure of completion across every Pokémon game, every region, or every possible completion goal.

## Current limitations

- The guide catalogue is incomplete and currently contains only the documented Let's Go, Pikachu! guide.
- The Pokédex dataset currently contains 151 Pokémon.
- Achievements are not connected to the profile calculation.
- The in-memory `StorageService` should not be treated as the persistence source for data that must survive restarts; the guide and caught-Pokémon screens currently use SharedPreferences for those specific records.
- Automated tests and full static analysis have not been confirmed as passing.

## Maintenance rule

When architecture or storage behavior changes, update this document in the same change where practical. Document verified behavior separately from planned work and known limitations.
