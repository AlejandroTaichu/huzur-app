// lib/main.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huzur_app/models/sure.dart';
import 'package:huzur_app/screens/auth/login_ekran.dart';
import 'package:huzur_app/screens/splash_ekrani.dart';
import 'package:huzur_app/screens/sure_detay_ekrani.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HuzurApp());
}

class HuzurApp extends StatelessWidget {
  const HuzurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Huzur Uygulaması',
      home: const SplashEkrani(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<Sure> tumSureler = [];
  List<Sure> goruntulenenSureler = [];
  final TextEditingController _aramaController = TextEditingController();
  Sure? sonOkunanSure;
  User? _user;

  @override
  void initState() {
    super.initState();
    // Kullanıcı durumundaki anlık değişiklikleri dinle
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
    // Veri yükleme ve diğer başlangıç işlemleri
    _initialize();
  }

  Future<void> _initialize() async {
    await veriYukle();
    await _sonOkunaniYukle();
  }

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

  Future<void> veriYukle() async {
    final cevap = await rootBundle.loadString('assets/kuran_tr.json');
    final List<dynamic> data = json.decode(cevap);
    if (mounted) {
      setState(() {
        tumSureler = data.map((sureJson) => Sure.fromJson(sureJson)).toList();
        goruntulenenSureler = tumSureler;
      });
    }
  }

  void _filtrele(String aramaMetni) {
    final String sorgu = aramaMetni.toLowerCase();
    setState(() {
      goruntulenenSureler = tumSureler.where((sure) {
        final sureAdiKucukHarf = sure.name.toLowerCase();
        return sureAdiKucukHarf.contains(sorgu);
      }).toList();
    });
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
    // Splash ekranı artık başlangıçta anonim giriş yaptırdığı için,
    // çıkış yaptıktan sonra login ekranına değil, uygulamayı yeniden başlatarak
    // yeni bir anonim kullanıcı oluşturmasını sağlayabiliriz.
    // VEYA direkt login ekranına atabiliriz. Şimdilik bu daha basit.
    // Çıkış yapınca AuthYonlendirme bizi Login'e atıyordu, o yapı kalktı.
    // Yeni yapıda çıkış yapınca tekrar anonim olarak devam eder.
    // Gerçek bir hesaba geçmek için profil ikonuna basması gerekir.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Huzur Uygulaması - Sureler'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _user != null && _user!.isAnonymous
                  ? Icons.login
                  : Icons.person_outline,
            ),
            tooltip: _user != null && _user!.isAnonymous
                ? 'Kayıt Ol / Giriş Yap'
                : 'Profilim',
            onPressed: () {
              if (_user != null && _user!.isAnonymous) {
                // Anonim kullanıcıyı Login ekranına GÖNDER ve GERİ DÖNEMEMESİNİ SAĞLA
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginEkrani()),
                );
              } else if (_user != null) {
                // Kayıtlı kullanıcı için çıkış yapma menüsünü göster
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Giriş yapıldı: ${_user!.email}'),
                    action: SnackBarAction(
                      label: 'ÇIKIŞ YAP',
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ),
                );
              }
            },
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
            child: goruntulenenSureler.isEmpty
                ? const Center(child: Text('Arama sonucu bulunamadı.'))
                : ListView.builder(
                    itemCount: goruntulenenSureler.length,
                    itemBuilder: (context, index) {
                      final sure = goruntulenenSureler[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                                builder: (context) =>
                                    SureDetay_Ekrani(sure: sure),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
