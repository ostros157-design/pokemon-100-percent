import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameDataPackage {
  final String id, title, assetPath, fileName;
  const GameDataPackage(this.id, this.title, this.assetPath, this.fileName);
}

class GameDataDownloadService {
  static const packages = <GameDataPackage>[
    GameDataPackage('red_blue','Pokémon Red / Blue','assets/data/maps/kanto_audit.json','kanto_audit.json'),
    GameDataPackage('yellow','Pokémon Yellow','assets/data/maps/kanto_audit.json','kanto_audit.json'),
    GameDataPackage('gold_silver','Pokémon Gold / Silver','assets/data/maps/johto_audit.json','johto_audit.json'),
    GameDataPackage('crystal','Pokémon Crystal','assets/data/maps/johto_audit.json','johto_audit.json'),
    GameDataPackage('heart_gold_soul_silver','Pokémon HeartGold / SoulSilver','assets/data/maps/johto_audit.json','johto_audit.json'),
    GameDataPackage('ruby_sapphire','Pokémon Ruby / Sapphire','assets/data/maps/hoenn_audit.json','hoenn_audit.json'),
    GameDataPackage('emerald','Pokémon Emerald','assets/data/maps/hoenn_audit.json','hoenn_audit.json'),
    GameDataPackage('diamond_pearl','Pokémon Diamond / Pearl','assets/data/maps/sinnoh_audit.json','sinnoh_audit.json'),
    GameDataPackage('platinum','Pokémon Platinum','assets/data/maps/sinnoh_audit.json','sinnoh_audit.json'),
    GameDataPackage('black_white','Pokémon Black / White','assets/data/maps/unova_audit.json','unova_audit.json'),
    GameDataPackage('black_2_white_2','Pokémon Black 2 / White 2','assets/data/maps/unova_audit.json','unova_audit.json'),
    GameDataPackage('x_y','Pokémon X / Y','assets/data/maps/kalos_audit.json','kalos_audit.json'),
    GameDataPackage('sun_moon','Pokémon Sun / Moon','assets/data/maps/alola_audit.json','alola_audit.json'),
    GameDataPackage('ultra_sun_ultra_moon','Pokémon Ultra Sun / Ultra Moon','assets/data/maps/alola_audit.json','alola_audit.json'),
    GameDataPackage('lets_go_pikachu','Pokémon: Let’s Go, Pikachu!','assets/data/maps/lets_go_kanto_audit.json','lets_go_kanto_audit.json'),
    GameDataPackage('lets_go_eevee','Pokémon: Let’s Go, Eevee!','assets/data/maps/lets_go_kanto_audit.json','lets_go_kanto_audit.json'),
    GameDataPackage('sword_shield','Pokémon Sword / Shield','assets/data/maps/galar_audit.json','galar_audit.json'),
    GameDataPackage('legends_arceus','Pokémon Legends: Arceus','assets/data/maps/hisui_audit.json','hisui_audit.json'),
    GameDataPackage('scarlet_violet','Pokémon Scarlet / Violet','assets/data/maps/paldea_audit.json','paldea_audit.json'),
  ];
  static const _base = 'https://raw.githubusercontent.com/ostros157-design/pokemon-100-percent/main/pokemon100_flutter_prototype/pokemon100/';
  static const _key = 'downloaded_game_data_packages';
  static Future<Directory> _dir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/game_data');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
  static Future<Set<String>> downloadedPackages() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }
  static Future<String> loadMapJson(String assetPath) async {
    final file = File('${(await _dir()).path}/${assetPath.split('/').last}');
    if (await file.exists()) return file.readAsString();
    return rootBundle.loadString(assetPath);
  }
  static Future<void> download(GameDataPackage pack) async {
    final uri = Uri.parse('$_base${pack.assetPath}');
    final response = await http.get(uri).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}', uri: uri);
    final data = jsonDecode(response.body);
    if (data is! Map || data['locations'] is! List) throw const FormatException('Nieprawidłowe dane mapy.');
    final file = File('${(await _dir()).path}/${pack.fileName}');
    await file.writeAsString(response.body);
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? <String>[]).toSet()..add(pack.id);
    await prefs.setStringList(_key, ids.toList());
  }
}