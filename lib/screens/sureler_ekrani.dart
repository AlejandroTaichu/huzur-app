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
  User? _user;
  bool _aramaYapiliyor = false;

  @override
  void initState() {
    super.initState();
    // ❌ Bu listener'ı kaldırıyoruz - AuthYonlendirme hallediyor
    // FirebaseAuth.instance.authStateChanges().listen((User? user) {
    //   if (mounted) setState(() => _user = user);
    // });

    // ✅ İlk user state'ini al - tek sefer
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

    final sureListesi = data
        .map((sureJson) => Sure.fromJson(sureJson))
        .toList();
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
      78,
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
    if (sonOkunanSureNo != null && tumSureler.isNotEmpty) {
      try {
        final bulunanSure = tumSureler.firstWhere(
          (s) => s.chapter == sonOkunanSureNo,
        );
        if (mounted) {
          setState(() {
            sonOkunanSure = bulunanSure;
          });
        }
      } catch (e) {
        print("Kaydedilmiş sure bulunamadı: $sonOkunanSureNo");
      }
    }
  }

  Future<void> _sonOkunaniKaydet(Sure sure) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sonOkunanSureNo', sure.chapter);
    }
  }

  Widget _buildSonOkunanKarti() {
    if (sonOkunanSure == null || (_user != null && _user!.isAnonymous)) {
      return const SizedBox.shrink();
    }
    return Card(
      color: Colors.green[50],
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: const Icon(Icons.bookmark, color: Colors.green),
        title: const Text(
          'Kaldığın Yerden Devam Et',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${sonOkunanSure!.name} Suresi"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SureDetay_Ekrani(sure: sonOkunanSure!),
            ),
          );
        },
      ),
    );
  }

  void _cikisYap() {
    FirebaseAuth.instance.signOut();
  }

  // ✅ User state'ini manuel güncelleme fonksiyonu
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
      appBar: AppBar(
        title: const Text('Huzur Uygulaması - Sureler'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
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
                    // Login'den döndükten sonra user state'ini güncelle
                    _updateUserState();
                  });
                } else if (_user != null) {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Giriş Yapıldı: ${_user!.email}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
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
                backgroundColor: Colors.green[100],
                child: Icon(
                  _user != null && _user!.isAnonymous
                      ? Icons.person_add_alt_1
                      : Icons.person,
                  color: Colors.green[900],
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
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _aramaController,
              decoration: InputDecoration(
                labelText: 'Sure Ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
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
        ? const Center(child: Text('Arama sonucu bulunamadı.'))
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
                    color: Colors.green[800],
                  ),
                ),
                children: cuz.sureler
                    .map((sure) => _buildSureKarti(sure))
                    .toList(),
              );
            },
          );
  }

  Widget _buildSureKarti(Sure sure) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Text(
            sure.chapter.toString(),
            style: TextStyle(color: Colors.green[900]),
          ),
        ),
        title: Text("${sure.name} Suresi"),
        subtitle: Text('${sure.verses.length} ayet'),
        onTap: () {
          _sonOkunaniKaydet(sure);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SureDetay_Ekrani(sure: sure),
            ),
          );
        },
      ),
    );
  }
}
