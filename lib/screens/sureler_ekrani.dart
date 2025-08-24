import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huzur_app/models/ayet.dart';
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
  // --- YENİ GRUPLANMIŞ LİSTE ---
  List<Cuz> gruplanmisCuzler = [];
  // Arama sonuçları için yine düz bir liste tutacağız
  List<Sure> aramaSonuclari = [];
  final TextEditingController _aramaController = TextEditingController();
  Sure? sonOkunanSure;
  User? _user;
  bool _aramaYapiliyor =
      false; // Arama çubuğuna bir şey yazılıp yazılmadığını kontrol etmek için

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) setState(() => _user = user);
    });
    _initialize();
  }

  Future<void> _initialize() async {
    await veriYukle();
    await _sonOkunaniYukle();
  }

  Future<void> veriYukle() async {
    final cevap = await rootBundle.loadString('assets/kuran_tr.json');
    final List<dynamic> data = json.decode(cevap);

    // Önce tüm sureleri bir listeye alıyoruz
    final sureListesi = data
        .map((sureJson) => Sure.fromJson(sureJson))
        .toList();

    // Sonra bu listeyi cüzlere göre grupluyoruz
    final cuzListesi = _sureleriCuzlereGoreGrupla(sureListesi);

    if (mounted) {
      setState(() {
        tumSureler = sureListesi;
        gruplanmisCuzler = cuzListesi;
      });
    }
  }

  // --- YENİ GRUPLAMA FONKSİYONU ---
  List<Cuz> _sureleriCuzlereGoreGrupla(List<Sure> sureler) {
    // Cüzlerin hangi sureden başladığını belirten basit bir harita
    // Not: Bu yaklaşık bir gruplamadır, çünkü cüzler ayet ortasında başlayabilir.
    // Arayüz gösterimi için bu yöntem yeterlidir.
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
        // Sadece sure adını değil, numarasını da aramaya dahil edelim
        return sureAdiKucukHarf.contains(sorgu) ||
            sure.chapter.toString().contains(sorgu);
      }).toList();
    });
  }

  // ... _sonOkunaniYukle, _sonOkunaniKaydet, _buildSonOkunanKarti, _cikisYap fonksiyonları aynı kalıyor ...
  Future<void> _sonOkunaniYukle() async {
    final prefs = await SharedPreferences.getInstance();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /* ... AppBar kodu aynı ... */ title: const Text(
          'Huzur Uygulaması - Sureler',
        ),
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
                  );
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
            /* ... Arama kutusu aynı ... */ padding: const EdgeInsets.all(8.0),
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

          // --- LİSTE GÖRÜNÜMÜNÜN YENİ HALİ ---
          Expanded(
            // Eğer arama yapılıyorsa, arama sonuçlarını göster.
            // Yapılmıyorsa, cüzlere göre gruplanmış listeyi göster.
            child: _aramaYapiliyor
                ? _buildAramaSonucListesi()
                : _buildCuzListesi(),
          ),
        ],
      ),
    );
  }

  // --- YENİ WIDGET: ARAMA SONUÇLARI LİSTESİ ---
  Widget _buildAramaSonucListesi() {
    return aramaSonuclari.isEmpty
        ? const Center(child: Text('Arama sonucu bulunamadı.'))
        : ListView.builder(
            itemCount: aramaSonuclari.length,
            itemBuilder: (context, index) {
              final sure = aramaSonuclari[index];
              return _buildSureKarti(
                sure,
              ); // Tekrarı önlemek için kartı bir metoda taşıdık
            },
          );
  }

  // --- YENİ WIDGET: CÜZLERE GÖRE GRUPLANMIŞ LİSTE ---
  Widget _buildCuzListesi() {
    return gruplanmisCuzler.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: gruplanmisCuzler.length,
            itemBuilder: (context, index) {
              final cuz = gruplanmisCuzler[index];
              // Cüzde sure yoksa o cüz başlığını gösterme
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

  // --- YENİ WIDGET: HER BİR SURE KARTI (TEKRARI ÖNLEMEK İÇİN) ---
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
