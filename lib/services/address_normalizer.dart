class NormalizeAdres {
  final String tamAdres;
  final String caddeSokak;
  final String? kapiNo;
  final String? mahalle;
  final String? site;
  final String? apartman;

  const NormalizeAdres({
    required this.tamAdres,
    required this.caddeSokak,
    required this.kapiNo,
    required this.mahalle,
    required this.site,
    required this.apartman,
  });

  String get binaAdresi {
    if (caddeSokak.isEmpty) {
      return '';
    }

    if (kapiNo == null || kapiNo!.isEmpty) {
      return caddeSokak;
    }

    return '$caddeSokak No: $kapiNo';
  }

  List<String> get binaDetaylari {
    return [
      if (site != null && site!.isNotEmpty) site!,
      if (apartman != null && apartman!.isNotEmpty) apartman!,
    ];
  }
}

class AddressNormalizer {
  AddressNormalizer._();

  static String _bosluklariTemizle(
    String metin,
  ) {
    return metin
        .replaceAll(
          RegExp(r'[\r\n\t]+'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s*,\s*'),
          ', ',
        )
        .replaceAll(
          RegExp(r',\s*,+'),
          ', ',
        )
        .trim()
        .replaceAll(
          RegExp(r'^[,\s]+|[,\s]+$'),
          '',
        );
  }

  static String _kisaltmalariAc(
    String adres,
  ) {
    var sonuc = adres;

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\b(?:cad|cd)\.?(?=\s|,|;|$)',
        caseSensitive: false,
      ),
      (_) => 'Caddesi',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\b(?:sok|sk)\.?(?=\s|,|;|$)',
        caseSensitive: false,
      ),
      (_) => 'Sokak',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\b(?:mah|mh)\.?(?=\s|,|;|$)',
        caseSensitive: false,
      ),
      (_) => 'Mahallesi',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\b(?:blv|bulv)\.?(?=\s|,|;|$)',
        caseSensitive: false,
      ),
      (_) => 'Bulvarı',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\b(?:apt|ap)\.?(?=\s|,|;|$)',
        caseSensitive: false,
      ),
      (_) => 'Apartmanı',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\b(?:dış\s*kapı\s*)?no\.?\s*[:.]?\s*'
        r'([0-9]+[a-zA-Z]?(?:[/-][0-9a-zA-Z]+)?)',
        caseSensitive: false,
      ),
      (eslesme) =>
          'No: ${eslesme.group(1)}',
    );

    // Yaygın uzun yazımları tek biçime getiriyoruz.
    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\bcadde(?:si)?\b',
        caseSensitive: false,
      ),
      (_) => 'Caddesi',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\bsoka(?:k|ğı)\b',
        caseSensitive: false,
      ),
      (_) => 'Sokak',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\bbulvar(?:ı)?\b',
        caseSensitive: false,
      ),
      (_) => 'Bulvarı',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\bmahalle(?:si)?\b',
        caseSensitive: false,
      ),
      (_) => 'Mahallesi',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\bapartman(?:ı)?\b',
        caseSensitive: false,
      ),
      (_) => 'Apartmanı',
    );

    return _bosluklariTemizle(
      sonuc,
    );
  }

  static String? _mahalleBul(
    String adres,
  ) {
    // Pilot bölgeyi özellikle tanıyoruz. Böylece adresin başında
    // İstanbul/Beylikdüzü gibi ek bilgiler olsa bile mahalle adı
    // yanlışlıkla uzamıyor.
    final pilot = RegExp(
      r'\bAdnan\s+Kahveci\s+Mahallesi\b',
      caseSensitive: false,
    ).firstMatch(adres);

    if (pilot != null) {
      return 'Adnan Kahveci Mahallesi';
    }

    final eslesme = RegExp(
      r'(?:^|[,.;])\s*([^,.;]{2,60}?)\s+Mahallesi\b',
      caseSensitive: false,
    ).firstMatch(adres);

    final ad = eslesme?.group(1)?.trim();

    if (ad == null || ad.isEmpty) {
      return null;
    }

    return '$ad Mahallesi';
  }

  static String _mahalleyiCikar(
    String adres,
    String? mahalle,
  ) {
    if (mahalle == null || mahalle.isEmpty) {
      return adres;
    }

    return adres.replaceFirst(
      RegExp(
        RegExp.escape(mahalle),
        caseSensitive: false,
      ),
      ' ',
    );
  }

  static String _yolOnEkiniTemizle(
    String deger,
  ) {
    var sonuc = deger.trim();

    // "Adnan Kahveci Mahallesi Çambaşı Caddesi" veya
    // "Umut Sitesi Çambaşı Caddesi" gibi noktalamasız girişlerde
    // yol adından önceki adres parçalarını ayıklıyoruz.
    final ayirici = RegExp(
      r'\b(?:Mahallesi|Sitesi|Apartmanı|Blok)\b\s*',
      caseSensitive: false,
    );

    final parcalar = sonuc.split(ayirici);

    if (parcalar.isNotEmpty) {
      sonuc = parcalar.last.trim();
    }

    return sonuc
        .replaceAll(
          RegExp(r'^[,.;:\-\s]+'),
          '',
        )
        .trim();
  }

  static String _yolBul(
    String adres,
    String? mahalle,
  ) {
    final mahalleHaric =
        _mahalleyiCikar(
      adres,
      mahalle,
    );

    // 203. Sokak, 1. Cadde gibi numaralı yol adlarını nokta
    // yüzünden iki parçaya bölmeden önce yakalıyoruz.
    final numaraliYol = RegExp(
      r'\b([0-9]+\.?\s+(?:Caddesi|Sokak|Bulvarı))\b',
      caseSensitive: false,
    ).firstMatch(mahalleHaric);

    if (numaraliYol != null) {
      final bulunan =
          numaraliYol.group(1)?.trim();

      if (bulunan != null && bulunan.isNotEmpty) {
        return bulunan;
      }
    }

    final eslesmeler = RegExp(
      r'(?:^|[,.;])\s*([^,.;]{1,90}?)\s+'
      r'(Caddesi|Sokak|Bulvarı)\b',
      caseSensitive: false,
    ).allMatches(mahalleHaric);

    for (final eslesme in eslesmeler) {
      final hamAd =
          _yolOnEkiniTemizle(
        eslesme.group(1) ?? '',
      );

      final tur = eslesme.group(2) ?? '';

      if (hamAd.isEmpty || tur.isEmpty) {
        continue;
      }

      return _bosluklariTemizle(
        '$hamAd $tur',
      );
    }

    // Virgül/nokta kullanılmamış adresler için ikinci deneme.
    final serbest = RegExp(
      r'([^,.;]{1,90}?)\s+'
      r'(Caddesi|Sokak|Bulvarı)\b',
      caseSensitive: false,
    ).firstMatch(mahalleHaric);

    if (serbest == null) {
      return '';
    }

    final hamAd =
        _yolOnEkiniTemizle(
      serbest.group(1) ?? '',
    );

    final tur = serbest.group(2) ?? '';

    if (hamAd.isEmpty || tur.isEmpty) {
      return '';
    }

    return _bosluklariTemizle(
      '$hamAd $tur',
    );
  }

  static String? _kapiNoBul(
    String adres,
    String caddeSokak,
  ) {
    final acikNo = RegExp(
      r'\bNo:\s*'
      r'([0-9]+[a-zA-Z]?(?:[/-][0-9a-zA-Z]+)?)',
      caseSensitive: false,
    ).firstMatch(adres);

    if (acikNo != null) {
      return acikNo.group(1);
    }

    if (caddeSokak.isEmpty) {
      return null;
    }

    // "Çambaşı Cad. 11" gibi No: yazılmayan adresleri de
    // bina numarası olarak anlayabilmek için yol adının hemen
    // arkasındaki sayıyı kullanıyoruz.
    final yolEslesmesi = RegExp(
      RegExp.escape(caddeSokak),
      caseSensitive: false,
    ).firstMatch(adres);

    if (yolEslesmesi == null) {
      return null;
    }

    final devam = adres.substring(
      yolEslesmesi.end,
    );

    final dogrudanNo = RegExp(
      r'^[\s,.;:#\-]*'
      r'([0-9]+[a-zA-Z]?(?:[/-][0-9a-zA-Z]+)?)\b',
      caseSensitive: false,
    ).firstMatch(devam);

    return dogrudanNo?.group(1);
  }

  static String? _siteBul(
    String adres,
  ) {
    final eslesme = RegExp(
      r'(?:^|[,.;])\s*([^,.;]{1,60}?\s+Sitesi)\b',
      caseSensitive: false,
    ).firstMatch(adres);

    return eslesme?.group(1)?.trim();
  }

  static String? _apartmanBul(
    String adres,
  ) {
    final eslesme = RegExp(
      r'(?:No:\s*[0-9]+[a-zA-Z]?(?:[/-][0-9a-zA-Z]+)?\s+|^|[,.;])'
      r'\s*([^,.;]{1,60}?\s+Apartmanı)\b',
      caseSensitive: false,
    ).firstMatch(adres);

    return eslesme?.group(1)?.trim();
  }

  static NormalizeAdres parcala(
    String adres,
  ) {
    final tamAdres =
        _kisaltmalariAc(
      adres.trim(),
    );

    final mahalle =
        _mahalleBul(
      tamAdres,
    );

    final caddeSokak =
        _yolBul(
      tamAdres,
      mahalle,
    );

    final kapiNo =
        _kapiNoBul(
      tamAdres,
      caddeSokak,
    );

    return NormalizeAdres(
      tamAdres: tamAdres,
      caddeSokak: caddeSokak,
      kapiNo: kapiNo,
      mahalle: mahalle,
      site: _siteBul(tamAdres),
      apartman: _apartmanBul(tamAdres),
    );
  }

  static String anahtar(
    String adres,
  ) {
    final normalize =
        parcala(adres).tamAdres;

    return normalize
        .toLowerCase()
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s*,\s*'),
          ',',
        )
        .trim();
  }

  static String kapiNoAnahtar(
    String deger,
  ) {
    return deger
        .toLowerCase()
        .replaceAll(
          RegExp(r'\s+'),
          '',
        )
        .replaceAll(
          '.',
          '',
        );
  }

  static String yolAnahtar(
    String deger,
  ) {
    var sonuc = _kisaltmalariAc(
      deger,
    ).toLowerCase();

    sonuc = sonuc
        .replaceAll('ı', 'i')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');

    sonuc = sonuc.replaceAll(
      RegExp(
        r'\b(?:caddesi|sokak|bulvari)\b',
        caseSensitive: false,
      ),
      '',
    );

    return sonuc.replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
  }
}
