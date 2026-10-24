
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
WidgetsFlutterBinding.ensureInitialized();

runApp(const PokemonGuideApp());
}

class PokemonGuideApp extends StatelessWidget {
const PokemonGuideApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Pokémon Guide',
theme: ThemeData(
useMaterial3: true,
colorSchemeSeed: Colors.green,
scaffoldBackgroundColor: const Color(0xFFF5F7F5),
appBarTheme: const AppBarTheme(
centerTitle: true,
elevation: 0,
),
),
home: const HomeScreen(),
);
}
}

