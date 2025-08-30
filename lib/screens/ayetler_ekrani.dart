// lib/screens/ayetler_ekrani.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huzur_app/models/sure.dart';
import 'package:huzur_app/models/ayet.dart';
import 'package:huzur_app/screens/sure_detay_ekrani.dart'; // Sure Detay ekranını import ediyoruz

class AyetlerEkrani extends StatefulWidget {
  const AyetlerEkrani({super.key});

  @override
  State<AyetlerEkrani> createState() => _AyetlerEkraniState();
}

class _AyetlerEkraniState extends State<AyetlerEkrani> {
  List<Sure> _tumSureler = [];

  // Sadece günün ayetini değil, öncesini, sonrasını ve ait olduğu sureyi de tutuyoruz
  Sure? _gununAyetSuresi;
  Ayet? _gununAyet;
  Ayet? _ayetOnceki;
  Ayet? _ayetSonraki;
  int _gununAyetIndex = 0; // Günün ayetinin index'i

  // Örnek konular listesi
  final List<Map<String, dynamic>> _konular = [
    {'isim': 'Sabır', 'ikon': Icons.timelapse},
    {'isim': 'Şükür', 'ikon': Icons.sentiment_satisfied_alt},
    {'isim': 'Dua', 'ikon': Icons.volunteer_activism},
    {'isim': 'İnanç', 'ikon': Icons.shield_moon_outlined},
    {'isim': 'Aile', 'ikon': Icons.family_restroom},
    {'isim': 'Tövbe', 'ikon': Icons.replay_circle_filled},
    {'isim': 'Adalet', 'ikon': Icons.gavel},
    {'isim': 'Yardımlaşma', 'ikon': Icons.group_add},
  ];

  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _veriYukle();
  }

  Future<void> _veriYukle() async {
    try {
      final cevap = await rootBundle.loadString('assets/kuran_tr.json');
      final dynamic rawData = json.decode(cevap);

      List<dynamic> data;
      if (rawData is List<dynamic>) {
        data = rawData;
      } else if (rawData is Map<String, dynamic>) {
        // JSON bir obje ise, ilk array değerini al
        final firstKey = rawData.keys.first;
        data = rawData[firstKey] as List<dynamic>;
      } else {
        throw Exception("JSON formatı desteklenmiyor");
      }

      _tumSureler = data.map((sureJson) {
        // JSON formatınıza uygun olarak Sure oluştur
        final sureData = Map<String, dynamic>.from(sureJson);

        // id'yi chapter'a çevir
        if (sureData.containsKey('id')) {
          sureData['chapter'] = sureData['id'];
        }

        // transliteration'ı name olarak kullan (Türkçe isim için)
        if (sureData.containsKey('translation')) {
          sureData['name'] = sureData['translation'];
        }

        // type'ı revelation'a çevir
        if (sureData.containsKey('type')) {
          sureData['revelation'] = sureData['type'];
        }

        return Sure.fromJson(sureData);
      }).toList();

      _gununAyetiniSec();

      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    } catch (e) {
      print("Veri yükleme hatası: $e");
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

  void _gununAyetiniSec() {
    if (_tumSureler.isEmpty) return;

    final random = Random();

    // Boş olmayan bir sure bulana kadar dene
    Sure? rastgeleSure;
    int deneme = 0;
    while (deneme < 10) {
      // Sonsuz döngüye girmemek için limit
      rastgeleSure = _tumSureler[random.nextInt(_tumSureler.length)];
      if (rastgeleSure.verses.isNotEmpty) break;
      deneme++;
    }

    if (rastgeleSure == null || rastgeleSure.verses.isEmpty) {
      print("Uygun sure bulunamadı");
      return;
    }

    final rastgeleAyetIndex = random.nextInt(rastgeleSure.verses.length);

    setState(() {
      _gununAyetSuresi = rastgeleSure!; // ! ekledik çünkü null kontrolü yaptık
      _gununAyet = rastgeleSure.verses[rastgeleAyetIndex];
      _gununAyetIndex = rastgeleAyetIndex;

      // Önceki ayeti bul (eğer ilk ayet değilse)
      _ayetOnceki = (rastgeleAyetIndex > 0)
          ? rastgeleSure.verses[rastgeleAyetIndex - 1]
          : null;

      // Sonraki ayeti bul (eğer son ayet değilse)
      _ayetSonraki = (rastgeleAyetIndex < rastgeleSure.verses.length - 1)
          ? rastgeleSure.verses[rastgeleAyetIndex + 1]
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Ayetler', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _gununAyetiniSec,
            tooltip: 'Yeni Ayet Seç',
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Ayetler yükleniyor...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildGununAyetiKarti(),
                const SizedBox(height: 24),
                _buildBaslik("Konulara Göre Ayetler"),
                const SizedBox(height: 16),
                _buildKonuGridi(),
              ],
            ),
    );
  }

  Widget _buildBaslik(String metin) {
    return Text(
      metin,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildGununAyetiKarti() {
    if (_gununAyet == null || _gununAyetSuresi == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Center(
          child: Text(
            'Henüz ayet seçilmedi',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withOpacity(0.5),
            Colors.purple.shade900.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_border, color: Colors.yellow.shade600),
              const SizedBox(width: 8),
              Text(
                "Günün Ayeti",
                style: TextStyle(
                  color: Colors.yellow.shade600,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Önceki ayet (eğer varsa)
          if (_ayetOnceki != null) ...[
            Text(
              '"${_ayetOnceki!.translation}"',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.4),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Ana ayet
          Text(
            '"${_gununAyet!.translation}"',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),

          // Sonraki ayet (eğer varsa)
          if (_ayetSonraki != null) ...[
            const SizedBox(height: 12),
            Text(
              '"${_ayetSonraki!.translation}"',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.4),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  "${_gununAyetSuresi!.name} Suresi, ${_gununAyet!.id}. Ayet",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.8),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
                icon: const Icon(Icons.menu_book, size: 18),
                label: const Text("Surede Oku"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SureDetay_Ekrani(
                        sure: _gununAyetSuresi!,
                        baslangicAyetIndex: _gununAyetIndex,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKonuGridi() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _konular.length,
      itemBuilder: (context, index) {
        final konu = _konular[index];
        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${konu['isim']} konusu yakında eklenecek.'),
                backgroundColor: Colors.blue.shade900,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  konu['ikon'],
                  size: 40,
                  color: Colors.blue.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  konu['isim'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
