class NormalizeAdres {
  final String tamAdres;
  final String caddeSokak;
  final String? kapiNo;

  const NormalizeAdres({
    required this.tamAdres,
    required this.caddeSokak,
    required this.kapiNo,
  });
}

class AddressNormalizer {
  AddressNormalizer._();

  static String _bosluklariTemizle(
    String metin,
  ) {
    return metin
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s*,\s*'),
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
        r'\b(?:cad|cd)\.?(?=\s|,|$)',
        caseSensitive: false,
      ),
      (_) => 'Caddesi',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\b(?:sok|sk)\.?(?=\s|,|$)',
        caseSensitive: false,
      ),
      (_) => 'Sokak',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\b(?:mah|mh)\.?(?=\s|,|$)',
        caseSensitive: false,
      ),
      (_) => 'Mahallesi',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\b(?:blv|bulv)\.?(?=\s|,|$)',
        caseSensitive: false,
      ),
      (_) => 'Bulvarı',
    );

    sonuc = sonuc.replaceAllMapped(
      RegExp(
        r'\bno\.?\s*[:.]?\s*'
        r'([0-9]+[a-zA-Z]?(?:[/-][0-9a-zA-Z]+)?)',
        caseSensitive: false,
      ),
      (eslesme) =>
          'No: ${eslesme.group(1)}',
    );

    return _bosluklariTemizle(
      sonuc,
    );
  }

  static NormalizeAdres parcala(
    String adres,
  ) {
    final tamAdres =
        _kisaltmalariAc(
      adres.trim(),
    );

    final noEslesmesi = RegExp(
      r'\bNo:\s*'
      r'([0-9]+[a-zA-Z]?(?:[/-][0-9a-zA-Z]+)?)',
      caseSensitive: false,
    ).firstMatch(
      tamAdres,
    );

    final kapiNo =
        noEslesmesi?.group(1);

    var caddeSokak = tamAdres;

    if (noEslesmesi != null) {
      caddeSokak =
          caddeSokak.replaceRange(
        noEslesmesi.start,
        noEslesmesi.end,
        '',
      );
    }

    caddeSokak =
        _bosluklariTemizle(
      caddeSokak,
    );

    return NormalizeAdres(
      tamAdres: tamAdres,
      caddeSokak: caddeSokak,
      kapiNo: kapiNo,
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
}
