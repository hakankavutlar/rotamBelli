import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/rota_sonucu.dart';

class OsrmMatrisi {
  final List<List<double?>> mesafeler;
  final List<List<double?>> sureler;

  const OsrmMatrisi({
    required this.mesafeler,
    required this.sureler,
  });
}

class OsrmHatasi implements Exception {
  final String mesaj;

  const OsrmHatasi(this.mesaj);

  @override
  String toString() => mesaj;
}

/// OSRM Table API üzerinden bütün durak çiftlerinin gerçek yol ağına göre
/// sürüş mesafesi ve süresini getirir.
class OsrmService {
  OsrmService._();

  static final OsrmService instance = OsrmService._();

  static const String _sunucu = 'https://router.project-osrm.org';

  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12);

  Future<OsrmMatrisi> mesafeMatrisiGetir(
    List<RotaDuragi> duraklar,
  ) async {
    if (duraklar.isEmpty) {
      return const OsrmMatrisi(
        mesafeler: [],
        sureler: [],
      );
    }

    if (duraklar.length == 1) {
      return const OsrmMatrisi(
        mesafeler: [
          [0],
        ],
        sureler: [
          [0],
        ],
      );
    }

    final koordinatlar = duraklar
        .map(
          (durak) =>
              '${durak.longitude.toStringAsFixed(6)},${durak.latitude.toStringAsFixed(6)}',
        )
        .join(';');

    final uri = Uri.parse(
      '$_sunucu/table/v1/driving/$koordinatlar'
      '?annotations=distance,duration',
    );

    try {
      final istek = await _httpClient
          .getUrl(uri)
          .timeout(const Duration(seconds: 15));

      istek.headers.set(
        HttpHeaders.userAgentHeader,
        'RotamBelli/1.0',
      );

      final yanit = await istek
          .close()
          .timeout(const Duration(seconds: 20));

      final govde = await utf8
          .decoder
          .bind(yanit)
          .join()
          .timeout(const Duration(seconds: 20));

      if (yanit.statusCode != HttpStatus.ok) {
        throw OsrmHatasi(
          'Rota sunucusu ${yanit.statusCode} hatası döndürdü.',
        );
      }

      final decoded = jsonDecode(govde);

      if (decoded is! Map<String, dynamic>) {
        throw const OsrmHatasi(
          'Rota sunucusundan geçersiz cevap geldi.',
        );
      }

      if (decoded['code'] != 'Ok') {
        final mesaj = decoded['message'] as String?;
        throw OsrmHatasi(
          mesaj == null || mesaj.isEmpty
              ? 'Rota mesafe tablosu oluşturulamadı.'
              : mesaj,
        );
      }

      final mesafeler = _matrisOku(
        decoded['distances'],
        beklenenBoyut: duraklar.length,
      );

      final sureler = _matrisOku(
        decoded['durations'],
        beklenenBoyut: duraklar.length,
      );

      return OsrmMatrisi(
        mesafeler: mesafeler,
        sureler: sureler,
      );
    } on OsrmHatasi {
      rethrow;
    } on TimeoutException {
      throw const OsrmHatasi(
        'Rota sunucusu zamanında cevap vermedi.',
      );
    } on SocketException {
      throw const OsrmHatasi(
        'Rota sunucusuna bağlanılamadı. İnternet bağlantısını kontrol et.',
      );
    } on FormatException {
      throw const OsrmHatasi(
        'Rota sunucusundan okunamayan bir cevap geldi.',
      );
    } catch (hata) {
      throw OsrmHatasi(
        'Rota mesafeleri alınırken hata oluştu: $hata',
      );
    }
  }

  List<List<double?>> _matrisOku(
    dynamic hamMatris, {
    required int beklenenBoyut,
  }) {
    if (hamMatris is! List || hamMatris.length != beklenenBoyut) {
      throw const OsrmHatasi(
        'Rota sunucusunun döndürdüğü matris boyutu geçersiz.',
      );
    }

    final sonuc = <List<double?>>[];

    for (final hamSatir in hamMatris) {
      if (hamSatir is! List || hamSatir.length != beklenenBoyut) {
        throw const OsrmHatasi(
          'Rota sunucusunun döndürdüğü matris satırı geçersiz.',
        );
      }

      sonuc.add(
        hamSatir.map<double?>((deger) {
          if (deger == null) {
            return null;
          }

          if (deger is num) {
            return deger.toDouble();
          }

          return null;
        }).toList(),
      );
    }

    return sonuc;
  }
}
