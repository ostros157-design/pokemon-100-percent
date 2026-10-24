import 'package:flutter/material.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const team = [
      'Pikachu',
      'Haunter',
      'Venusaur',
      'Charizard',
      'Lapras',
      'Machamp',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Twój Team'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: team.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(team[index]),
              subtitle: const Text(
                'Pokémon w Twojej drużynie',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}