class RotaOptimizasyonHatasi implements Exception {
  final String mesaj;

  const RotaOptimizasyonHatasi(this.mesaj);

  @override
  String toString() => mesaj;
}

/// Başlangıç durağını sabit tutup son durağı serbest bırakan açık rota
/// optimizasyonu. İlk çözüm Nearest Neighbor, ardından 2-opt iyileştirmesi.
class RouteOptimizer {
  const RouteOptimizer();

  List<int> optimize({
    required List<List<double?>> maliyetMatrisi,
    required int baslangicIndex,
  }) {
    final n = maliyetMatrisi.length;

    if (n == 0) {
      return const [];
    }

    if (baslangicIndex < 0 || baslangicIndex >= n) {
      throw const RotaOptimizasyonHatasi(
        'Başlangıç durağı bulunamadı.',
      );
    }

    _matrisiDogrula(maliyetMatrisi);

    if (n == 1) {
      return [baslangicIndex];
    }

    var rota = _nearestNeighbor(
      maliyetMatrisi: maliyetMatrisi,
      baslangicIndex: baslangicIndex,
    );

    rota = _ikiOptIleIyilestir(
      rota: rota,
      maliyetMatrisi: maliyetMatrisi,
    );

    return rota;
  }

  List<int> _nearestNeighbor({
    required List<List<double?>> maliyetMatrisi,
    required int baslangicIndex,
  }) {
    final n = maliyetMatrisi.length;
    final ziyaretEdildi = List<bool>.filled(n, false);
    final rota = <int>[baslangicIndex];

    ziyaretEdildi[baslangicIndex] = true;
    var mevcut = baslangicIndex;

    while (rota.length < n) {
      int? enIyiIndex;
      var enIyiMaliyet = double.infinity;

      for (int aday = 0; aday < n; aday++) {
        if (ziyaretEdildi[aday]) {
          continue;
        }

        final maliyet = _maliyet(
          maliyetMatrisi[mevcut][aday],
        );

        if (maliyet < enIyiMaliyet) {
          enIyiMaliyet = maliyet;
          enIyiIndex = aday;
        }
      }

      if (enIyiIndex == null || !enIyiMaliyet.isFinite) {
        throw const RotaOptimizasyonHatasi(
          'Bazı teslimat noktalarına araçla ulaşılabilir bir yol bulunamadı.',
        );
      }

      rota.add(enIyiIndex);
      ziyaretEdildi[enIyiIndex] = true;
      mevcut = enIyiIndex;
    }

    return rota;
  }

  List<int> _ikiOptIleIyilestir({
    required List<int> rota,
    required List<List<double?>> maliyetMatrisi,
  }) {
    if (rota.length < 4) {
      return rota;
    }

    var enIyiRota = List<int>.from(rota);
    var enIyiMaliyet = _rotaMaliyeti(
      enIyiRota,
      maliyetMatrisi,
    );

    // 50 durak seviyesinde bu sınır prototip için yeterince hızlıdır.
    const int maksimumTur = 20;

    for (int tur = 0; tur < maksimumTur; tur++) {
      var iyilesti = false;

      // 0. elemanı hiç değiştirmiyoruz: başlangıç sabit.
      for (int i = 1; i < enIyiRota.length - 1; i++) {
        for (int j = i + 1; j < enIyiRota.length; j++) {
          final aday = List<int>.from(enIyiRota);

          final tersParca = aday
              .sublist(i, j + 1)
              .reversed
              .toList();

          aday.replaceRange(
            i,
            j + 1,
            tersParca,
          );

          final adayMaliyet = _rotaMaliyeti(
            aday,
            maliyetMatrisi,
          );

          if (adayMaliyet + 0.001 < enIyiMaliyet) {
            enIyiRota = aday;
            enIyiMaliyet = adayMaliyet;
            iyilesti = true;
          }
        }
      }

      if (!iyilesti) {
        break;
      }
    }

    return enIyiRota;
  }

  double _rotaMaliyeti(
    List<int> rota,
    List<List<double?>> maliyetMatrisi,
  ) {
    var toplam = 0.0;

    for (int i = 0; i < rota.length - 1; i++) {
      final maliyet = _maliyet(
        maliyetMatrisi[rota[i]][rota[i + 1]],
      );

      if (!maliyet.isFinite) {
        return double.infinity;
      }

      toplam += maliyet;
    }

    return toplam;
  }

  double _maliyet(double? deger) {
    if (deger == null || deger < 0) {
      return double.infinity;
    }

    return deger;
  }

  void _matrisiDogrula(
    List<List<double?>> matris,
  ) {
    final n = matris.length;

    for (final satir in matris) {
      if (satir.length != n) {
        throw const RotaOptimizasyonHatasi(
          'Rota maliyet matrisi geçersiz.',
        );
      }
    }
  }
}
