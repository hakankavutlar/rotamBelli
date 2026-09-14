import 'kargo_store.dart';

/// Aynı fiziksel koordinatta bulunan bir veya daha fazla teslimatın
/// rota motorundaki tek durak karşılığıdır.
class RotaDuragi {
  final double latitude;
  final double longitude;
  final List<TeslimatGrubu> teslimatGruplari;

  const RotaDuragi({
    required this.latitude,
    required this.longitude,
    required this.teslimatGruplari,
  });

  int get toplamKargoAdedi {
    return teslimatGruplari.fold<int>(
      0,
      (toplam, grup) => toplam + grup.adet,
    );
  }

  int get teslimatSayisi => teslimatGruplari.length;

  bool teslimatIceriyor(int teslimatId) {
    return teslimatGruplari.any(
      (grup) => grup.teslimatId == teslimatId,
    );
  }

  String get adres {
    if (teslimatGruplari.isEmpty) {
      return '';
    }

    final adresler = teslimatGruplari
        .map((grup) => grup.adres.trim())
        .where((adres) => adres.isNotEmpty)
        .toSet()
        .toList();

    if (adresler.isEmpty) {
      return 'Adres bilgisi yok';
    }

    if (adresler.length == 1) {
      return adresler.first;
    }

    return '${adresler.first} (+${adresler.length - 1} teslimat)';
  }

  String get baslik {
    if (teslimatGruplari.isEmpty) {
      return 'Teslimat';
    }

    final isimler = teslimatGruplari
        .map((grup) => grup.alici.trim())
        .where((isim) => isim.isNotEmpty)
        .toList();

    if (isimler.isNotEmpty) {
      if (isimler.length == 1) {
        return isimler.first;
      }

      return '${isimler.first} +${isimler.length - 1} teslimat';
    }

    final ilkId = teslimatGruplari.first.ilkKargo.id;
    return '#${ilkId.toString().padLeft(3, '0')}';
  }
}

class RotaSonucu {
  final List<RotaDuragi> duraklar;
  final double toplamMesafeMetre;
  final double toplamSureSaniye;

  const RotaSonucu({
    required this.duraklar,
    required this.toplamMesafeMetre,
    required this.toplamSureSaniye,
  });

  double get toplamMesafeKm => toplamMesafeMetre / 1000;

  int get tahminiDakika => (toplamSureSaniye / 60).round();
}
