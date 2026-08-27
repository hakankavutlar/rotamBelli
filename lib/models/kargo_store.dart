import 'package:flutter/foundation.dart';

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
  final List<Kargo> kargolar = [
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

    notifyListeners();
  }

  void teslimEt(
    TeslimatGrubu grup,
  ) {
    for (final kargo
        in grup.kargolar) {
      kargo.durum =
          KargoDurumu.delivered;
    }

    notifyListeners();
  }

  void teslimatiGeriAl(
    TeslimatGrubu grup,
  ) {
    for (final kargo
        in grup.kargolar) {
      kargo.durum =
          KargoDurumu.pending;
    }

    notifyListeners();
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

    notifyListeners();
  }

  void adresGuncelle(
    TeslimatGrubu grup,
    String yeniAdres,
  ) {
    for (final kargo
        in grup.kargolar) {
      kargo.adres =
          yeniAdres;

      kargo.latitude = null;
      kargo.longitude = null;
      kargo.konumDogrulugu =
          null;
      kargo.konumKaynagi =
          null;
    }

    notifyListeners();
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

    notifyListeners();
  }
}

final KargoStore kargoStore =
    KargoStore();
