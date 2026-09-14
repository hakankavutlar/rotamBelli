import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum KargoDurumu {
  pending,
  delivered,
  skipped,
}

enum KonumDogrulugu {
  kullaniciDogruladi,
  tam,
  yaklasik,
}

enum KonumKaynagi {
  kurye,
  osm,
  google,
}

KargoDurumu _kargoDurumuOku(
  String? deger,
) {
  return KargoDurumu.values.firstWhere(
    (durum) => durum.name == deger,
    orElse: () => KargoDurumu.pending,
  );
}

KonumDogrulugu? _konumDogruluguOku(
  String? deger,
) {
  if (deger == null) {
    return null;
  }

  for (final dogruluk
      in KonumDogrulugu.values) {
    if (dogruluk.name == deger) {
      return dogruluk;
    }
  }

  return null;
}

KonumKaynagi? _konumKaynagiOku(
  String? deger,
) {
  if (deger == null) {
    return null;
  }

  for (final kaynak
      in KonumKaynagi.values) {
    if (kaynak.name == deger) {
      return kaynak;
    }
  }

  return null;
}

class Kargo {
  final int id;
  final int teslimatId;
  final String alici;

  String adres;
  String not;
  KargoDurumu durum;

  double? latitude;
  double? longitude;
  KonumDogrulugu? konumDogrulugu;
  KonumKaynagi? konumKaynagi;

  Kargo({
    required this.id,
    required this.teslimatId,
    required this.alici,
    required this.adres,
    this.not = '',
    this.durum = KargoDurumu.pending,
    this.latitude,
    this.longitude,
    this.konumDogrulugu,
    this.konumKaynagi,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teslimatId': teslimatId,
      'alici': alici,
      'adres': adres,
      'not': not,
      'durum': durum.name,
      'latitude': latitude,
      'longitude': longitude,
      'konumDogrulugu':
          konumDogrulugu?.name,
      'konumKaynagi':
          konumKaynagi?.name,
    };
  }

  factory Kargo.fromJson(
    Map<String, dynamic> json,
  ) {
    return Kargo(
      id: (json['id'] as num).toInt(),
      teslimatId:
          (json['teslimatId'] as num)
              .toInt(),
      alici: json['alici'] as String? ??
          '',
      adres: json['adres'] as String? ??
          '',
      not: json['not'] as String? ?? '',
      durum: _kargoDurumuOku(
        json['durum'] as String?,
      ),
      latitude:
          (json['latitude'] as num?)
              ?.toDouble(),
      longitude:
          (json['longitude'] as num?)
              ?.toDouble(),
      konumDogrulugu:
          _konumDogruluguOku(
        json['konumDogrulugu']
            as String?,
      ),
      konumKaynagi:
          _konumKaynagiOku(
        json['konumKaynagi']
            as String?,
      ),
    );
  }
}

class TeslimatGrubu {
  final List<Kargo> kargolar;

  TeslimatGrubu({
    required this.kargolar,
  });

  Kargo get ilkKargo =>
      kargolar.first;

  int get adet =>
      kargolar.length;

  int get teslimatId =>
      ilkKargo.teslimatId;

  String get alici =>
      ilkKargo.alici;

  String get adres =>
      ilkKargo.adres;

  String get not =>
      ilkKargo.not;

  double? get latitude =>
      ilkKargo.latitude;

  double? get longitude =>
      ilkKargo.longitude;

  KonumDogrulugu?
      get konumDogrulugu =>
          ilkKargo
              .konumDogrulugu;

  KonumKaynagi?
      get konumKaynagi =>
          ilkKargo.konumKaynagi;

  bool get konumuVar {
    return latitude != null &&
        longitude != null;
  }

  bool get konumYaklasik {
    return konumDogrulugu ==
        KonumDogrulugu.yaklasik;
  }

  bool get kuryeDogruladi {
    return konumDogrulugu ==
            KonumDogrulugu
                .kullaniciDogruladi &&
        konumKaynagi ==
            KonumKaynagi.kurye;
  }

  bool get teslimEdildi {
    return kargolar.every(
      (kargo) =>
          kargo.durum ==
          KargoDurumu.delivered,
    );
  }
}

class KargoStore
    extends ChangeNotifier {
  static const String _depolamaAnahtari =
      'rotam_belli_kargolar_v1';

  final SharedPreferencesAsync
      _preferences =
      SharedPreferencesAsync();

  /// Tüm ekranlar bu listeyi kullanmaya devam eder.
  /// Uygulama açılırken [yukle] bu listeyi doldurur.
  final List<Kargo> kargolar = [];

  /// Çok sayıda pin peş peşe güncellendiğinde
  /// disk yazmalarının sırası bozulmasın.
  Future<void> _kayitZinciri =
      Future<void>.value();

  List<Kargo>
      _varsayilanKargolar() {
    return [
      Kargo(
        id: 1,
        teslimatId: 1,
        alici: '',
        adres:
            'Anadolu Cad. No:15',
      ),
      Kargo(
        id: 2,
        teslimatId: 2,
        alici: '',
        adres:
            'Çambaşı Cad. No:22',
      ),
      Kargo(
        id: 3,
        teslimatId: 3,
        alici: '',
        adres:
            'Atatürk Bulvarı No:8',
      ),
      Kargo(
        id: 4,
        teslimatId: 4,
        alici: '',
        adres:
            'Avrupa Cad. No:36',
      ),
      Kargo(
        id: 5,
        teslimatId: 5,
        alici: '',
        adres:
            'Kurtuluş Cad. No:12',
      ),
    ];
  }

  /// UYGULAMA AÇILIRKEN BİR KEZ ÇAĞRILMALI.
  ///
  /// Kayıt varsa onu yükler.
  /// İlk çalıştırmaysa varsayılan kargoları koyar
  /// ve onları da diske yazar.
  Future<void> yukle() async {
    try {
      final kayitliMetin =
          await _preferences.getString(
        _depolamaAnahtari,
      );

      if (kayitliMetin == null ||
          kayitliMetin.isEmpty) {
        kargolar
          ..clear()
          ..addAll(
            _varsayilanKargolar(),
          );

        await _kaydetSirayaAl();

        notifyListeners();
        return;
      }

      final decoded =
          jsonDecode(kayitliMetin);

      List<dynamic> hamKargolar;

      if (decoded
          is Map<String, dynamic>) {
        final deger =
            decoded['kargolar'];

        hamKargolar =
            deger is List
                ? deger
                : <dynamic>[];
      } else if (decoded is List) {
        // Eski bir liste formatına karşı
        // geriye dönük uyumluluk.
        hamKargolar = decoded;
      } else {
        throw const FormatException(
          'Kayıt formatı geçersiz.',
        );
      }

      final yuklenenKargolar =
          <Kargo>[];

      for (final hamKargo
          in hamKargolar) {
        if (hamKargo is! Map) {
          continue;
        }

        yuklenenKargolar.add(
          Kargo.fromJson(
            Map<String, dynamic>.from(
              hamKargo,
            ),
          ),
        );
      }

      kargolar
        ..clear()
        ..addAll(
          yuklenenKargolar,
        );

      notifyListeners();
    } catch (hata, stackTrace) {
      debugPrint(
        'Kargo verileri yüklenemedi: '
        '$hata',
      );
      debugPrintStack(
        stackTrace: stackTrace,
      );

      // Bozuk kayıt yüzünden uygulama
      // tamamen kullanılamaz hale gelmesin.
      kargolar
        ..clear()
        ..addAll(
          _varsayilanKargolar(),
        );

      notifyListeners();
    }
  }

  String _anlikVeriyiJsonaCevir() {
    return jsonEncode(
      {
        'surum': 1,
        'kargolar': kargolar
            .map(
              (kargo) =>
                  kargo.toJson(),
            )
            .toList(),
      },
    );
  }

  /// Her yazma işlemi bir öncekinin bitmesini bekler.
  Future<void> _kaydetSirayaAl() {
    final anlikJson =
        _anlikVeriyiJsonaCevir();

    _kayitZinciri =
        _kayitZinciri.then(
      (_) async {
        await _preferences.setString(
          _depolamaAnahtari,
          anlikJson,
        );
      },
    ).catchError(
      (
        Object hata,
        StackTrace stackTrace,
      ) {
        debugPrint(
          'Kargo verileri '
          'kaydedilemedi: $hata',
        );
        debugPrintStack(
          stackTrace: stackTrace,
        );
      },
    );

    return _kayitZinciri;
  }

  void _degisiklikYapildi() {
    // Ekran hemen yenilensin.
    notifyListeners();

    // Ardından yeni durum diske yazılsın.
    unawaited(
      _kaydetSirayaAl(),
    );
  }

  int get bekleyenSayisi {
    return kargolar
        .where(
          (kargo) =>
              kargo.durum ==
              KargoDurumu.pending,
        )
        .length;
  }

  int get teslimEdilenSayisi {
    return kargolar
        .where(
          (kargo) =>
              kargo.durum ==
              KargoDurumu.delivered,
        )
        .length;
  }

  List<TeslimatGrubu>
      get teslimatGruplari {
    final gruplar =
        <int, List<Kargo>>{};

    for (final kargo
        in kargolar) {
      gruplar.putIfAbsent(
        kargo.teslimatId,
        () => [],
      );

      gruplar[
              kargo.teslimatId]!
          .add(
        kargo,
      );
    }

    return gruplar.values
        .map(
          (liste) =>
              TeslimatGrubu(
            kargolar: liste,
          ),
        )
        .toList();
  }

  int _yeniKargoIdOlustur() {
    if (kargolar.isEmpty) {
      return 1;
    }

    return kargolar
            .map(
              (kargo) => kargo.id,
            )
            .reduce(
              (a, b) =>
                  a > b ? a : b,
            ) +
        1;
  }

  int _yeniTeslimatIdOlustur() {
    if (kargolar.isEmpty) {
      return 1;
    }

    return kargolar
            .map(
              (kargo) =>
                  kargo.teslimatId,
            )
            .reduce(
              (a, b) =>
                  a > b ? a : b,
            ) +
        1;
  }

  void teslimatEkle({
    required int adet,
    required String alici,
    required String adres,
  }) {
    final teslimatId =
        _yeniTeslimatIdOlustur();

    for (int i = 0;
        i < adet;
        i++) {
      kargolar.add(
        Kargo(
          id:
              _yeniKargoIdOlustur(),
          teslimatId:
              teslimatId,
          alici: alici,
          adres: adres,
        ),
      );
    }

    _degisiklikYapildi();
  }

  void teslimEt(
    TeslimatGrubu grup,
  ) {
    for (final kargo
        in grup.kargolar) {
      kargo.durum =
          KargoDurumu.delivered;
    }

    _degisiklikYapildi();
  }

  void teslimatiGeriAl(
    TeslimatGrubu grup,
  ) {
    for (final kargo
        in grup.kargolar) {
      kargo.durum =
          KargoDurumu.pending;
    }

    _degisiklikYapildi();
  }

  void notGuncelle(
    TeslimatGrubu grup,
    String yeniNot,
  ) {
    for (final kargo
        in grup.kargolar) {
      kargo.not =
          yeniNot;
    }

    _degisiklikYapildi();
  }

  void adresGuncelle(
    TeslimatGrubu grup,
    String yeniAdres,
  ) {
    for (final kargo
        in grup.kargolar) {
      kargo.adres =
          yeniAdres;

      // Adres değişince eski pin artık
      // geçerli sayılmamalı.
      kargo.latitude = null;
      kargo.longitude = null;
      kargo.konumDogrulugu =
          null;
      kargo.konumKaynagi =
          null;
    }

    _degisiklikYapildi();
  }

  void konumGuncelle(
    TeslimatGrubu grup, {
    required double latitude,
    required double longitude,
    required KonumDogrulugu
        konumDogrulugu,
    required KonumKaynagi
        konumKaynagi,
  }) {
    for (final kargo
        in grup.kargolar) {
      kargo.latitude =
          latitude;
      kargo.longitude =
          longitude;
      kargo.konumDogrulugu =
          konumDogrulugu;
      kargo.konumKaynagi =
          konumKaynagi;
    }

    _degisiklikYapildi();
  }

  /// İleride Ayarlar ekranına
  /// "Tüm verileri sıfırla" butonu koyarsak
  /// bunu kullanabiliriz.
  Future<void>
      tumVerileriSifirla() async {
    kargolar
      ..clear()
      ..addAll(
        _varsayilanKargolar(),
      );

    notifyListeners();

    await _preferences.remove(
      _depolamaAnahtari,
    );

    await _kaydetSirayaAl();
  }
}

final KargoStore kargoStore =
    KargoStore();
