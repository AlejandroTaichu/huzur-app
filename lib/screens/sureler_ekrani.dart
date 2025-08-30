// lib/screens/sureler_ekrani.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huzur_app/models/cuz.dart';
import 'package:huzur_app/models/sure.dart';
import 'package:huzur_app/screens/sure_detay_ekrani.dart';
import 'package:huzur_app/services/login_ekran.dart';
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

  // Yükleme ve Hata durumları için state'ler
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _initialize();
  }

  Future<void> _initialize() async {
    await veriYukle();
    if (mounted && _errorMessage == null) {
      await _sonOkunaniYukle();
    }
  }

  Future<void> veriYukle() async {
    try {
      if (!mounted) return;

      print("JSON dosyası yüklenmeye başladı...");

      final cevap = await rootBundle.loadString('assets/kuran_tr.json');
      print("JSON dosyası başarıyla yüklendi. Boyut: ${cevap.length} karakter");

      if (!mounted) return;

      final dynamic rawData = json.decode(cevap);
      print("JSON parse edildi. Tip: ${rawData.runtimeType}");

      List<dynamic> data;
      if (rawData is Map<String, dynamic>) {
        // Eğer JSON bir obje ise, sureler bir array property'sinde olabilir
        if (rawData.containsKey('chapters')) {
          data = rawData['chapters'] as List<dynamic>;
        } else if (rawData.containsKey('surahs')) {
          data = rawData['surahs'] as List<dynamic>;
        } else if (rawData.containsKey('data')) {
          data = rawData['data'] as List<dynamic>;
        } else {
          // İlk key'i al
          final firstKey = rawData.keys.first;
          final firstValue = rawData[firstKey];
          if (firstValue is List) {
            data = firstValue;
          } else {
            throw Exception("JSON formatı beklenenden farklı");
          }
        }
      } else if (rawData is List<dynamic>) {
        data = rawData;
      } else {
        throw Exception("JSON formatı desteklenmiyor: ${rawData.runtimeType}");
      }

      print("Sure listesi bulundu. Sure sayısı: ${data.length}");

      if (data.isEmpty) {
        throw Exception("Sure listesi boş");
      }

      // İlk sure'yi kontrol et
      print("İlk sure verisi: ${data.first}");

      final sureListesi = data.map((sureJson) {
        try {
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

          print(
              "Dönüştürülmüş sure data: chapter=${sureData['chapter']}, name=${sureData['name']}");

          return Sure.fromJson(sureData);
        } catch (e) {
          print("Sure parse hatası: $e");
          print("Sorunlu veri: $sureJson");
          rethrow;
        }
      }).toList();

      print("Sureler başarıyla parse edildi. Toplam: ${sureListesi.length}");

      // İlk birkaç sure'nin chapter numaralarını kontrol et
      for (int i = 0; i < 5 && i < sureListesi.length; i++) {
        print(
            "Sure ${i + 1}: chapter=${sureListesi[i].chapter}, name=${sureListesi[i].name}");
      }

      final cuzListesi = _sureleriCuzlereGoreGrupla(sureListesi);
      print("Cüzler oluşturuldu. Toplam: ${cuzListesi.length}");

      if (mounted) {
        setState(() {
          tumSureler = sureListesi;
          gruplanmisCuzler = cuzListesi;
          _isLoading = false;
        });
        print("State güncellendi. Yükleme tamamlandı.");
      }
    } catch (e, stackTrace) {
      print("Veri yükleme hatası: $e");
      print("StackTrace: $stackTrace");

      if (mounted) {
        setState(() {
          _errorMessage =
              "Sureler yüklenirken bir sorun oluştu.\nHata: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  List<Cuz> _sureleriCuzlereGoreGrupla(List<Sure> sureler) {
    print("Cüz gruplama başlatıldı...");
    print("Toplam sure sayısı: ${sureler.length}");

    // Surelerin chapter numaralarını kontrol et
    sureler.forEach((sure) {
      print("Sure: ${sure.name} - Chapter: ${sure.chapter}");
    });

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

      print("${i + 1}. Cüz için aralık: $baslangicSureNo - $bitisSureNo");

      final cuzSureleri = sureler.where((s) {
        final dahil = s.chapter >= baslangicSureNo && s.chapter < bitisSureNo;
        if (dahil) {
          print("${s.name} (${s.chapter}) ${i + 1}. cüze dahil edildi");
        }
        return dahil;
      }).toList();

      cuzler.add(Cuz(cuzNumarasi: i + 1, sureler: cuzSureleri));
      print("${i + 1}. Cüz oluşturuldu. Sure sayısı: ${cuzSureleri.length}");
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
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF101439),
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              "Giriş Yapıldı: ${_user!.email ?? 'Google Kullanıcısı'}",
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    print(
        "_buildBody çağrıldı. _isLoading: $_isLoading, _errorMessage: $_errorMessage");
    print("tumSureler.length: ${tumSureler.length}");
    print("gruplanmisCuzler.length: ${gruplanmisCuzler.length}");

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Sureler yükleniyor...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade300, fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initialize();
                },
                child: Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    // Eğer buraya kadar geldiyse ama liste boşsa
    if (tumSureler.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Henüz sure yüklenmedi',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
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
          child:
              _aramaYapiliyor ? _buildAramaSonucListesi() : _buildCuzListesi(),
        ),
      ],
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
    print(
        "_buildCuzListesi çağrıldı. gruplanmisCuzler.length: ${gruplanmisCuzler.length}");

    if (gruplanmisCuzler.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cüzler yükleniyor...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: gruplanmisCuzler.length,
      itemBuilder: (context, index) {
        final cuz = gruplanmisCuzler[index];
        print("Cüz ${cuz.cuzNumarasi} - Sure sayısı: ${cuz.sureler.length}");

        if (cuz.sureler.isEmpty) return const SizedBox.shrink();

        return ExpansionTile(
          iconColor: Colors.white.withOpacity(0.7),
          collapsedIconColor: Colors.white.withOpacity(0.7),
          title: Text(
            "${cuz.cuzNumarasi}. Cüz",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade300,
              fontSize: 18,
            ),
          ),
          children: cuz.sureler.map((sure) => _buildSureKarti(sure)).toList(),
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
          subtitle: Text(
            '${sure.verses.length} ayet',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
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
