#!/usr/bin/env python3
"""Convert PokeAPI CSV learnsets into compact JSON for Pokémon 100%.

Inputs are the official PokeAPI CSV files:
  pokemon_moves.csv, pokemon.csv, version_groups.csv, move_names.csv (optional)
Output is a JSON array with one record per learnset row for default Pokémon forms.
The script deliberately preserves version-group and learn-method IDs so the app
can filter by game and distinguish level-up, machine, tutor, egg, and other methods.
"""
import argparse
import csv
import json
from pathlib import Path


def read_csv(path):
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pokemon-moves", required=True, type=Path)
    parser.add_argument("--pokemon", required=True, type=Path)
    parser.add_argument("--version-groups", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--max-dex", type=int, default=1025)
    args = parser.parse_args()

    pokemon_rows = read_csv(args.pokemon)
    default_forms = {}
    for row in pokemon_rows:
        if row.get("is_default") != "1":
            continue
        try:
            pokemon_id = int(row["id"])
            species_id = int(row["species_id"])
        except (ValueError, KeyError):
            continue
        if 1 <= species_id <= args.max_dex:
            default_forms[pokemon_id] = species_id

    version_names = {}
    for row in read_csv(args.version_groups):
        try:
            version_names[int(row["id"])] = row["identifier"]
        except (ValueError, KeyError):
            continue

    # Keep the source IDs and the raw level/method fields; interpretation of
    # method IDs is done by the app so new methods won't be silently discarded.
    output = []
    for row in read_csv(args.pokemon_moves):
        try:
            pokemon_id = int(row["pokemon_id"])
            move_id = int(row["move_id"])
            version_group_id = int(row["version_group_id"])
            method_id = int(row["pokemon_move_method_id"])
            level = int(row.get("level") or 0)
        except (ValueError, KeyError):
            continue
        dex_id = default_forms.get(pokemon_id)
        if dex_id is None:
            continue
        output.append({
            "pokemonId": dex_id,
            "moveId": move_id,
            "versionGroupId": version_group_id,
            "versionGroup": version_names.get(version_group_id, "unknown"),
            "methodId": method_id,
            "level": level,
            "order": int(row["order"]) if (row.get("order") or "").isdigit() else None,
        })

    output.sort(key=lambda item: (
        item["pokemonId"], item["versionGroupId"], item["methodId"],
        item["level"], item["moveId"]
    ))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(output, handle, ensure_ascii=False, separators=(",", ":"))
        handle.write("\n")
    print(f"Saved {len(output):,} learnset rows to {args.output}")
    print(f"Mapped {len(default_forms):,} default Pokémon forms through National Dex #{args.max_dex}.")


if __name__ == "__main__":
    main()
