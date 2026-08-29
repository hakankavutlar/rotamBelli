import 'dart:convert';
import 'dart:io';

import 'address_normalizer.dart';

enum GoogleKonumDogrulugu {
  rooftop,
  interpolated,
  approximate,
}

class GoogleGeocodeResult {
  final double latitude;
  final double longitude;
  final String displayName;
  final GoogleKonumDogrulugu dogruluk;

  const GoogleGeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.dogruluk,
  });
}

class GoogleGeocodingService {
  GoogleGeocodingService._();

  static final GoogleGeocodingService instance =
      GoogleGeocodingService._();

  static const String _apiKey =
      String.fromEnvironment(
    'GOOGLE_GEOCODING_API_KEY',
  );

  final HttpClient _client =
      HttpClient();

  bool get aktif =>
      _apiKey.trim().isNotEmpty;

  String _yerelAdresSorgusu(
    NormalizeAdres parcalar, {
    bool detayli = false,
  }) {
    final kisimlar = <String>[];

    if (detayli) {
      kisimlar.addAll(
        parcalar.binaDetaylari,
      );
    }

    if (parcalar.binaAdresi.isNotEmpty) {
      kisimlar.add(
        parcalar.binaAdresi,
      );
    }

    kisimlar.add(
      parcalar.mahalle ??
          'Adnan Kahveci Mahallesi',
    );
    kisimlar.add('Beylikdüzü');
    kisimlar.add('İstanbul');
    kisimlar.add('Türkiye');

    return kisimlar.join(', ');
  }

  Future<GoogleGeocodeResult?> adresiBul(
    String adres,
  ) async {
    if (!aktif) {
      return null;
    }

    final parcalar =
        AddressNormalizer.parcala(
      adres,
    );

    if (parcalar.caddeSokak.isEmpty) {
      return null;
    }

    final temelSorgu =
        _yerelAdresSorgusu(
      parcalar,
    );

    final temelSonuc =
        await _tekSorgu(
      sorgu: temelSorgu,
      parcalar: parcalar,
    );

    if (temelSonuc != null) {
      return temelSonuc;
    }

    // Temiz cadde + kapı numarası sorgusu sonuç vermediyse
    // site/apartman adıyla bir kez daha deneriz. Daire numarası
    // sorguya hiç eklenmez.
    if (parcalar.binaDetaylari.isEmpty) {
      return null;
    }

    final detayliSorgu =
        _yerelAdresSorgusu(
      parcalar,
      detayli: true,
    );

    if (detayliSorgu == temelSorgu) {
      return null;
    }

    return _tekSorgu(
      sorgu: detayliSorgu,
      parcalar: parcalar,
    );
  }

  Future<GoogleGeocodeResult?> _tekSorgu({
    required String sorgu,
    required NormalizeAdres parcalar,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'address': sorgu,
        'components': 'country:TR',
        'language': 'tr',
        'region': 'tr',
        'key': _apiKey,
      },
    );

    final request =
        await _client.getUrl(
      uri,
    );

    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/json',
    );

    final response =
        await request.close();

    final body = await response
        .transform(
          utf8.decoder,
        )
        .join();

    if (response.statusCode !=
        HttpStatus.ok) {
      throw HttpException(
        'Google Geocoding HTTP '
        '${response.statusCode} döndürdü.',
        uri: uri,
      );
    }

    final decoded =
        jsonDecode(body);

    if (decoded is! Map) {
      return null;
    }

    final status =
        decoded['status']
            ?.toString();

    if (status == 'ZERO_RESULTS') {
      return null;
    }

    if (status != 'OK') {
      throw StateError(
        'Google Geocoding durumu: '
        '${status ?? 'bilinmiyor'}',
      );
    }

    final results =
        decoded['results'];

    if (results is! List ||
        results.isEmpty) {
      return null;
    }

    // Sadece ilk sonucu körlemesine kabul etmiyoruz. Google birkaç
    // aday döndürürse kapı numarası + yol adı birlikte eşleşen ilk
    // sonucu seçiyoruz.
    for (final aday in results) {
      if (aday is! Map) {
        continue;
      }

      final components =
          aday['address_components'];

      if (!_yolEslesiyor(
        components,
        parcalar.caddeSokak,
      )) {
        continue;
      }

      if (parcalar.kapiNo != null &&
          !_kapiNoEslesiyor(
            components,
            parcalar.kapiNo!,
          )) {
        continue;
      }

      final geometry =
          aday['geometry'];

      if (geometry is! Map) {
        continue;
      }

      final location =
          geometry['location'];

      if (location is! Map) {
        continue;
      }

      final lat =
          (location['lat'] as num?)
              ?.toDouble();

      final lng =
          (location['lng'] as num?)
              ?.toDouble();

      if (lat == null || lng == null) {
        continue;
      }

      final partialMatch =
          aday['partial_match'] == true;

      final locationType =
          geometry['location_type']
              ?.toString();

      final dogruluk =
          _dogrulukBelirle(
        locationType,
        partialMatch,
      );

      return GoogleGeocodeResult(
        latitude: lat,
        longitude: lng,
        displayName:
            aday['formatted_address']
                    ?.toString() ??
                sorgu,
        dogruluk: dogruluk,
      );
    }

    return null;
  }

  bool _kapiNoEslesiyor(
    dynamic components,
    String istenenKapiNo,
  ) {
    if (components is! List) {
      return false;
    }

    for (final component
        in components) {
      if (component is! Map) {
        continue;
      }

      final types =
          component['types'];

      if (types is! List ||
          !types.contains(
            'street_number',
          )) {
        continue;
      }

      final bulunan =
          component['long_name']
              ?.toString();

      if (bulunan == null) {
        continue;
      }

      if (AddressNormalizer
              .kapiNoAnahtar(
            bulunan,
          ) ==
          AddressNormalizer
              .kapiNoAnahtar(
            istenenKapiNo,
          )) {
        return true;
      }
    }

    return false;
  }

  bool _yolEslesiyor(
    dynamic components,
    String istenenYol,
  ) {
    if (components is! List) {
      return false;
    }

    final istenenAnahtar =
        AddressNormalizer.yolAnahtar(
      istenenYol,
    );

    if (istenenAnahtar.isEmpty) {
      return false;
    }

    for (final component
        in components) {
      if (component is! Map) {
        continue;
      }

      final types =
          component['types'];

      if (types is! List ||
          !types.contains('route')) {
        continue;
      }

      final uzunAd =
          component['long_name']
              ?.toString();
      final kisaAd =
          component['short_name']
              ?.toString();

      for (final bulunan in [
        uzunAd,
        kisaAd,
      ]) {
        if (bulunan == null ||
            bulunan.trim().isEmpty) {
          continue;
        }

        if (AddressNormalizer.yolAnahtar(
              bulunan,
            ) ==
            istenenAnahtar) {
          return true;
        }
      }
    }

    return false;
  }

  GoogleKonumDogrulugu
      _dogrulukBelirle(
    String? locationType,
    bool partialMatch,
  ) {
    if (partialMatch) {
      return GoogleKonumDogrulugu
          .approximate;
    }

    switch (locationType) {
      case 'ROOFTOP':
        return GoogleKonumDogrulugu
            .rooftop;

      case 'RANGE_INTERPOLATED':
        return GoogleKonumDogrulugu
            .interpolated;

      default:
        return GoogleKonumDogrulugu
            .approximate;
    }
  }
}
