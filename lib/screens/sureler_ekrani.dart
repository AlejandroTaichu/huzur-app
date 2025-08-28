// lib/screens/sureler_ekrani.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huzur_app/models/cuz.dart';
import 'package:huzur_app/models/sure.dart';
import 'package:huzur_app/screens/auth/login_ekran.dart';
import 'package:huzur_app/screens/sure_detay_ekrani.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<Sure> tumSureler = [];
  List<Cuz> gruplanmisCuzler = [];
  List<Sure> aramaSonuclari = [];
  final TextEditingController _aramaController = TextEditingController();

  Sure? sonOkunanSure;
  int? sonOkunanAyetIndex;

  User? _user;
  bool _aramaYapiliyor = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _initialize();
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    await veriYukle();
    if (!mounted) return;
    await _sonOkunaniYukle();
  }

  Future<void> veriYukle() async {
    if (!mounted) return;
    final cevap = await rootBundle.loadString('assets/kuran_tr.json');
    if (!mounted) return;
    final List<dynamic> data = json.decode(cevap);
    final sureListesi =
        data.map((sureJson) => Sure.fromJson(sureJson)).toList();
    final cuzListesi = _sureleriCuzlereGoreGrupla(sureListesi);
    if (mounted) {
      setState(() {
        tumSureler = sureListesi;
        gruplanmisCuzler = cuzListesi;
      });
    }
  }

  List<Cuz> _sureleriCuzlereGoreGrupla(List<Sure> sureler) {
    final cuzBaslangicSureleri = [
      1,
      2,
      2,
      3,
      4,
      4,
      5,
      6,
      7,
      8,
      9,
      11,
      12,
      14,
      16,
      18,
      20,
      22,
      25,
      27,
      29,
      33,
      36,
      39,
      41,
      46,
      51,
      58,
      67,
      78
    ];
    List<Cuz> cuzler = [];
    for (int i = 0; i < 30; i++) {
      final int baslangicSureNo = cuzBaslangicSureleri[i];
      final int bitisSureNo = (i + 1 < 30) ? cuzBaslangicSureleri[i + 1] : 115;
      final cuzSureleri = sureler
          .where((s) => s.chapter >= baslangicSureNo && s.chapter < bitisSureNo)
          .toList();
      cuzler.add(Cuz(cuzNumarasi: i + 1, sureler: cuzSureleri));
    }
    return cuzler;
  }

  void _filtrele(String aramaMetni) {
    final String sorgu = aramaMetni.toLowerCase();
    setState(() {
      _aramaYapiliyor = sorgu.isNotEmpty;
      aramaSonuclari = tumSureler.where((sure) {
        final sureAdiKucukHarf = sure.name.toLowerCase();
        return sureAdiKucukHarf.contains(sorgu) ||
            sure.chapter.toString().contains(sorgu);
      }).toList();
    });
  }

  Future<void> _sonOkunaniYukle() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final int? sonOkunanSureNo = prefs.getInt('sonOkunanSureNo');
    final int? okunanAyetIndex = prefs.getInt('sonOkunanAyetIndex');

    if (sonOkunanSureNo != null && tumSureler.isNotEmpty) {
      try {
        final bulunanSure =
            tumSureler.firstWhere((s) => s.chapter == sonOkunanSureNo);
        if (mounted) {
          setState(() {
            sonOkunanSure = bulunanSure;
            sonOkunanAyetIndex = okunanAyetIndex;
          });
        }
      } catch (e) {
        print("Kaydedilmiş sure bulunamadı: $sonOkunanSureNo");
      }
    } else {
      if (mounted) {
        setState(() {
          sonOkunanSure = null;
          sonOkunanAyetIndex = null;
        });
      }
    }
  }

  Widget _buildSonOkunanKarti() {
    if (sonOkunanSure == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(Icons.bookmark, color: Colors.green.shade300),
        title: Text(
          'Kaldığın Yerden Devam Et',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text("${sonOkunanSure!.name} Suresi",
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SureDetay_Ekrani(
                sure: sonOkunanSure!,
                baslangicAyetIndex: sonOkunanAyetIndex,
              ),
            ),
          );
          _sonOkunaniYukle();
        },
      ),
    );
  }

  void _cikisYap() {
    FirebaseAuth.instance.signOut();
  }

  void _updateUserState() {
    if (mounted) {
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Sureler', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: InkWell(
              onTap: () {
                if (_user != null && _user!.isAnonymous) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginEkrani(),
                    ),
                  ).then((_) {
                    _updateUserState();
                  });
                } else if (_user != null) {
                  // Daha şık bir BottomSheet
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF101439),
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Giriş Yapıldı: ${_user!.email}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text("Çıkış Yap"),
                            onPressed: () {
                              _cikisYap();
                              _updateUserState();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(
                  _user != null && _user!.isAnonymous
                      ? Icons.person_add_alt_1
                      : Icons.person,
                  color: Colors.blue.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSonOkunanKarti(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _aramaController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Sure Ara...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filtrele,
            ),
          ),
          Expanded(
            child: _aramaYapiliyor
                ? _buildAramaSonucListesi()
                : _buildCuzListesi(),
          ),
        ],
      ),
    );
  }

  Widget _buildAramaSonucListesi() {
    return aramaSonuclari.isEmpty
        ? const Center(
            child: Text('Arama sonucu bulunamadı.',
                style: TextStyle(color: Colors.white)))
        : ListView.builder(
            itemCount: aramaSonuclari.length,
            itemBuilder: (context, index) {
              final sure = aramaSonuclari[index];
              return _buildSureKarti(sure);
            },
          );
  }

  Widget _buildCuzListesi() {
    return gruplanmisCuzler.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: gruplanmisCuzler.length,
            itemBuilder: (context, index) {
              final cuz = gruplanmisCuzler[index];
              if (cuz.sureler.isEmpty) return const SizedBox.shrink();
              return ExpansionTile(
                title: Text(
                  "${cuz.cuzNumarasi}. Cüz",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade300,
                    fontSize: 18,
                  ),
                ),
                children:
                    cuz.sureler.map((sure) => _buildSureKarti(sure)).toList(),
              );
            },
          );
  }

  Widget _buildSureKarti(Sure sure) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(
              sure.chapter.toString(),
              style: TextStyle(
                  color: Colors.blue.shade300, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text("${sure.name} Suresi",
              style: TextStyle(color: Colors.white)),
          subtitle: Text('${sure.verses.length} ayet',
              style: TextStyle(color: Colors.white.withOpacity(0.7))),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SureDetay_Ekrani(sure: sure),
              ),
            );
            _sonOkunaniYukle();
          },
        ),
      ),
    );
  }
}
