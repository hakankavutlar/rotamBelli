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

    final sorgu =
        '${parcalar.tamAdres}, '
        'Adnan Kahveci Mahallesi, '
        'Beylikdüzü, İstanbul, Türkiye';

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

    final first = results.first;

    if (first is! Map) {
      return null;
    }

    final partialMatch =
        first['partial_match'] == true;

    final components =
        first['address_components'];

    if (parcalar.kapiNo != null &&
        !_kapiNoEslesiyor(
          components,
          parcalar.kapiNo!,
        )) {
      return null;
    }

    final geometry =
        first['geometry'];

    if (geometry is! Map) {
      return null;
    }

    final location =
        geometry['location'];

    if (location is! Map) {
      return null;
    }

    final lat =
        (location['lat'] as num?)
            ?.toDouble();

    final lng =
        (location['lng'] as num?)
            ?.toDouble();

    if (lat == null || lng == null) {
      return null;
    }

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
          first['formatted_address']
                  ?.toString() ??
              sorgu,
      dogruluk: dogruluk,
    );
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
