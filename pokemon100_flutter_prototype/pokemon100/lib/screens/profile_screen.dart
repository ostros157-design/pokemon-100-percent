import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CircleAvatar(
            radius: 50,
            child: Icon(
              Icons.person,
              size: 55,
            ),
          ),
          SizedBox(height: 24),
          Card(
            child: ListTile(
              title: Text('Postęp'),
              subtitle: Text('0%'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Pokémony złapane'),
              subtitle: Text('0'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Odznaki'),
              subtitle: Text('0'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Osiągnięcia'),
              subtitle: Text('0'),
            ),
          ),
        ],
      ),
    );
  }
}