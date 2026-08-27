import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/kargo_store.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int? seciliTeslimatId;

  static const LatLng haritaMerkezi = LatLng(
    41.00148,
    28.627988,
  );

  LatLng _geciciPinKonumu(int index) {
    const sutunSayisi = 5;
    const latAralik = 0.00115;
    const lngAralik = 0.00145;

    final satir = index ~/ sutunSayisi;
    final sutun = index % sutunSayisi;

    final latOffset = (satir - 2) * latAralik;
    final lngOffset = (sutun - 2) * lngAralik;

    return LatLng(
      haritaMerkezi.latitude + latOffset,
      haritaMerkezi.longitude + lngOffset,
    );
  }

  TeslimatGrubu? _seciliGrubuBul(
    List<TeslimatGrubu> gruplar,
  ) {
    if (seciliTeslimatId == null) {
      return null;
    }

    for (final grup in gruplar) {
      if (grup.teslimatId == seciliTeslimatId) {
        return grup;
      }
    }

    return null;
  }

  Future<void> _teslimEt(
    TeslimatGrubu grup,
  ) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Teslim Edildi'),
          content: Text(
            grup.adet > 1
                ? '${grup.adet} adet kargoyu teslim edildi olarak '
                    'işaretlemek istediğine emin misin?'
                : 'Bu kargoyu teslim edildi olarak '
                    'işaretlemek istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Hayır'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );

    if (onay == true) {
      kargoStore.teslimEt(grup);
    }
  }

  Future<void> _teslimatiGeriAl(
    TeslimatGrubu grup,
  ) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Teslimatı Geri Al'),
          content: Text(
            grup.adet > 1
                ? '${grup.adet} adet kargoyu tekrar bekleyen duruma '
                    'almak istediğine emin misin?'
                : 'Bu kargoyu tekrar bekleyen duruma almak '
                    'istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Hayır'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );

    if (onay == true) {
      kargoStore.teslimatiGeriAl(grup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: kargoStore,
      builder: (context, child) {
        final gruplar = kargoStore.teslimatGruplari;
        final seciliGrup = _seciliGrubuBul(gruplar);

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
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
                          markers: gruplar
                              .asMap()
                              .entries
                              .map(
                                (entry) => _pinOlustur(
                                  context,
                                  grup: entry.value,
                                  sira: entry.key + 1,
                                  konum: _geciciPinKonumu(
                                    entry.key,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SimpleAttributionWidget(
                          source: Text(
                            'OpenStreetMap contributors',
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 6,
                                  color: Colors.black12,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Pin konumları şimdilik geçici',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  18,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: const Border(
                    top: BorderSide(
                      color: Colors.black12,
                    ),
                  ),
                ),
                child: seciliGrup == null
                    ? _pinSecilmediAlani(context)
                    : _kargoBilgiKarti(
                        context,
                        seciliGrup,
                        gruplar.indexWhere(
                              (grup) =>
                                  grup.teslimatId ==
                                  seciliGrup.teslimatId,
                            ) +
                            1,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Marker _pinOlustur(
    BuildContext context, {
    required TeslimatGrubu grup,
    required int sira,
    required LatLng konum,
  }) {
    final secili = grup.teslimatId == seciliTeslimatId;
    final teslimEdildi = grup.teslimEdildi;
    final colorScheme = Theme.of(context).colorScheme;

    final Color pinRengi;

    if (teslimEdildi) {
      pinRengi = Colors.green;
    } else if (secili) {
      pinRengi = colorScheme.primary;
    } else {
      pinRengi = colorScheme.secondary;
    }

    return Marker(
      point: konum,
      width: 72,
      height: 82,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          setState(() {
            seciliTeslimatId = grup.teslimatId;
          });
        },
        child: AnimatedScale(
          scale: secili ? 1.20 : 1.0,
          duration: const Duration(
            milliseconds: 150,
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Icon(
                Icons.location_on,
                size: 62,
                color: pinRengi,
              ),
              Positioned(
                top: 11,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black12,
                    ),
                  ),
                  child: teslimEdildi
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.green,
                        )
                      : Text(
                          '$sira',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: sira >= 10 ? 11 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pinSecilmediAlani(BuildContext context) {
    if (kargoStore.teslimatGruplari.isEmpty) {
      return SizedBox(
        height: 105,
        child: Center(
          child: Text(
            'Henüz kargo yok.',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 105,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Kargo bilgilerini görmek için bir pine dokun',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kargoBilgiKarti(
    BuildContext context,
    TeslimatGrubu grup,
    int sira,
  ) {
    final teslimEdildi = grup.teslimEdildi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: teslimEdildi
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: teslimEdildi
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 26,
                    )
                  : Text(
                      '$sira',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grup.alici.isEmpty
                        ? '#${grup.ilkKargo.id.toString().padLeft(3, '0')}'
                        : grup.alici,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    grup.adres,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  if (grup.adet > 1) ...[
                    const SizedBox(height: 7),
                    Text(
                      '${grup.adet} adet kargosu bulunmaktadır',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (grup.not.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              grup.not,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: teslimEdildi
              ? OutlinedButton.icon(
                  onPressed: () {
                    _teslimatiGeriAl(grup);
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Teslimatı Geri Al',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : FilledButton.icon(
                  onPressed: () {
                    _teslimEt(grup);
                  },
                  icon: const Icon(
                    Icons.check_circle_outline,
                  ),
                  label: const Text(
                    'Teslim Edildi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
