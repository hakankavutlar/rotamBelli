import 'package:flutter/material.dart';

void main() {
  runApp(const KargoRotaApp());
}

enum KargoDurumu {
  pending,
  delivered,
  skipped,
}

class Kargo {
  final int id;
  final int teslimatId;
  final String alici;

  String adres;
  String not;
  KargoDurumu durum;

  Kargo({
    required this.id,
    required this.teslimatId,
    required this.alici,
    required this.adres,
    this.not = '',
    this.durum = KargoDurumu.pending,
  });
}

class YeniTeslimatVerisi {
  final int adet;
  final String alici;
  final String adres;

  YeniTeslimatVerisi({
    required this.adet,
    required this.alici,
    required this.adres,
  });
}

class TopluKargoSatiri {
  final int adet;
  final String alici;
  final String adres;

  TopluKargoSatiri({
    required this.adet,
    required this.alici,
    required this.adres,
  });
}

class TeslimatGrubu {
  final List<Kargo> kargolar;

  TeslimatGrubu({
    required this.kargolar,
  });

  Kargo get ilkKargo => kargolar.first;

  int get adet => kargolar.length;

  int get teslimatId => ilkKargo.teslimatId;

  String get alici => ilkKargo.alici;

  String get adres => ilkKargo.adres;

  String get not => ilkKargo.not;

  bool get teslimEdildi {
    return kargolar.every(
      (kargo) => kargo.durum == KargoDurumu.delivered,
    );
  }
}

class KargoRotaApp extends StatelessWidget {
  const KargoRotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kargo Rota',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const KargoAnaSayfa(),
    );
  }
}

class KargoAnaSayfa extends StatefulWidget {
  const KargoAnaSayfa({super.key});

  @override
  State<KargoAnaSayfa> createState() => _KargoAnaSayfaState();
}

class _KargoAnaSayfaState extends State<KargoAnaSayfa> {
  final List<Kargo> kargolar = [
    Kargo(
      id: 1,
      teslimatId: 1,
      alici: '',
      adres: 'Anadolu Cad. No:15',
    ),
    Kargo(
      id: 2,
      teslimatId: 2,
      alici: '',
      adres: 'Çambaşı Cad. No:22',
    ),
    Kargo(
      id: 3,
      teslimatId: 3,
      alici: '',
      adres: 'Atatürk Bulvarı No:8',
    ),
    Kargo(
      id: 4,
      teslimatId: 4,
      alici: '',
      adres: 'Avrupa Cad. No:36',
    ),
    Kargo(
      id: 5,
      teslimatId: 5,
      alici: '',
      adres: 'Kurtuluş Cad. No:12',
    ),
  ];

  int get bekleyenSayisi {
    return kargolar
        .where(
          (kargo) => kargo.durum == KargoDurumu.pending,
        )
        .length;
  }

  int get teslimEdilenSayisi {
    return kargolar
        .where(
          (kargo) => kargo.durum == KargoDurumu.delivered,
        )
        .length;
  }

  List<TeslimatGrubu> get teslimatGruplari {
    final gruplar = <int, List<Kargo>>{};

    for (final kargo in kargolar) {
      gruplar.putIfAbsent(
        kargo.teslimatId,
        () => [],
      );

      gruplar[kargo.teslimatId]!.add(kargo);
    }

    return gruplar.values
        .map(
          (liste) => TeslimatGrubu(
            kargolar: liste,
          ),
        )
        .toList();
  }

  int yeniKargoIdOlustur() {
    if (kargolar.isEmpty) {
      return 1;
    }

    return kargolar
            .map(
              (kargo) => kargo.id,
            )
            .reduce(
              (a, b) => a > b ? a : b,
            ) +
        1;
  }

  int yeniTeslimatIdOlustur() {
    if (kargolar.isEmpty) {
      return 1;
    }

    return kargolar
            .map(
              (kargo) => kargo.teslimatId,
            )
            .reduce(
              (a, b) => a > b ? a : b,
            ) +
        1;
  }

  Future<bool> teslimOnayiSor(
    TeslimatGrubu grup,
  ) async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Teslim Edildi',
          ),
          content: Text(
            grup.adet > 1
                ? '${grup.adet} adet kargoyu teslim edildi olarak '
                    'işaretlemek istediğine emin misin?'
                : 'Bu kargoyu teslim edildi olarak '
                    'işaretlemek istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Hayır',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Evet',
              ),
            ),
          ],
        );
      },
    );

    return sonuc ?? false;
  }

  Future<bool> teslimIptalOnayiSor(
    TeslimatGrubu grup,
  ) async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Teslimatı Geri Al',
          ),
          content: Text(
            grup.adet > 1
                ? '${grup.adet} adet kargoyu tekrar bekleyen '
                    'durumuna almak istediğine emin misin?'
                : 'Bu kargoyu tekrar bekleyen durumuna '
                    'almak istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Hayır',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Evet',
              ),
            ),
          ],
        );
      },
    );

    return sonuc ?? false;
  }

  Future<void> teslimEt(
    TeslimatGrubu grup,
  ) async {
    final onaylandi = await teslimOnayiSor(
      grup,
    );

    if (!onaylandi || !mounted) {
      return;
    }

    setState(() {
      for (final kargo in grup.kargolar) {
        kargo.durum = KargoDurumu.delivered;
      }
    });
  }

  Future<void> teslimatiGeriAl(
    TeslimatGrubu grup,
  ) async {
    final onaylandi = await teslimIptalOnayiSor(
      grup,
    );

    if (!onaylandi || !mounted) {
      return;
    }

    setState(() {
      for (final kargo in grup.kargolar) {
        kargo.durum = KargoDurumu.pending;
      }
    });
  }

  Future<void> teslimatMenuAc(
    TeslimatGrubu grup,
  ) async {
    final secim = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (grup.alici.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        grup.alici,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.note_add_outlined,
                  ),
                  title: Text(
                    grup.not.isEmpty
                        ? 'Not Ekle'
                        : 'Notu Düzenle',
                  ),
                  subtitle: const Text(
                    'Teslimat için özel bir not ekle',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'not',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.edit_location_alt_outlined,
                  ),
                  title: const Text(
                    'Düzenle',
                  ),
                  subtitle: const Text(
                    'Teslimat adresini düzenle',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'duzenle',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (secim == 'not') {
      await notDuzenle(
        grup,
      );
    }

    if (secim == 'duzenle') {
      await adresDuzenle(
        grup,
      );
    }
  }

  Future<void> notDuzenle(
    TeslimatGrubu grup,
  ) async {
    final yeniNot = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return NotDuzenleSayfa(
            mevcutNot: grup.not,
          );
        },
      ),
    );

    if (!mounted || yeniNot == null) {
      return;
    }

    setState(() {
      for (final kargo in grup.kargolar) {
        kargo.not = yeniNot;
      }
    });
  }

  Future<void> adresDuzenle(
    TeslimatGrubu grup,
  ) async {
    final yeniAdres = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AdresDuzenleSayfa(
            mevcutAdres: grup.adres,
          );
        },
      ),
    );

    if (!mounted ||
        yeniAdres == null ||
        yeniAdres.trim().isEmpty) {
      return;
    }

    setState(() {
      for (final kargo in grup.kargolar) {
        kargo.adres = yeniAdres.trim();
      }
    });
  }

  Future<void> kargoEkleMenuAc() async {
    final secim = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    16,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kargo Ekle',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.add_box_outlined,
                    size: 30,
                  ),
                  title: const Text(
                    'Tek Ekle',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Tek bir teslimat ekle',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'tek',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.library_add_outlined,
                    size: 30,
                  ),
                  title: const Text(
                    'Toplu Ekle',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Birden fazla kargoyu metin olarak ekle',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'toplu',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (secim == 'tek') {
      final yeniTeslimat =
          await Navigator.push<YeniTeslimatVerisi>(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const TekKargoEkleSayfa();
          },
        ),
      );

      if (!mounted || yeniTeslimat == null) {
        return;
      }

      final teslimatId = yeniTeslimatIdOlustur();

      setState(() {
        for (int i = 0;
            i < yeniTeslimat.adet;
            i++) {
          kargolar.add(
            Kargo(
              id: yeniKargoIdOlustur(),
              teslimatId: teslimatId,
              alici: yeniTeslimat.alici,
              adres: yeniTeslimat.adres,
            ),
          );
        }
      });
    }

    if (secim == 'toplu') {
      final yeniTeslimatlar =
          await Navigator.push<List<YeniTeslimatVerisi>>(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const TopluKargoEkleSayfa();
          },
        ),
      );

      if (!mounted ||
          yeniTeslimatlar == null ||
          yeniTeslimatlar.isEmpty) {
        return;
      }

      int toplamEklenen = 0;

      setState(() {
        for (final teslimat in yeniTeslimatlar) {
          final teslimatId =
              yeniTeslimatIdOlustur();

          for (int i = 0;
              i < teslimat.adet;
              i++) {
            kargolar.add(
              Kargo(
                id: yeniKargoIdOlustur(),
                teslimatId: teslimatId,
                alici: teslimat.alici,
                adres: teslimat.adres,
              ),
            );

            toplamEklenen++;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$toplamEklenen kargo başarıyla eklendi.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gruplar = teslimatGruplari;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kargo Dağıtım',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Sayac(
                    baslik: 'Bekleyen',
                    sayi: bekleyenSayisi,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Sayac(
                    baslik: 'Teslim edilen',
                    sayi: teslimEdilenSayisi,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              10,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bugünkü Kargolar',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: gruplar.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz kargo yok.',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    itemCount: gruplar.length,
                    separatorBuilder: (
                      context,
                      index,
                    ) {
                      return const SizedBox(
                        height: 4,
                      );
                    },
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final grup = gruplar[index];

                      return KargoSatiri(
                        grup: grup,
                        sira: index + 1,
                        teslimEt: () {
                          teslimEt(
                            grup,
                          );
                        },
                        teslimatiGeriAl: () {
                          teslimatiGeriAl(
                            grup,
                          );
                        },
                        uzunBas: () {
                          teslimatMenuAc(
                            grup,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: kargoEkleMenuAc,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Kargo Ekle',
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// TEK KARGO EKLE
// ----------------------------------------------------

class TekKargoEkleSayfa extends StatefulWidget {
  const TekKargoEkleSayfa({
    super.key,
  });

  @override
  State<TekKargoEkleSayfa> createState() {
    return _TekKargoEkleSayfaState();
  }
}

class _TekKargoEkleSayfaState
    extends State<TekKargoEkleSayfa> {
  final TextEditingController aliciController =
      TextEditingController();

  final TextEditingController adresController =
      TextEditingController();

  @override
  void dispose() {
    aliciController.dispose();
    adresController.dispose();

    super.dispose();
  }

  void kargoEkle() {
    final alici = aliciController.text.trim();
    final adres = adresController.text.trim();

    if (adres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen teslimat adresini gir.',
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      YeniTeslimatVerisi(
        adet: 1,
        alici: alici,
        adres: adres,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tek Kargo Ekle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(
          20,
        ),
        children: [
          const Text(
            'Alıcı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: aliciController,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Örn: Ahmet Yılmaz',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          const Text(
            'Teslimat Adresi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: adresController,
            textCapitalization:
                TextCapitalization.words,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: 'Örn: Anadolu Cad. No:15',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          FilledButton.icon(
            onPressed: kargoEkle,
            icon: const Icon(
              Icons.add,
            ),
            label: const Text(
              'Kargoyu Ekle',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// TOPLU KARGO EKLE
// ----------------------------------------------------

class TopluKargoEkleSayfa extends StatefulWidget {
  const TopluKargoEkleSayfa({
    super.key,
  });

  @override
  State<TopluKargoEkleSayfa> createState() {
    return _TopluKargoEkleSayfaState();
  }
}

class _TopluKargoEkleSayfaState
    extends State<TopluKargoEkleSayfa> {
  final TextEditingController topluController =
      TextEditingController();

  List<TopluKargoSatiri> onizleme = [];

  List<String> hatalar = [];

  bool onizlemeYapildi = false;

  @override
  void dispose() {
    topluController.dispose();

    super.dispose();
  }

  int get toplamKargo {
    int toplam = 0;

    for (final satir in onizleme) {
      toplam += satir.adet;
    }

    return toplam;
  }

  void onizle() {
    final metin = topluController.text.trim();

    final yeniOnizleme = <TopluKargoSatiri>[];
    final yeniHatalar = <String>[];

    if (metin.isEmpty) {
      setState(() {
        onizleme = [];
        hatalar = [
          'Toplu ekleme alanı boş.',
        ];
        onizlemeYapildi = true;
      });

      return;
    }

    final satirlar = metin.split('\n');

    for (int i = 0;
        i < satirlar.length;
        i++) {
      final hamSatir = satirlar[i].trim();

      if (hamSatir.isEmpty) {
        continue;
      }

      final parcalar = hamSatir.split('|');

      if (parcalar.length < 3) {
        yeniHatalar.add(
          '${i + 1}. satır hatalı: '
          'ADET|ALICI|ADRES formatında olmalı.',
        );

        continue;
      }

      final adetMetni = parcalar[0].trim();
      final alici = parcalar[1].trim();

      final adres = parcalar
          .sublist(2)
          .join('|')
          .trim();

      final adet = int.tryParse(
        adetMetni,
      );

      if (adet == null || adet < 1) {
        yeniHatalar.add(
          '${i + 1}. satır hatalı: '
          'kargo adedi geçerli değil.',
        );

        continue;
      }

      if (adet > 100) {
        yeniHatalar.add(
          '${i + 1}. satır hatalı: '
          'tek satırda en fazla 100 kargo eklenebilir.',
        );

        continue;
      }

      if (alici.isEmpty) {
        yeniHatalar.add(
          '${i + 1}. satır hatalı: '
          'alıcı adı boş bırakılamaz.',
        );

        continue;
      }

      if (adres.isEmpty) {
        yeniHatalar.add(
          '${i + 1}. satır hatalı: '
          'adres boş bırakılamaz.',
        );

        continue;
      }

      yeniOnizleme.add(
        TopluKargoSatiri(
          adet: adet,
          alici: alici,
          adres: adres,
        ),
      );
    }

    setState(() {
      onizleme = yeniOnizleme;
      hatalar = yeniHatalar;
      onizlemeYapildi = true;
    });
  }

  Future<void> kargolariEkle() async {
    if (onizleme.isEmpty ||
        hatalar.isNotEmpty) {
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Kargoları Ekle',
          ),
          content: Text(
            '${onizleme.length} teslimat adresinden '
            'toplam $toplamKargo kargo eklenecek.\n\n'
            'Devam etmek istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Hayır',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Evet',
              ),
            ),
          ],
        );
      },
    );

    if (onay != true || !mounted) {
      return;
    }

    final sonuc = onizleme
        .map(
          (satir) => YeniTeslimatVerisi(
            adet: satir.adet,
            alici: satir.alici,
            adres: satir.adres,
          ),
        )
        .toList();

    Navigator.pop(
      context,
      sonuc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eklemeHazir =
        onizleme.isNotEmpty &&
            hatalar.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Toplu Kargo Ekle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          40,
        ),
        children: [
          const Text(
            'Toplu giriş formatı',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'Her kişiyi ayrı bir satıra yaz:',
          ),
          const SizedBox(
            height: 12,
          ),
          Container(
            padding: const EdgeInsets.all(
              14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                12,
              ),
              color: Colors.grey.shade200,
            ),
            child: const SelectableText(
              'ADET|ALICI|ADRES\n\n'
              '2|Abuzer Kadayıf|Anadolu Cad. No:14/5\n'
              '1|Metin Aday|Çambaşı Cad. No:13/4',
              style: TextStyle(
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          TextField(
            controller: topluController,
            minLines: 8,
            maxLines: 15,
            keyboardType:
                TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: 'Kargolar',
              alignLabelWithHint: true,
              hintText:
                  '2|Abuzer Kadayıf|Anadolu Cad. No:14/5\n'
                  '1|Metin Aday|Çambaşı Cad. No:13/4',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (onizlemeYapildi) {
                setState(() {
                  onizlemeYapildi = false;
                  onizleme = [];
                  hatalar = [];
                });
              }
            },
          ),
          const SizedBox(
            height: 14,
          ),
          FilledButton.icon(
            onPressed: onizle,
            icon: const Icon(
              Icons.preview_outlined,
            ),
            label: const Text(
              'Önizle',
            ),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 15,
              ),
            ),
          ),
          if (onizlemeYapildi) ...[
            const SizedBox(
              height: 28,
            ),
            const Divider(),
            const SizedBox(
              height: 16,
            ),
            if (hatalar.isNotEmpty) ...[
              Text(
                'Düzeltilmesi gereken satırlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .error,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ...hatalar.map(
                (hata) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 20,
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .error,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            hata,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(
                height: 18,
              ),
            ],
            if (onizleme.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: OnizlemeSayac(
                      baslik:
                          'Teslimat adresi',
                      sayi:
                          onizleme.length,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: OnizlemeSayac(
                      baslik:
                          'Toplam kargo',
                      sayi:
                          toplamKargo,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 22,
              ),
              const Text(
                'Önizleme',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              ...onizleme
                  .asMap()
                  .entries
                  .map(
                (entry) {
                  final index = entry.key;
                  final satir = entry.value;

                  return Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 8,
                    ),
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    decoration:
                        BoxDecoration(
                      border: Border.all(
                        color: Colors
                            .grey.shade300,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          child: Text(
                            '${index + 1}',
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                satir.alici,
                                style:
                                    const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                satir.adres,
                              ),
                              if (satir.adet >
                                  1) ...[
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  '${satir.adet} adet kargosu bulunmaktadır',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                    color: Theme.of(
                                            context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(
              height: 16,
            ),
            FilledButton.icon(
              onPressed: eklemeHazir
                  ? kargolariEkle
                  : null,
              icon: const Icon(
                Icons.done_all,
              ),
              label: Text(
                eklemeHazir
                    ? '$toplamKargo Kargoyu Ekle'
                    : 'Önce Hataları Düzelt',
              ),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// ADRES DÜZENLE
// ----------------------------------------------------

class AdresDuzenleSayfa extends StatefulWidget {
  final String mevcutAdres;

  const AdresDuzenleSayfa({
    super.key,
    required this.mevcutAdres,
  });

  @override
  State<AdresDuzenleSayfa> createState() {
    return _AdresDuzenleSayfaState();
  }
}

class _AdresDuzenleSayfaState
    extends State<AdresDuzenleSayfa> {
  late TextEditingController adresController;

  @override
  void initState() {
    super.initState();

    adresController = TextEditingController(
      text: widget.mevcutAdres,
    );
  }

  @override
  void dispose() {
    adresController.dispose();

    super.dispose();
  }

  void kaydet() {
    final adres = adresController.text.trim();

    if (adres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Adres boş bırakılamaz.',
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      adres,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adresi Düzenle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(
          20,
        ),
        children: [
          const Text(
            'Teslimat Adresi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          TextField(
            controller: adresController,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          FilledButton.icon(
            onPressed: kaydet,
            icon: const Icon(
              Icons.save_outlined,
            ),
            label: const Text(
              'Adresi Kaydet',
            ),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// NOT EKLE / DÜZENLE
// ----------------------------------------------------

class NotDuzenleSayfa extends StatefulWidget {
  final String mevcutNot;

  const NotDuzenleSayfa({
    super.key,
    required this.mevcutNot,
  });

  @override
  State<NotDuzenleSayfa> createState() {
    return _NotDuzenleSayfaState();
  }
}

class _NotDuzenleSayfaState
    extends State<NotDuzenleSayfa> {
  late TextEditingController notController;

  @override
  void initState() {
    super.initState();

    notController = TextEditingController(
      text: widget.mevcutNot,
    );
  }

  @override
  void dispose() {
    notController.dispose();

    super.dispose();
  }

  void kaydet() {
    Navigator.pop(
      context,
      notController.text.trim(),
    );
  }

  void notuSil() {
    Navigator.pop(
      context,
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mevcutNot.isEmpty
              ? 'Not Ekle'
              : 'Notu Düzenle',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(
          20,
        ),
        children: [
          const Text(
            'Teslimat Notu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          TextField(
            controller: notController,
            autofocus: true,
            textCapitalization:
                TextCapitalization.sentences,
            minLines: 3,
            maxLines: 7,
            decoration: const InputDecoration(
              hintText:
                  'Örn: Kapıyı çalmadan önce ara.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          FilledButton.icon(
            onPressed: kaydet,
            icon: const Icon(
              Icons.save_outlined,
            ),
            label: const Text(
              'Notu Kaydet',
            ),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),
          if (widget.mevcutNot.isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),
            OutlinedButton.icon(
              onPressed: notuSil,
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text(
                'Notu Sil',
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// KARGO SATIRI
// ----------------------------------------------------

class KargoSatiri extends StatelessWidget {
  final TeslimatGrubu grup;
  final int sira;

  final VoidCallback teslimEt;
  final VoidCallback teslimatiGeriAl;
  final VoidCallback uzunBas;

  const KargoSatiri({
    super.key,
    required this.grup,
    required this.sira,
    required this.teslimEt,
    required this.teslimatiGeriAl,
    required this.uzunBas,
  });

  @override
  Widget build(BuildContext context) {
    final teslimEdildi = grup.teslimEdildi;

    return GestureDetector(
      onLongPress: uzunBas,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 250,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: teslimEdildi
              ? Colors.grey.shade200
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            12,
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(
                milliseconds: 250,
              ),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: teslimEdildi
                    ? Colors.green
                    : Colors.transparent,
                border: Border.all(
                  width: 2,
                  color: teslimEdildi
                      ? Colors.green
                      : Theme.of(context)
                          .colorScheme
                          .primary,
                ),
              ),
              child: Center(
                child: teslimEdildi
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 30,
                      )
                    : Text(
                        '$sira',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${grup.ilkKargo.id.toString().padLeft(3, '0')}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: teslimEdildi
                          ? Colors.grey.shade600
                          : null,
                    ),
                  ),
                  if (grup.alici.isNotEmpty) ...[
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      grup.alici,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w600,
                        color: teslimEdildi
                            ? Colors.grey.shade600
                            : null,
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    grup.adres,
                    style: TextStyle(
                      fontSize: 15,
                      color: teslimEdildi
                          ? Colors.grey.shade600
                          : null,
                    ),
                  ),
                  if (grup.adet > 1) ...[
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      '${grup.adet} adet kargosu bulunmaktadır',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                        color: teslimEdildi
                            ? Colors.grey.shade600
                            : Theme.of(context)
                                .colorScheme
                                .primary,
                      ),
                    ),
                  ],
                  if (grup.not.isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),
                      child: Text(
                        grup.not,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'Düzenlemek için basılı tut',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 6,
            ),
            if (!teslimEdildi)
              IconButton(
                onPressed: teslimEt,
                tooltip: 'Teslim edildi',
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 31,
                  color: Colors.green,
                ),
              )
            else
              IconButton(
                onPressed:
                    teslimatiGeriAl,
                tooltip:
                    'Teslimatı geri al',
                icon: const Icon(
                  Icons.close,
                  size: 31,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// SAYAÇLAR
// ----------------------------------------------------

class Sayac extends StatelessWidget {
  final String baslik;
  final int sayi;

  const Sayac({
    super.key,
    required this.baslik,
    required this.sayi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$sayi',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class OnizlemeSayac extends StatelessWidget {
  final String baslik;
  final int sayi;

  const OnizlemeSayac({
    super.key,
    required this.baslik,
    required this.sayi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$sayi',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            baslik,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const KargoAnaSayfa();
  }
}