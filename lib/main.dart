import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/map_page.dart';

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
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const AnaUygulama(),
    );
  }
}

class AnaUygulama extends StatefulWidget {
  const AnaUygulama({super.key});

  @override
  State<AnaUygulama> createState() => _AnaUygulamaState();
}

class _AnaUygulamaState extends State<AnaUygulama> {
  int seciliSayfa = 0;

  final List<Widget> sayfalar = const [
    HomePage(),
    MapPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: seciliSayfa,
        children: sayfalar,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: seciliSayfa,
        onDestinationSelected: (index) {
          setState(() {
            seciliSayfa = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Kargolar',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
          ),
        ],
      ),
    );
  }
}