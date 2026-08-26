import 'package:flutter/material.dart';

void main() {
  runApp(const KargoRotaApp());
}

class KargoRotaApp extends StatelessWidget {
  const KargoRotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kargo Rota',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kargo Dağıtım'),
        ),
        body: const Center(
          child: Text(
            'Bugünkü Kargolar',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}