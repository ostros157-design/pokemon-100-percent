"""Regression tests for the offline Pokémon learnset importer."""
import csv
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("import_pokemon_moves.py")


def write_csv(path, headers, rows):
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=headers)
        writer.writeheader()
        writer.writerows(rows)


class ImporterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.pokemon = self.root / "pokemon.csv"
        self.groups = self.root / "version_groups.csv"
        self.moves = self.root / "pokemon_moves.csv"
        self.output = self.root / "learnsets.json"

        write_csv(self.pokemon, ["id", "species_id", "is_default"], [
            {"id": "25", "species_id": "25", "is_default": "1"},
            {"id": "10025", "species_id": "25", "is_default": "0"},
            {"id": "1", "species_id": "1", "is_default": "1"},
            {"id": "26", "species_id": "26", "is_default": "1"},
        ])
        write_csv(self.groups, ["id", "identifier"], [
            {"id": "1", "identifier": "red-blue"},
        ])
        write_csv(self.moves, [
            "pokemon_id", "version_group_id", "move_id",
            "pokemon_move_method_id", "level", "order",
        ], [
            {"pokemon_id": "25", "version_group_id": "1", "move_id": "84",
             "pokemon_move_method_id": "1", "level": "9", "order": "1"},
            {"pokemon_id": "1", "version_group_id": "1", "move_id": "33",
             "pokemon_move_method_id": "1", "level": "1", "order": "1"},
            {"pokemon_id": "26", "version_group_id": "1", "move_id": "85",
             "pokemon_move_method_id": "1", "level": "15", "order": ""},
        ])

    def tearDown(self):
        self.temp.cleanup()

    def run_importer(self, max_dex="1025"):
        return subprocess.run([
            sys.executable, str(SCRIPT),
            "--pokemon-moves", str(self.moves),
            "--pokemon", str(self.pokemon),
            "--version-groups", str(self.groups),
            "--max-dex", str(max_dex),
            "--output", str(self.output),
        ], capture_output=True, text=True, check=False)

    def test_maps_default_forms_to_national_dex_and_sorts_rows(self):
        result = self.run_importer("25")
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = json.loads(self.output.read_text(encoding="utf-8"))
        self.assertEqual([row["pokemonId"] for row in rows], [1, 25])
        self.assertEqual(rows[1]["versionGroup"], "red-blue")
        self.assertEqual(rows[1]["moveId"], 84)
        self.assertEqual(rows[1]["order"], 1)

    def test_rejects_non_positive_dex_limit(self):
        result = self.run_importer("0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--max-dex must be at least 1", result.stderr)
        self.assertFalse(self.output.exists())

    def test_rejects_empty_source_csv(self):
        self.moves.write_text("pokemon_id,version_group_id,move_id,pokemon_move_method_id,level,order\n",
                              encoding="utf-8")
        result = self.run_importer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("is empty", result.stderr)
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
