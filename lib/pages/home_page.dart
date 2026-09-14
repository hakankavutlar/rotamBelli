import 'dart:async';

import 'package:flutter/material.dart';

import '../models/kargo_store.dart';
import '../models/rota_sonucu.dart';
import '../services/rota_hesaplama_service.dart';
import 'map_page.dart';

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

class KargoAnaSayfa extends StatefulWidget {
  const KargoAnaSayfa({super.key});

  @override
  State<KargoAnaSayfa> createState() => _KargoAnaSayfaState();
}

class _KargoAnaSayfaState extends State<KargoAnaSayfa> {
  List<Kargo> get kargolar => kargoStore.kargolar;

  int get bekleyenSayisi => kargoStore.bekleyenSayisi;

  int get teslimEdilenSayisi => kargoStore.teslimEdilenSayisi;

  List<TeslimatGrubu> get teslimatGruplari =>
      kargoStore.teslimatGruplari;

  @override
  void initState() {
    super.initState();
    kargoStore.addListener(_storeDegisti);
  }

  @override
  void dispose() {
    kargoStore.removeListener(_storeDegisti);
    super.dispose();
  }

  void _storeDegisti() {
    if (mounted) {
      setState(() {});
    }
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

    kargoStore.teslimEt(grup);
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

    kargoStore.teslimatiGeriAl(grup);
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

    kargoStore.notGuncelle(
      grup,
      yeniNot,
    );
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

    kargoStore.adresGuncelle(
      grup,
      yeniAdres.trim(),
    );
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

      kargoStore.teslimatEkle(
        adet: yeniTeslimat.adet,
        alici: yeniTeslimat.alici,
        adres: yeniTeslimat.adres,
      );
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

      for (final teslimat in yeniTeslimatlar) {
        kargoStore.teslimatEkle(
          adet: teslimat.adet,
          alici: teslimat.alici,
          adres: teslimat.adres,
        );

        toplamEklenen += teslimat.adet;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$toplamEklenen kargo başarıyla eklendi.',
          ),
        ),
      );
    }
  }

  Future<void> sifirlamaOnayiAc() async {
    final onaylandi = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const _SifirlamaOnayDialogu();
      },
    );

    if (onaylandi != true || !mounted) {
      return;
    }

    await kargoStore.tumVerileriSifirla();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tüm kargolar silindi.',
        ),
      ),
    );
  }

  Future<void> rotaHesaplamaTaslagiAc() async {
    final bekleyenGruplar = teslimatGruplari
        .where((grup) => !grup.teslimEdildi)
        .toList();

    final sonuc = await showDialog<_RotaTaslakSecimi>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _RotaHesaplamaDialogu(
          gruplar: bekleyenGruplar,
        );
      },
    );

    if (sonuc == null || !mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const _RotaHesaplaniyorDialogu();
      },
    );

    try {
      final rota = await RotaHesaplamaService.instance.hesapla(
        gruplar: teslimatGruplari,
        baslangicTeslimatId:
            sonuc.baslangicGrubu.teslimatId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();

      await showDialog<void>(
        context: context,
        builder: (context) {
          return _RotaSonucDialogu(
            rota: rota,
          );
        },
      );
    } on RotaHesaplamaHatasi catch (hata) {
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Rota Hesaplanamadı',
            ),
            content: Text(
              hata.mesaj,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Tamam',
                ),
              ),
            ],
          );
        },
      );
    } catch (hata) {
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Rota Hesaplanamadı',
            ),
            content: Text(
              'Beklenmeyen bir hata oluştu: $hata',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Tamam',
                ),
              ),
            ],
          );
        },
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
            ),
            tooltip: 'Menü',
            onSelected: (secim) {
              if (secim == 'sifirla') {
                sifirlamaOnayiAc();
              }

              if (secim == 'rota_hesapla') {
                rotaHesaplamaTaslagiAc();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'sifirla',
                  child: Text(
                    'Sıfırla',
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'rota_hesapla',
                  child: Text(
                    'Rota Hesapla',
                  ),
                ),
              ];
            },
          ),
        ],
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
// SIFIRLAMA ONAY PENCERESİ
// ----------------------------------------------------

class _SifirlamaOnayDialogu extends StatefulWidget {
  const _SifirlamaOnayDialogu();

  @override
  State<_SifirlamaOnayDialogu> createState() {
    return _SifirlamaOnayDialoguState();
  }
}

class _SifirlamaOnayDialoguState
    extends State<_SifirlamaOnayDialogu> {
  int kalanSaniye = 3;
  Timer? _sayac;

  @override
  void initState() {
    super.initState();

    _sayac = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (kalanSaniye <= 1) {
          timer.cancel();

          setState(() {
            kalanSaniye = 0;
          });

          return;
        }

        setState(() {
          kalanSaniye--;
        });
      },
    );
  }

  @override
  void dispose() {
    _sayac?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sifirlanabilir = kalanSaniye == 0;

    return AlertDialog(
      title: const Text(
        'Sıfırlamak istediğinize emin misiniz?',
      ),
      content: const Text(
        'Bu işlem teslim edilecek ve teslim edilmiş '
        'bütün kargoları kalıcı olarak siler.',
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
            'Geri',
          ),
        ),
        FilledButton(
          onPressed: sifirlanabilir
              ? () {
                  Navigator.pop(
                    context,
                    true,
                  );
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                Colors.grey.shade300,
            disabledForegroundColor:
                Colors.grey.shade600,
          ),
          child: Text(
            sifirlanabilir
                ? 'Sıfırla'
                : 'Sıfırla ($kalanSaniye)',
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// ROTA HESAPLAMA TASARIMI
// ----------------------------------------------------

class _RotaTaslakSecimi {
  final TeslimatGrubu baslangicGrubu;
  final String bitisNoktasi;

  const _RotaTaslakSecimi({
    required this.baslangicGrubu,
    required this.bitisNoktasi,
  });
}

class _RotaHesaplamaDialogu extends StatefulWidget {
  final List<TeslimatGrubu> gruplar;

  const _RotaHesaplamaDialogu({
    required this.gruplar,
  });

  @override
  State<_RotaHesaplamaDialogu> createState() {
    return _RotaHesaplamaDialoguState();
  }
}

class _RotaHesaplamaDialoguState extends State<_RotaHesaplamaDialogu> {
  TeslimatGrubu? seciliBaslangic;
  String? seciliBitis;

  bool get onaylanabilir {
    return seciliBaslangic != null && seciliBitis != null;
  }

  String _grupBaslik(TeslimatGrubu grup) {
    if (grup.alici.isNotEmpty) {
      return grup.alici;
    }

    return '#${grup.ilkKargo.id.toString().padLeft(3, '0')}';
  }

  String _grupAltMetin(TeslimatGrubu grup) {
    if (grup.adet > 1) {
      return '${grup.adres}\n${grup.adet} adet kargo';
    }

    return grup.adres;
  }

  Future<void> _baslangicSec() async {
    if (widget.gruplar.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Kargo Yok',
            ),
            content: const Text(
              'Başlangıç noktası seçebilmek için listede en az bir kargo olmalı.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Tamam',
                ),
              ),
            ],
          );
        },
      );

      return;
    }

    if (!mounted) {
      return;
    }

    final secim = await showModalBottomSheet<TeslimatGrubu>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.70,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    12,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Başlangıç Noktası Seç',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.gruplar.length,
                    separatorBuilder: (context, index) {
                      return const Divider(
                        height: 1,
                      );
                    },
                    itemBuilder: (context, index) {
                      final grup = widget.gruplar[index];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            '${index + 1}',
                          ),
                        ),
                        title: Text(
                          _grupBaslik(grup),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _grupAltMetin(grup),
                        ),
                        trailing: seciliBaslangic?.teslimatId == grup.teslimatId
                            ? const Icon(
                                Icons.check_circle,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(
                            context,
                            grup,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (secim == null || !mounted) {
      return;
    }

    setState(() {
      seciliBaslangic = secim;
    });
  }

  void _bitisSec() {
    setState(() {
      seciliBitis = 'En Stratejik Nokta';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.route_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Expanded(
                    child: Text(
                      'Rota Hesapla',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 22,
              ),
              _RotaSecimKutusu(
                baslik: 'Başlangıç Noktası',
                deger: seciliBaslangic == null
                    ? 'Listeden bir kargo seç'
                    : '${_grupBaslik(seciliBaslangic!)}\n${_grupAltMetin(seciliBaslangic!)}',
                icon: Icons.trip_origin,
                onTap: _baslangicSec,
              ),
              const SizedBox(
                height: 16,
              ),
              _RotaSecimKutusu(
                baslik: 'Final Noktası',
                deger: seciliBitis ?? 'Seçmek için dokun',
                icon: Icons.flag_outlined,
                onTap: _bitisSec,
              ),
              const SizedBox(
                height: 28,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: onaylanabilir
                          ? () {
                              Navigator.pop(
                                context,
                                _RotaTaslakSecimi(
                                  baslangicGrubu: seciliBaslangic!,
                                  bitisNoktasi: seciliBitis!,
                                ),
                              );
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Onayla',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RotaSecimKutusu extends StatelessWidget {
  final String baslik;
  final String deger;
  final IconData icon;
  final VoidCallback onTap;

  const _RotaSecimKutusu({
    required this.baslik,
    required this.deger,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          18,
        ),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(
            16,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black26,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(
              18,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Text(
                      deger,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// ROTA HESAPLAMA DURUM / SONUÇ PENCERELERİ
// ----------------------------------------------------

class _RotaHesaplaniyorDialogu extends StatelessWidget {
  const _RotaHesaplaniyorDialogu();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          SizedBox(
            width: 18,
          ),
          Expanded(
            child: Text(
              'Gerçek yol mesafeleri alınıyor ve rota hesaplanıyor...',
            ),
          ),
        ],
      ),
    );
  }
}

class _RotaSonucDialogu extends StatelessWidget {
  final RotaSonucu rota;

  const _RotaSonucDialogu({
    required this.rota,
  });

  @override
  Widget build(BuildContext context) {
    final mesafeMetni = rota.toplamMesafeKm < 1
        ? '${rota.toplamMesafeMetre.round()} m'
        : '${rota.toplamMesafeKm.toStringAsFixed(1)} km';

    final sureMetni = rota.tahminiDakika <= 0
        ? '0 dk'
        : '${rota.tahminiDakika} dk';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.route,
          ),
          SizedBox(
            width: 10,
          ),
          Text(
            'Rota Hesaplandı',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(
                    Icons.pin_drop_outlined,
                    size: 18,
                  ),
                  label: Text(
                    '${rota.duraklar.length} durak',
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.straighten,
                    size: 18,
                  ),
                  label: Text(
                    mesafeMetni,
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.schedule,
                    size: 18,
                  ),
                  label: Text(
                    sureMetni,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              'Final: ${rota.duraklar.isEmpty ? '-' : rota.duraklar.last.baslik}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rota.duraklar.length,
                separatorBuilder: (context, index) {
                  return const Divider(
                    height: 1,
                  );
                },
                itemBuilder: (context, index) {
                  final durak = rota.duraklar[index];

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 17,
                      child: Text(
                        '${index + 1}',
                      ),
                    ),
                    title: Text(
                      durak.baslik,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      durak.toplamKargoAdedi > 1
                          ? '${durak.adres}\n${durak.toplamKargoAdedi} adet kargo'
                          : durak.adres,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Tamam',
          ),
        ),
      ],
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

  Future<void> _pinOlusturmaSor(
    BuildContext context,
  ) async {
    if (grup.konumuVar) {
      return;
    }

    final pinOlustur =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Haritadan Pin Oluşturmak İster Misiniz?',
          ),
          content: Text(
            '${grup.adres}\n\n'
            'Bu adres için haritada bir nokta seçerek '
            'manuel pin oluşturabilirsiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Hayır',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Evet',
              ),
            ),
          ],
        );
      },
    );

    if (pinOlustur != true ||
        !context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return MapPage(
            ilkSeciliTeslimatId:
                grup.teslimatId,
            pinOlusturmaModu: true,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teslimEdildi = grup.teslimEdildi;
    final colorScheme = Theme.of(context).colorScheme;

    final Color teslimatRengi;

    if (teslimEdildi) {
      teslimatRengi = Colors.green;
    } else if (!grup.konumuVar) {
      // Haritada henüz pini olmayan teslimatlar:
      // hafif saydam #F7D439.
      teslimatRengi =
          const Color(0xFFF7D439).withValues(
        alpha: 0.72,
      );
    } else {
      // MapPage'deki normal pin rengi.
      final temelPinRengi = colorScheme.secondary;

      // MapPage'deki "yaklaşık konum" rengiyle
      // birebir aynı hesap.
      teslimatRengi = grup.konumYaklasik
          ? Color.lerp(
                temelPinRengi,
                Colors.white,
                0.45,
              ) ??
              temelPinRengi
          : temelPinRengi;
    }

    final numaraRengi =
        teslimatRengi.computeLuminance() > 0.55
            ? Colors.black
            : Colors.white;

    final pinsiz = !grup.konumuVar;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: pinsiz
            ? () {
                _pinOlusturmaSor(
                  context,
                );
              }
            : null,
        onLongPress: uzunBas,
        borderRadius: BorderRadius.circular(
          12,
        ),
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
                color: teslimatRengi,
                border: Border.all(
                  width: 2,
                  color: teslimatRengi,
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
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                          color: numaraRengi,
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