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

  // GÜNCELLENDİ: Sadece günün ayetini değil, öncesini, sonrasını ve ait olduğu sureyi de tutuyoruz
  Sure? _gununAyetSuresi;
  Ayet? _gununAyet;
  Ayet? _ayetOnceki;
  Ayet? _ayetSonraki;

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

  @override
  void initState() {
    super.initState();
    _veriYukle();
  }

  Future<void> _veriYukle() async {
    final cevap = await rootBundle.loadString('assets/kuran_tr.json');
    final List<dynamic> data = json.decode(cevap);
    _tumSureler = data.map((sureJson) => Sure.fromJson(sureJson)).toList();
    _gununAyetiniSec();
    if (mounted) {
      setState(() {});
    }
  }

  void _gununAyetiniSec() {
    if (_tumSureler.isEmpty) return;

    final random = Random();
    final rastgeleSure = _tumSureler[random.nextInt(_tumSureler.length)];
    // Tek ayetli surelerde hata almamak için kontrol ekleyelim
    if (rastgeleSure.verses.isEmpty) {
      _gununAyetiniSec(); // Eğer sure boşsa, tekrar seç
      return;
    }
    final rastgeleAyetIndex = random.nextInt(rastgeleSure.verses.length);

    setState(() {
      _gununAyetSuresi = rastgeleSure;
      _gununAyet = rastgeleSure.verses[rastgeleAyetIndex];

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
      ),
      body: _tumSureler.isEmpty
          ? const Center(child: CircularProgressIndicator())
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
      style: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildGununAyetiKarti() {
    if (_gununAyet == null || _gununAyetSuresi == null) {
      return const SizedBox.shrink();
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
          if (_ayetOnceki != null)
            Text(
              '"${_ayetOnceki!.translation}"',
              style: TextStyle(
                fontSize: 17,
                color: Colors.white.withOpacity(0.5),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          if (_ayetOnceki != null) const SizedBox(height: 12),
          Text(
            '"${_gununAyet!.translation}"',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          if (_ayetSonraki != null) const SizedBox(height: 12),
          if (_ayetSonraki != null)
            Text(
              '"${_ayetSonraki!.translation}"',
              style: TextStyle(
                fontSize: 17,
                color: Colors.white.withOpacity(0.5),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  "${_gununAyetSuresi!.name} Suresi, ${_gununAyet!.verse}. Ayet",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.8)),
                icon: Icon(Icons.menu_book, size: 18),
                label: Text("Surede Oku"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SureDetay_Ekrani(
                        sure: _gununAyetSuresi!,
                        baslangicAyetIndex: _gununAyet!.verse - 1,
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
                  content: Text('${konu['isim']} konusu yakında eklenecek.')),
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
