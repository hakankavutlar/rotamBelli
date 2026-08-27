import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'address_normalizer.dart';

class DogrulanmisAdresKonumu {
  final double latitude;
  final double longitude;

  const DogrulanmisAdresKonumu({
    required this.latitude,
    required this.longitude,
  });
}

class VerifiedAddressService {
  VerifiedAddressService._();

  static final VerifiedAddressService instance =
      VerifiedAddressService._();

  static const String _prefix =
      'kargo_rota_verified_address_v1_';

  final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  String _key(
    String adres,
  ) {
    final normalized =
        AddressNormalizer.anahtar(
      adres,
    );

    final encoded = base64Url.encode(
      utf8.encode(
        normalized,
      ),
    );

    return '$_prefix$encoded';
  }

  Future<DogrulanmisAdresKonumu?> bul(
    String adres,
  ) async {
    final raw = await _prefs.getString(
      _key(adres),
    );

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! Map) {
        return null;
      }

      final lat = (decoded['lat']
              as num?)
          ?.toDouble();

      final lng = (decoded['lng']
              as num?)
          ?.toDouble();

      if (lat == null || lng == null) {
        return null;
      }

      return DogrulanmisAdresKonumu(
        latitude: lat,
        longitude: lng,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> kaydet(
    String adres, {
    required double latitude,
    required double longitude,
  }) async {
    final veri = jsonEncode(
      {
        'lat': latitude,
        'lng': longitude,
      },
    );

    await _prefs.setString(
      _key(adres),
      veri,
    );
  }

  Future<void> sil(
    String adres,
  ) async {
    await _prefs.remove(
      _key(adres),
    );
  }
}
