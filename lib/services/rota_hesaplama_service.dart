import '../models/kargo_store.dart';
import '../models/rota_sonucu.dart';
import 'osrm_service.dart';
import 'route_optimizer.dart';

class RotaHesaplamaHatasi implements Exception {
  final String mesaj;

  const RotaHesaplamaHatasi(this.mesaj);

  @override
  String toString() => mesaj;
}

class RotaHesaplamaService {
  RotaHesaplamaService._();

  static final RotaHesaplamaService instance =
      RotaHesaplamaService._();

  final OsrmService _osrmService = OsrmService.instance;
  final RouteOptimizer _optimizer = const RouteOptimizer();

  /// Başlangıç teslimatını sabit tutar. Bitiş noktası özellikle verilmez;
  /// algoritmanın toplam süreyi azaltan açık rotası hangi durakta bitiyorsa
  /// "En Stratejik Nokta" odur.
  Future<RotaSonucu> hesapla({
    required List<TeslimatGrubu> gruplar,
    required int baslangicTeslimatId,
  }) async {
    final bekleyenGruplar = gruplar.where(
      (grup) => grup.kargolar.any(
        (kargo) => kargo.durum == KargoDurumu.pending,
      ),
    ).toList();

    if (bekleyenGruplar.isEmpty) {
      throw const RotaHesaplamaHatasi(
        'Rota oluşturmak için bekleyen kargo yok.',
      );
    }

    final konumsuzGruplar = bekleyenGruplar
        .where((grup) => !grup.konumuVar)
        .toList();

    if (konumsuzGruplar.isNotEmpty) {
      throw RotaHesaplamaHatasi(
        '${konumsuzGruplar.length} teslimatın harita konumu hazır değil. '
        'Önce bu teslimatların pinlerini oluştur.',
      );
    }

    final baslangicBekliyor = bekleyenGruplar.any(
      (grup) => grup.teslimatId == baslangicTeslimatId,
    );

    if (!baslangicBekliyor) {
      throw const RotaHesaplamaHatasi(
        'Seçilen başlangıç teslimatı artık bekleyen listesinde değil.',
      );
    }

    final duraklar = _ayniKonumdakileriBirlestir(
      bekleyenGruplar,
    );

    final baslangicIndex = duraklar.indexWhere(
      (durak) => durak.teslimatIceriyor(
        baslangicTeslimatId,
      ),
    );

    if (baslangicIndex < 0) {
      throw const RotaHesaplamaHatasi(
        'Başlangıç noktasının koordinatı bulunamadı.',
      );
    }

    if (duraklar.length == 1) {
      return RotaSonucu(
        duraklar: [duraklar.first],
        toplamMesafeMetre: 0,
        toplamSureSaniye: 0,
      );
    }

    try {
      final matris = await _osrmService.mesafeMatrisiGetir(
        duraklar,
      );

      // "Stratejik" ölçüt olarak statik sürüş süresini kullanıyoruz.
      // Trafik verisi kullanılmıyor; OSRM'nin yol sınıflarına dayalı driving
      // profilindeki süreler kullanılıyor.
      final siralama = _optimizer.optimize(
        maliyetMatrisi: matris.sureler,
        baslangicIndex: baslangicIndex,
      );

      final siraliDuraklar = siralama
          .map((index) => duraklar[index])
          .toList();

      var toplamMesafe = 0.0;
      var toplamSure = 0.0;

      for (int i = 0; i < siralama.length - 1; i++) {
        final from = siralama[i];
        final to = siralama[i + 1];

        final mesafe = matris.mesafeler[from][to];
        final sure = matris.sureler[from][to];

        if (mesafe == null || sure == null) {
          throw const RotaHesaplamaHatasi(
            'Rota üzerindeki iki durak arasında araç yolu bulunamadı.',
          );
        }

        toplamMesafe += mesafe;
        toplamSure += sure;
      }

      return RotaSonucu(
        duraklar: siraliDuraklar,
        toplamMesafeMetre: toplamMesafe,
        toplamSureSaniye: toplamSure,
      );
    } on OsrmHatasi catch (hata) {
      throw RotaHesaplamaHatasi(hata.mesaj);
    } on RotaOptimizasyonHatasi catch (hata) {
      throw RotaHesaplamaHatasi(hata.mesaj);
    }
  }

  List<RotaDuragi> _ayniKonumdakileriBirlestir(
    List<TeslimatGrubu> gruplar,
  ) {
    final duraklar = <RotaDuragi>[];

    // map_page.dart ile aynı tolerans: yaklaşık 10 cm.
    const double tolerans = 0.000001;

    for (final grup in gruplar) {
      final latitude = grup.latitude!;
      final longitude = grup.longitude!;

      int? bulunanIndex;

      for (int i = 0; i < duraklar.length; i++) {
        final durak = duraklar[i];

        final ayniKonum =
            (durak.latitude - latitude).abs() <= tolerans &&
                (durak.longitude - longitude).abs() <= tolerans;

        if (ayniKonum) {
          bulunanIndex = i;
          break;
        }
      }

      if (bulunanIndex == null) {
        duraklar.add(
          RotaDuragi(
            latitude: latitude,
            longitude: longitude,
            teslimatGruplari: [grup],
          ),
        );
      } else {
        final mevcut = duraklar[bulunanIndex];

        duraklar[bulunanIndex] = RotaDuragi(
          latitude: mevcut.latitude,
          longitude: mevcut.longitude,
          teslimatGruplari: [
            ...mevcut.teslimatGruplari,
            grup,
          ],
        );
      }
    }

    return duraklar;
  }
}
