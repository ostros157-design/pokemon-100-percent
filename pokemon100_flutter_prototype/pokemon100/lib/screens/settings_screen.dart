import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool spoilers = false;
  bool animations = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Pokazuj spoilery'),
            subtitle: const Text(
              'Pozwala wyświetlać informacje o późniejszych wydarzeniach.',
            ),
            value: spoilers,
            onChanged: (value) {
              setState(() {
                spoilers = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Animacje'),
            value: animations,
            onChanged: (value) {
              setState(() {
                animations = value;
              });
            },
          ),
          const Divider(),
          const ListTile(
            title: Text('Wersja aplikacji'),
            subtitle: Text('Pokémon Guide 2.0.0'),
          ),
        ],
      ),
    );
  }
}