import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/kargo_store.dart';
import '../services/geocoding_service.dart';
import '../services/verified_address_service.dart';

class MapPage extends StatefulWidget {
  final int? ilkSeciliTeslimatId;
  final bool pinOlusturmaModu;

  const MapPage({
    super.key,
    this.ilkSeciliTeslimatId,
    this.pinOlusturmaModu = false,
  });

  @override
  State<MapPage> createState() =>
      _MapPageState();
}

class _MapPageState
    extends State<MapPage> {
  int? seciliTeslimatId;

  static const LatLng haritaMerkezi =
      LatLng(
    41.00148,
    28.627988,
  );

  final GeocodingService
      _geocodingService =
      GeocodingService.instance;

  final VerifiedAddressService
      _verifiedAddressService =
      VerifiedAddressService.instance;

  bool _konumDuzeltmeModu =
      false;

  final Set<int>
      _konumuBulunamayanTeslimatlar =
      {};

  final Map<int, String>
      _bilinenAdresler = {};

  bool _konumlandirmaCalisiyor =
      false;



  String? _sonKonumlandirmaHatasi;

  @override
  void initState() {
    super.initState();

    seciliTeslimatId =
        widget.ilkSeciliTeslimatId;

    _konumDuzeltmeModu =
        widget.pinOlusturmaModu &&
            widget.ilkSeciliTeslimatId !=
                null;

    if (_konumDuzeltmeModu) {
      // Kullanıcı bu teslimat için manuel pin oluşturmak
      // istedi. Otomatik geocoding aynı teslimata tekrar
      // müdahale etmesin.
      _konumuBulunamayanTeslimatlar.add(
        widget.ilkSeciliTeslimatId!,
      );
    }

    _adresleriKaydet();

    kargoStore.addListener(
      _storeDegisti,
    );

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        _eksikKonumlariCoz();
      },
    );
  }

  @override
  void dispose() {
    kargoStore.removeListener(
      _storeDegisti,
    );

    super.dispose();
  }

  void _adresleriKaydet() {
    for (final grup
        in kargoStore
            .teslimatGruplari) {
      _bilinenAdresler[
              grup.teslimatId] =
          grup.adres;
    }
  }

  void _storeDegisti() {
    final gruplar =
        kargoStore.teslimatGruplari;

    final mevcutTeslimatIdleri =
        gruplar
            .map(
              (grup) =>
                  grup.teslimatId,
            )
            .toSet();

    _konumuBulunamayanTeslimatlar
        .removeWhere(
      (teslimatId) =>
          !mevcutTeslimatIdleri
              .contains(
        teslimatId,
      ),
    );

    _bilinenAdresler.removeWhere(
      (teslimatId, _) =>
          !mevcutTeslimatIdleri
              .contains(
        teslimatId,
      ),
    );

    for (final grup in gruplar) {
      final oncekiAdres =
          _bilinenAdresler[
              grup.teslimatId];

      if (oncekiAdres != null &&
          oncekiAdres != grup.adres) {
        _konumuBulunamayanTeslimatlar
            .remove(
          grup.teslimatId,
        );

        _geocodingService
            .onbellektenSil(
          oncekiAdres,
        );
      }

      _bilinenAdresler[
              grup.teslimatId] =
          grup.adres;
    }

    _eksikKonumlariCoz();
  }

  TeslimatGrubu?
      _siradakiKonumsuzGrubuBul() {
    for (final grup
        in kargoStore
            .teslimatGruplari) {
      if (grup.konumuVar) {
        continue;
      }

      if (_konumuBulunamayanTeslimatlar
          .contains(
        grup.teslimatId,
      )) {
        continue;
      }

      return grup;
    }

    return null;
  }

  Future<void>
      _eksikKonumlariCoz() async {
    if (_konumlandirmaCalisiyor ||
        !mounted) {
      return;
    }

    _konumlandirmaCalisiyor = true;

    if (mounted) {
      setState(() {});
    }

    try {
      while (mounted) {
        final hedefGrup =
            _siradakiKonumsuzGrubuBul();

        if (hedefGrup == null) {
          break;
        }

        final arananTeslimatId =
            hedefGrup.teslimatId;

        final arananAdres =
            hedefGrup.adres;



        _sonKonumlandirmaHatasi =
            null;

        if (mounted) {
          setState(() {});
        }

        try {
          final sonuc =
              await _geocodingService
                  .adresiBul(
            arananAdres,
          );

          if (!mounted) {
            return;
          }

          final guncelGruplar =
              kargoStore
                  .teslimatGruplari;

          TeslimatGrubu?
              guncelGrup;

          for (final grup
              in guncelGruplar) {
            if (grup.teslimatId ==
                arananTeslimatId) {
              guncelGrup = grup;
              break;
            }
          }

          if (guncelGrup == null) {
            continue;
          }

          // Geocoding sürerken kullanıcı adresi
          // değiştirmiş olabilir. Eski sonucun
          // yeni adrese yazılmasını engelliyoruz.
          if (guncelGrup.adres !=
              arananAdres) {
            continue;
          }

          if (sonuc == null) {
            _konumuBulunamayanTeslimatlar
                .add(
              arananTeslimatId,
            );
          } else {
            kargoStore.konumGuncelle(
              guncelGrup,
              latitude:
                  sonuc.latitude,
              longitude:
                  sonuc.longitude,
              konumDogrulugu:
                  sonuc.dogruluk,
              konumKaynagi:
                  sonuc.kaynak,
            );
          }
        } catch (e) {
          _konumuBulunamayanTeslimatlar
              .add(
            arananTeslimatId,
          );

          _sonKonumlandirmaHatasi =
              'Konum servisine ulaşılamadı.';
        }

        if (mounted) {
          setState(() {});
        }
      }
    } finally {
      _konumlandirmaCalisiyor =
          false;


      if (mounted) {
        setState(() {});
      }
    }
  }

  void _basarisizKonumlariTekrarDene() {
    final gruplar =
        kargoStore.teslimatGruplari;

    for (final grup in gruplar) {
      if (_konumuBulunamayanTeslimatlar
          .contains(
        grup.teslimatId,
      )) {
        _geocodingService
            .onbellektenSil(
          grup.adres,
        );
      }
    }

    setState(() {
      _konumuBulunamayanTeslimatlar
          .clear();

      _sonKonumlandirmaHatasi =
          null;
    });

    _eksikKonumlariCoz();
  }

  TeslimatGrubu? _seciliGrubuBul(
    List<TeslimatGrubu> gruplar,
  ) {
    if (seciliTeslimatId == null) {
      return null;
    }

    for (final grup in gruplar) {
      if (grup.teslimatId ==
          seciliTeslimatId) {
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
          title: const Text(
            'Teslim Edildi',
          ),
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
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Hayır',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Evet',
              ),
            ),
          ],
        );
      },
    );

    if (onay == true) {
      kargoStore.teslimEt(
        grup,
      );
    }
  }

  Future<void> _teslimatiGeriAl(
    TeslimatGrubu grup,
  ) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Teslimatı Geri Al',
          ),
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
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Hayır',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Evet',
              ),
            ),
          ],
        );
      },
    );

    if (onay == true) {
      kargoStore
          .teslimatiGeriAl(
        grup,
      );
    }
  }

  void _konumDuzeltmeyiBaslat(
    TeslimatGrubu grup,
  ) {
    setState(() {
      seciliTeslimatId =
          grup.teslimatId;

      _konumDuzeltmeModu =
          true;
    });
  }

  void _konumDuzeltmeyiIptalEt() {
    setState(() {
      _konumDuzeltmeModu =
          false;
    });
  }

  Future<void> _haritadaKonumSecildi(
    LatLng nokta,
  ) async {
    if (!_konumDuzeltmeModu ||
        seciliTeslimatId == null) {
      return;
    }

    final grup = _seciliGrubuBul(
      kargoStore.teslimatGruplari,
    );

    if (grup == null) {
      return;
    }

    final onay =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Pin Konumunu Kaydet',
          ),
          content: Text(
            '${grup.adres}\n\n'
            'Seçtiğin nokta bu adresin '
            'doğru bina konumu olarak kaydedilecek.\n\n'
            'Bu adres tekrar geldiğinde uygulama '
            'artık bu konumu doğrudan kullanacak.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'İptal',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Kaydet',
              ),
            ),
          ],
        );
      },
    );

    if (onay != true ||
        !mounted) {
      return;
    }

    await _verifiedAddressService
        .kaydet(
      grup.adres,
      latitude:
          nokta.latitude,
      longitude:
          nokta.longitude,
    );

    _geocodingService
        .onbellektenSil(
      grup.adres,
    );

    kargoStore.konumGuncelle(
      grup,
      latitude:
          nokta.latitude,
      longitude:
          nokta.longitude,
      konumDogrulugu:
          KonumDogrulugu
              .kullaniciDogruladi,
      konumKaynagi:
          KonumKaynagi.kurye,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _konumuBulunamayanTeslimatlar.remove(
        grup.teslimatId,
      );

      _sonKonumlandirmaHatasi =
          null;

      _konumDuzeltmeModu =
          false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Adres konumu doğrulandı ve kaydedildi.',
        ),
      ),
    );
  }

  Widget _konumDuzeltmeRozeti(
    BuildContext context,
  ) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(
            alpha: 0.96,
          ),
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      elevation: 3,
      child: InkWell(
        onTap:
            _konumDuzeltmeyiIptalEt,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child: const Padding(
          padding:
              EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                size: 18,
              ),
              SizedBox(
                width: 7,
              ),
              Flexible(
                child: Text(
                  'Doğru binanın üzerine dokun • İptal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _konumDurumRozeti(
    BuildContext context,
  ) {
    final gruplar =
        kargoStore.teslimatGruplari;

    final konumluSayisi = gruplar
        .where(
          (grup) => grup.konumuVar,
        )
        .length;

    final basarisizSayisi =
        _konumuBulunamayanTeslimatlar
            .length;

    String metin;
    IconData ikon;
    VoidCallback? onTap;

    if (_konumlandirmaCalisiyor) {
      metin =
          'Adresler konumlandırılıyor '
          '($konumluSayisi/${gruplar.length})';

      ikon = Icons.location_searching;
    } else if (basarisizSayisi > 0) {
      metin =
          '$basarisizSayisi adres bulunamadı'
          ' • Tekrar dene';

      ikon =
          Icons.location_off_outlined;

      onTap =
          _basarisizKonumlariTekrarDene;
    } else if (_sonKonumlandirmaHatasi !=
        null) {
      metin =
          _sonKonumlandirmaHatasi!;

      ikon = Icons.wifi_off_outlined;

      onTap =
          _basarisizKonumlariTekrarDene;
    } else {
      metin =
          'Adresler konumlandırıldı';

      ikon =
          Icons.location_on_outlined;
    }

    return Material(
      color: Theme.of(context)
          .colorScheme
          .surface
          .withValues(
            alpha: 0.94,
          ),
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                ikon,
                size: 17,
              ),
              const SizedBox(
                width: 7,
              ),
              Flexible(
                child: Text(
                  metin,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _ayniKoordinattaMi(
    TeslimatGrubu birinci,
    TeslimatGrubu ikinci,
  ) {
    if (!birinci.konumuVar ||
        !ikinci.konumuVar) {
      return false;
    }

    // Yaklaşık 10 cm'lik tolerans.
    // Aynı bina için servislerin ürettiği çok küçük
    // ondalık farklar yüzünden iki ayrı pin sayılmasını
    // engelliyoruz.
    const double tolerans = 0.000001;

    return (birinci.latitude! -
                    ikinci.latitude!)
                .abs() <=
            tolerans &&
        (birinci.longitude! -
                    ikinci.longitude!)
                .abs() <=
            tolerans;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: kargoStore,
      builder: (context, child) {
        final gruplar =
            kargoStore
                .teslimatGruplari;

        final seciliGrup =
            _seciliGrubuBul(
          gruplar,
        );

        final konumluGruplar = gruplar
            .where(
              (grup) =>
                  grup.konumuVar,
            )
            .toList();

        // Aynı koordinata düşen teslimatları haritada tek pin olarak
        // gösteriyoruz. Pinin içindeki sayı home_page listesindeki sırayı,
        // alttaki üçgen ise o fiziksel noktadaki toplam kargo adedini gösterir.
        final markers = <Marker>[];
        final islenenTeslimatIdleri = <int>{};

        for (final grup in konumluGruplar) {
          if (islenenTeslimatIdleri.contains(grup.teslimatId)) {
            continue;
          }

          final ayniKonumdakiGruplar = konumluGruplar
              .where(
                (digerGrup) => _ayniKoordinattaMi(
                  grup,
                  digerGrup,
                ),
              )
              .toList();

          islenenTeslimatIdleri.addAll(
            ayniKonumdakiGruplar.map(
              (digerGrup) => digerGrup.teslimatId,
            ),
          );

          final toplamKargoAdedi = ayniKonumdakiGruplar.fold<int>(
            0,
            (toplam, digerGrup) => toplam + digerGrup.adet,
          );

          final konumdakiTumKargolarTeslimEdildi =
              ayniKonumdakiGruplar.every(
            (digerGrup) => digerGrup.teslimEdildi,
          );

          final konumSecili = ayniKonumdakiGruplar.any(
            (digerGrup) => digerGrup.teslimatId == seciliTeslimatId,
          );

          // Aynı konumda birden fazla teslimat varsa pin numarası,
          // home_page'de o konumdaki ilk teslimatın sıra numarasıdır.
          final sira = ayniKonumdakiGruplar
                  .map(
                    (digerGrup) => gruplar.indexWhere(
                      (listeGrubu) =>
                          listeGrubu.teslimatId == digerGrup.teslimatId,
                    ),
                  )
                  .where((index) => index >= 0)
                  .reduce((a, b) => a < b ? a : b) +
              1;

          final pinGrubu = konumSecili
              ? ayniKonumdakiGruplar.firstWhere(
                  (digerGrup) =>
                      digerGrup.teslimatId == seciliTeslimatId,
                  orElse: () => ayniKonumdakiGruplar.first,
                )
              : ayniKonumdakiGruplar.first;

          markers.add(
            _pinOlustur(
              context,
              grup: pinGrubu,
              sira: sira,
              toplamKargoAdedi: toplamKargoAdedi,
              konumdakiTumKargolarTeslimEdildi:
                  konumdakiTumKargolarTeslimEdildi,
              konumSecili: konumSecili,
              konum: LatLng(
                grup.latitude!,
                grup.longitude!,
              ),
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      options:
                          MapOptions(
                        initialCenter:
                            haritaMerkezi,
                        initialZoom:
                            15.5,
                        onTap:
                            (tapPosition, point) {
                          if (_konumDuzeltmeModu) {
                            _haritadaKonumSecildi(
                              point,
                            );
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.hakan.kargorota.prototype',
                        ),
                        MarkerLayer(
                          markers:
                              markers,
                        ),
                        const SimpleAttributionWidget(
                          source: Text(
                            'OpenStreetMap contributors',
                          ),
                        ),
                      ],
                    ),
                    if (gruplar.isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Align(
                          alignment:
                              Alignment
                                  .topCenter,
                          child:
                              _konumDuzeltmeModu
                                  ? _konumDuzeltmeRozeti(
                                      context,
                                    )
                                  : _konumDurumRozeti(
                                      context,
                                    ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  18,
                  16,
                  18,
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Theme.of(context)
                          .colorScheme
                          .surface,
                  border:
                      const Border(
                    top: BorderSide(
                      color:
                          Colors.black12,
                    ),
                  ),
                ),
                child:
                    seciliGrup == null
                        ? _pinSecilmediAlani(
                            context,
                          )
                        : _kargoBilgiKarti(
                            context,
                            seciliGrup,
                            gruplar
                                    .indexWhere(
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
    required int toplamKargoAdedi,
    required bool konumdakiTumKargolarTeslimEdildi,
    required bool konumSecili,
    required LatLng konum,
  }) {
    final secili = konumSecili;
    final teslimEdildi =
        konumdakiTumKargolarTeslimEdildi;
    final colorScheme = Theme.of(context).colorScheme;

    final Color temelPinRengi;

    if (teslimEdildi) {
      temelPinRengi = Colors.green;
    } else if (secili) {
      temelPinRengi = colorScheme.primary;
    } else {
      temelPinRengi = colorScheme.secondary;
    }

    // Kullanıcı kapı numarası verdiği halde yalnızca
    // cadde/sokak seviyesi bulunabildiyse pini aynı
    // rengin daha açık tonunda gösteriyoruz.
    final pinRengi = grup.konumYaklasik
        ? Color.lerp(
              temelPinRengi,
              Colors.white,
              0.45,
            ) ??
            temelPinRengi
        : temelPinRengi;

    const double markerWidth = 72;
    const double markerHeight = 106;

    final pinAnchor = Marker.computePixelAlignment(
      width: markerWidth,
      height: markerHeight,
      left: markerWidth / 2,
      top: 57,
    );

    return Marker(
      point: konum,
      width: markerWidth,
      height: markerHeight,
      alignment: pinAnchor,
      child: GestureDetector(
        onTap: () {
          setState(() {
            seciliTeslimatId = grup.teslimatId;
          });
        },
        child: AnimatedScale(
          scale: secili ? 1.20 : 1.0,
          alignment: pinAnchor,
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
                  child: Text(
                    '$sira',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: sira >= 100
                          ? 9
                          : sira >= 10
                              ? 11
                              : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (toplamKargoAdedi > 1)
                Positioned(
                  top: 57,
                  child: _KargoAdetUcgeni(
                    adet: toplamKargoAdedi,
                    renk: temelPinRengi,
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
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              if (_konumDuzeltmeModu &&
                  seciliTeslimatId ==
                      grup.teslimatId) {
                _konumDuzeltmeyiIptalEt();
              } else {
                _konumDuzeltmeyiBaslat(
                  grup,
                );
              }
            },
            icon: Icon(
              _konumDuzeltmeModu &&
                      seciliTeslimatId ==
                          grup.teslimatId
                  ? Icons.close
                  : Icons.edit_location_alt_outlined,
            ),
            label: Text(
              _konumDuzeltmeModu &&
                      seciliTeslimatId ==
                          grup.teslimatId
                  ? 'Konum Düzeltmeyi İptal Et'
                  : 'Pin Konumunu Düzelt',
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
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

// ----------------------------------------------------
// HARİTA PİNİ KARGO ADET ÜÇGENİ
// ----------------------------------------------------

class _KargoAdetUcgeni extends StatelessWidget {
  final int adet;
  final Color renk;

  const _KargoAdetUcgeni({
    required this.adet,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.change_history,
            size: 44,
            color: renk,
          ),
          Align(
            alignment: const Alignment(0, 0.28),
            child: Text(
              '$adet',
              style: TextStyle(
                color: Colors.black,
                fontSize: adet >= 100
                    ? 9
                    : adet >= 10
                        ? 11
                        : 14,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
