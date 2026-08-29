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

  bool _nominatimYolEslesiyor(
    dynamic address,
    String istenenYol,
  ) {
    if (address is! Map) {
      return false;
    }

    final istenenAnahtar =
        AddressNormalizer.yolAnahtar(
      istenenYol,
    );

    if (istenenAnahtar.isEmpty) {
      return false;
    }

    const alanlar = [
      'road',
      'street',
      'pedestrian',
      'residential',
    ];

    for (final alan in alanlar) {
      final bulunan =
          address[alan]?.toString();

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

    return false;
  }

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

    final temizYerelSorgu =
        _yerelAdresSorgusu(
      parcalar,
    );

    // Kapı numarası ve gerçek bir cadde/sokak adı çıkarabildiysek
    // bina seviyesinde eşleşme arıyoruz. Uzun kullanıcı adresini
    // doğrudan "street" alanına göndermiyoruz.
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
          ) &&
          _nominatimYolEslesiyor(
            structured['address'],
            parcalar.caddeSokak,
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

      // Serbest sorguda da sadece geocoding için gerekli parçaları
      // kullanıyoruz. Site/apartman/daire metinleri cadde adına
      // karışmıyor ve mahalle iki kez eklenmiyor.
      final freeForm =
          await _nominatimAra(
        parametreler: {
          'q': temizYerelSorgu,
        },
      );

      if (freeForm != null &&
          _nominatimKapiNoEslesiyor(
            freeForm['address'],
            parcalar.kapiNo!,
          ) &&
          _nominatimYolEslesiyor(
            freeForm['address'],
            parcalar.caddeSokak,
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

      // Site/apartman adı gerçekten harita verisinde kayıtlıysa
      // ikinci bir temiz sorgu faydalı olabilir. Daire numarasını
      // bilerek sorguya katmıyoruz.
      if (parcalar.binaDetaylari.isNotEmpty) {
        final detayliSorgu =
            _yerelAdresSorgusu(
          parcalar,
          detayli: true,
        );

        if (detayliSorgu !=
            temizYerelSorgu) {
          final detayli =
              await _nominatimAra(
            parametreler: {
              'q': detayliSorgu,
            },
          );

          if (detayli != null &&
              _nominatimKapiNoEslesiyor(
                detayli['address'],
                parcalar.kapiNo!,
              ) &&
              _nominatimYolEslesiyor(
                detayli['address'],
                parcalar.caddeSokak,
              )) {
            final result =
                _nominatimSonucu(
              detayli,
              dogruluk:
                  KonumDogrulugu.tam,
            );

            _onbellek[anahtar] =
                result;

            return result;
          }
        }
      }

      // OSM gerçek binayı bulamadıysa Google'ı deneriz.
      // Google servisi de artık temizlenmiş cadde + kapı numarası
      // sorgusunu kullanacak ve hem kapı numarasını hem yol adını
      // doğrulayacak.
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

      // Bu aşamada bina kesin bulunamadı. Şimdilik mevcut davranışı
      // koruyup cadde seviyesine düşüyoruz. "Her teslimata mutlaka pin"
      // kuralını ikinci problemde ayrıca güçlendireceğiz.
      final streetOnly =
          await _nominatimAra(
        parametreler: {
          'q':
              '${parcalar.caddeSokak}, '
              '${parcalar.mahalle ?? 'Adnan Kahveci Mahallesi'}, '
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

    // Kapı numarası yok ama yol adı çıkarılabildiyse yol seviyesinde
    // temiz sorgu kullanıyoruz.
    if (parcalar.caddeSokak.isNotEmpty) {
      final streetResult =
          await _nominatimAra(
        parametreler: {
          'q': temizYerelSorgu,
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

    // Yol adı dahi çıkarılamadıysa eski serbest arama davranışını
    // koruyoruz. Bunun güvenli yaklaşık-pin davranışını 2. adımda
    // ele alacağız.
    final serbestSorgu =
        '${parcalar.tamAdres}, '
        'Adnan Kahveci Mahallesi, '
        'Beylikdüzü, İstanbul, Türkiye';

    final result =
        _nominatimSonucu(
      await _nominatimAra(
        parametreler: {
          'q': serbestSorgu,
        },
      ),
      dogruluk:
          KonumDogrulugu.yaklasik,
    );

    _onbellek[anahtar] =
        result;

    return result;
  }

}
