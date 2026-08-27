import 'dart:convert';
import 'dart:io';

import '../models/kargo_store.dart';
import 'address_normalizer.dart';
import 'google_geocoding_service.dart';
import 'verified_address_service.dart';

class GeocodeResult {
  final double latitude;
  final double longitude;
  final String displayName;
  final KonumDogrulugu dogruluk;
  final KonumKaynagi kaynak;

  const GeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.dogruluk,
    required this.kaynak,
  });
}

class GeocodingService {
  GeocodingService._();

  static final GeocodingService instance =
      GeocodingService._();

  final HttpClient _client =
      HttpClient();

  final Map<String, GeocodeResult?>
      _onbellek = {};

  final VerifiedAddressService
      _verifiedAddressService =
      VerifiedAddressService.instance;

  final GoogleGeocodingService
      _googleGeocodingService =
      GoogleGeocodingService.instance;

  DateTime? _sonNominatimIstekZamani;

  static const Duration
      _minimumNominatimIstekAraligi =
      Duration(
    milliseconds: 1100,
  );

  bool get googleAktif =>
      _googleGeocodingService.aktif;

  void onbellektenSil(
    String adres,
  ) {
    _onbellek.remove(
      AddressNormalizer.anahtar(
        adres,
      ),
    );
  }

  Future<void>
      _nominatimSirasiBekle() async {
    if (_sonNominatimIstekZamani ==
        null) {
      return;
    }

    final gecenSure =
        DateTime.now().difference(
      _sonNominatimIstekZamani!,
    );

    if (gecenSure >=
        _minimumNominatimIstekAraligi) {
      return;
    }

    await Future.delayed(
      _minimumNominatimIstekAraligi -
          gecenSure,
    );
  }

  Future<Map<String, dynamic>?>
      _nominatimAra({
    required Map<String, String>
        parametreler,
  }) async {
    await _nominatimSirasiBekle();

    _sonNominatimIstekZamani =
        DateTime.now();

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        ...parametreler,
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'tr',
        'addressdetails': '1',
        'accept-language': 'tr',
        'layer': 'address',
        'viewbox':
            '28.5900,41.0300,28.6700,40.9700',
        'bounded': '1',
      },
    );

    final request =
        await _client.getUrl(
      uri,
    );

    request.headers.set(
      HttpHeaders.userAgentHeader,
      'KargoRotaPrototype/0.3 '
      '(Flutter mobile delivery prototype)',
    );

    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/json',
    );

    final response =
        await request.close();

    if (response.statusCode !=
        HttpStatus.ok) {
      await response.drain();

      throw HttpException(
        'Nominatim HTTP '
        '${response.statusCode} döndürdü.',
        uri: uri,
      );
    }

    final body = await response
        .transform(
          utf8.decoder,
        )
        .join();

    final decoded =
        jsonDecode(body);

    if (decoded is! List ||
        decoded.isEmpty) {
      return null;
    }

    final first =
        decoded.first;

    if (first is Map<String, dynamic>) {
      return first;
    }

    if (first is Map) {
      return Map<String, dynamic>.from(
        first,
      );
    }

    return null;
  }

  bool _nominatimKapiNoEslesiyor(
    dynamic address,
    String istenenKapiNo,
  ) {
    if (address is! Map) {
      return false;
    }

    final bulunan =
        address['house_number']
            ?.toString();

    if (bulunan == null ||
        bulunan.trim().isEmpty) {
      return false;
    }

    return AddressNormalizer
            .kapiNoAnahtar(
          bulunan,
        ) ==
        AddressNormalizer
            .kapiNoAnahtar(
          istenenKapiNo,
        );
  }

  GeocodeResult?
      _nominatimSonucu(
    Map<String, dynamic>? sonuc, {
    required KonumDogrulugu
        dogruluk,
  }) {
    if (sonuc == null) {
      return null;
    }

    final lat =
        double.tryParse(
      sonuc['lat']
              ?.toString() ??
          '',
    );

    final lng =
        double.tryParse(
      sonuc['lon']
              ?.toString() ??
          '',
    );

    if (lat == null || lng == null) {
      return null;
    }

    return GeocodeResult(
      latitude: lat,
      longitude: lng,
      displayName:
          sonuc['display_name']
                  ?.toString() ??
              '',
      dogruluk: dogruluk,
      kaynak:
          KonumKaynagi.osm,
    );
  }

  Future<GeocodeResult?> adresiBul(
    String adres,
  ) async {
    final temizAdres =
        adres.trim();

    if (temizAdres.isEmpty) {
      return null;
    }

    // 1) En yüksek öncelik:
    // daha önce kurye tarafından doğrulanmış
    // aynı adres.
    final dogrulanmis =
        await _verifiedAddressService
            .bul(
      temizAdres,
    );

    if (dogrulanmis != null) {
      return GeocodeResult(
        latitude:
            dogrulanmis.latitude,
        longitude:
            dogrulanmis.longitude,
        displayName:
            AddressNormalizer
                .parcala(
                  temizAdres,
                )
                .tamAdres,
        dogruluk:
            KonumDogrulugu
                .kullaniciDogruladi,
        kaynak:
            KonumKaynagi.kurye,
      );
    }

    final anahtar =
        AddressNormalizer.anahtar(
      temizAdres,
    );

    if (_onbellek
        .containsKey(anahtar)) {
      return _onbellek[
          anahtar];
    }

    final parcalar =
        AddressNormalizer.parcala(
      temizAdres,
    );

    // Kapı numarası varsa önce gerçek bina
    // seviyesinde eşleşme arıyoruz.
    if (parcalar.kapiNo != null &&
        parcalar
            .caddeSokak.isNotEmpty) {
      final structured =
          await _nominatimAra(
        parametreler: {
          'street':
              '${parcalar.kapiNo} '
              '${parcalar.caddeSokak}',
          'city': 'Beylikdüzü',
          'county': 'İstanbul',
        },
      );

      if (structured != null &&
          _nominatimKapiNoEslesiyor(
            structured['address'],
            parcalar.kapiNo!,
          )) {
        final result =
            _nominatimSonucu(
          structured,
          dogruluk:
              KonumDogrulugu.tam,
        );

        _onbellek[anahtar] =
            result;

        return result;
      }

      final freeForm =
          await _nominatimAra(
        parametreler: {
          'q':
              '${parcalar.tamAdres}, '
              'Adnan Kahveci Mahallesi, '
              'Beylikdüzü, İstanbul, Türkiye',
        },
      );

      if (freeForm != null &&
          _nominatimKapiNoEslesiyor(
            freeForm['address'],
            parcalar.kapiNo!,
          )) {
        final result =
            _nominatimSonucu(
          freeForm,
          dogruluk:
              KonumDogrulugu.tam,
        );

        _onbellek[anahtar] =
            result;

        return result;
      }

      // 2) OSM tam binayı bulamadıysa,
      // API anahtarı varsa Google'ı deneriz.
      if (_googleGeocodingService
          .aktif) {
        final google =
            await _googleGeocodingService
                .adresiBul(
          temizAdres,
        );

        if (google != null) {
          final dogruluk =
              google.dogruluk ==
                      GoogleKonumDogrulugu
                          .rooftop
                  ? KonumDogrulugu.tam
                  : KonumDogrulugu
                      .yaklasik;

          final result =
              GeocodeResult(
            latitude:
                google.latitude,
            longitude:
                google.longitude,
            displayName:
                google.displayName,
            dogruluk:
                dogruluk,
            kaynak:
                KonumKaynagi.google,
          );

          _onbellek[anahtar] =
              result;

          return result;
        }
      }

      // 3) İki kaynak da binayı kesin
      // bulamadıysa cadde seviyesine düş.
      final streetOnly =
          await _nominatimAra(
        parametreler: {
          'q':
              '${parcalar.caddeSokak}, '
              'Adnan Kahveci Mahallesi, '
              'Beylikdüzü, İstanbul, Türkiye',
        },
      );

      final approximate =
          _nominatimSonucu(
        streetOnly,
        dogruluk:
            KonumDogrulugu.yaklasik,
      );

      _onbellek[anahtar] =
          approximate;

      return approximate;
    }

    // Kullanıcı kapı numarası istemediyse,
    // bulunan cadde/sokak konumu sorgunun
    // istediği seviyede tam sayılır.
    final streetResult =
        await _nominatimAra(
      parametreler: {
        'q':
            '${parcalar.tamAdres}, '
            'Adnan Kahveci Mahallesi, '
            'Beylikdüzü, İstanbul, Türkiye',
      },
    );

    final result =
        _nominatimSonucu(
      streetResult,
      dogruluk:
          KonumDogrulugu.tam,
    );

    _onbellek[anahtar] =
        result;

    return result;
  }
}
