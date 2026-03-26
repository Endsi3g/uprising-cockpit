import 'package:flutter/material.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails Client')),
      body: const Center(child: Text('Profil Client en développement')),
    );
  }
}
