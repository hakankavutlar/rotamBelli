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
  final String adres;
  KargoDurumu durum;

  Kargo({
    required this.id,
    required this.adres,
    this.durum = KargoDurumu.pending,
  });
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
    Kargo(id: 1, adres: 'Anadolu Cad. No:15'),
    Kargo(id: 2, adres: 'Çambaşı Cad. No:22'),
    Kargo(id: 3, adres: 'Atatürk Bulvarı No:8'),
    Kargo(id: 4, adres: 'Avrupa Cad. No:36'),
    Kargo(id: 5, adres: 'Kurtuluş Cad. No:12'),
  ];

  int get bekleyenSayisi {
    return kargolar
        .where((kargo) => kargo.durum == KargoDurumu.pending)
        .length;
  }

  int get teslimEdilenSayisi {
    return kargolar
        .where((kargo) => kargo.durum == KargoDurumu.delivered)
        .length;
  }

  int yeniKargoIdOlustur() {
    if (kargolar.isEmpty) {
      return 1;
    }

    final enBuyukId = kargolar
        .map((kargo) => kargo.id)
        .reduce((a, b) => a > b ? a : b);

    return enBuyukId + 1;
  }

  Future<bool> teslimOnayiSor(Kargo kargo) async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Teslim Edildi'),
          content: Text(
            '#${kargo.id.toString().padLeft(3, '0')} numaralı kargoyu '
            'teslim edildi olarak işaretlemek istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Hayır'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );

    return sonuc ?? false;
  }

  Future<bool> teslimIptalOnayiSor(Kargo kargo) async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Teslimatı Geri Al'),
          content: Text(
            '#${kargo.id.toString().padLeft(3, '0')} numaralı kargoyu '
            'tekrar bekleyen durumuna almak istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Hayır'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );

    return sonuc ?? false;
  }

  Future<void> teslimEt(Kargo kargo) async {
    final onaylandi = await teslimOnayiSor(kargo);

    if (!onaylandi || !mounted) {
      return;
    }

    setState(() {
      kargo.durum = KargoDurumu.delivered;
    });
  }

  Future<void> teslimatiGeriAl(Kargo kargo) async {
    final onaylandi = await teslimIptalOnayiSor(kargo);

    if (!onaylandi || !mounted) {
      return;
    }

    setState(() {
      kargo.durum = KargoDurumu.pending;
    });
  }

  Future<void> kargoEkleMenuAc() async {
    final secim = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                    'Tek bir teslimat adresi ekle',
                  ),
                  onTap: () {
                    Navigator.pop(context, 'tek');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.upload_file_outlined,
                    size: 30,
                  ),
                  title: const Text(
                    'Toplu Ekle',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Excel / CSV ile toplu kargo yükle',
                  ),
                  onTap: () {
                    Navigator.pop(context, 'toplu');
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
      final adres = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const TekKargoEkleSayfa(),
        ),
      );

      if (!mounted || adres == null || adres.isEmpty) {
        return;
      }

      setState(() {
        kargolar.add(
          Kargo(
            id: yeniKargoIdOlustur(),
            adres: adres,
          ),
        );
      });
    }

    if (secim == 'toplu' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Toplu ekleme özelliğini daha sonra yapacağız.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Sayac(
                    baslik: 'Bekleyen',
                    sayi: bekleyenSayisi,
                  ),
                ),
                const SizedBox(width: 12),
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
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
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
            child: kargolar.isEmpty
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
                    itemCount: kargolar.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 4);
                    },
                    itemBuilder: (context, index) {
                      final kargo = kargolar[index];

                      return KargoSatiri(
                        kargo: kargo,
                        sira: index + 1,
                        teslimEt: () {
                          teslimEt(kargo);
                        },
                        teslimatiGeriAl: () {
                          teslimatiGeriAl(kargo);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: kargoEkleMenuAc,
        icon: const Icon(Icons.add),
        label: const Text('Kargo Ekle'),
      ),
    );
  }
}

class TekKargoEkleSayfa extends StatefulWidget {
  const TekKargoEkleSayfa({super.key});

  @override
  State<TekKargoEkleSayfa> createState() => _TekKargoEkleSayfaState();
}

class _TekKargoEkleSayfaState extends State<TekKargoEkleSayfa> {
  final TextEditingController adresController = TextEditingController();

  @override
  void dispose() {
    adresController.dispose();
    super.dispose();
  }

  void kargoEkle() {
    final adres = adresController.text.trim();

    if (adres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir adres gir.'),
        ),
      );

      return;
    }

    Navigator.pop(context, adres);
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Teslimat Adresi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adresController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Örn: Anadolu Cad. No:15',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: kargoEkle,
              icon: const Icon(Icons.add),
              label: const Text('Kargoyu Ekle'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KargoSatiri extends StatelessWidget {
  final Kargo kargo;
  final int sira;
  final VoidCallback teslimEt;
  final VoidCallback teslimatiGeriAl;

  const KargoSatiri({
    super.key,
    required this.kargo,
    required this.sira,
    required this.teslimEt,
    required this.teslimatiGeriAl,
  });

  @override
  Widget build(BuildContext context) {
    final teslimEdildi = kargo.durum == KargoDurumu.delivered;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: teslimEdildi
            ? Colors.grey.shade200
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
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
                    : Theme.of(context).colorScheme.primary,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${kargo.id.toString().padLeft(3, '0')}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: teslimEdildi
                        ? Colors.grey.shade600
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kargo.adres,
                  style: TextStyle(
                    fontSize: 16,
                    color: teslimEdildi
                        ? Colors.grey.shade600
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
              onPressed: teslimatiGeriAl,
              tooltip: 'Teslimatı geri al',
              icon: const Icon(
                Icons.close,
                size: 31,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
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
          const SizedBox(height: 2),
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