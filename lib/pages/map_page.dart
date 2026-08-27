import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool pinSecili = false;

  // Adnan Kahveci Mahallesi
  static const LatLng haritaMerkezi = LatLng(
    41.00148,
    28.627988,
  );

  // Şimdilik sadece deneme pini.
  static const LatLng denemePinKonumu = LatLng(
    41.00148,
    28.627988,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: haritaMerkezi,
          initialZoom: 15.5,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'com.hakan.kargorota.prototype',
          ),

          MarkerLayer(
            markers: [
              Marker(
                point: denemePinKonumu,
                width: 60,
                height: 70,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      pinSecili = !pinSecili;
                    });
                  },
                  child: AnimatedScale(
                    scale: pinSecili ? 1.20 : 1.0,
                    duration: const Duration(
                      milliseconds: 150,
                    ),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 58,
                          color: pinSecili
                              ? colorScheme.primary
                              : colorScheme.secondary,
                        ),

                        Positioned(
                          top: 10,
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black12,
                              ),
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SimpleAttributionWidget(
            source: Text(
              'OpenStreetMap contributors',
            ),
          ),
        ],
      ),
    );
  }
}