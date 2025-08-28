// lib/screens/profil_ekrani.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:huzur_app/services/auth_service.dart';
import 'package:huzur_app/services/login_ekran.dart';
import 'package:huzur_app/screens/favoriler_ekrani.dart';

class ProfilEkrani extends StatefulWidget {
  const ProfilEkrani({super.key});

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  final AuthService _authService = AuthService();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Profilim', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildProfilKarti(),
            const SizedBox(height: 30),
            _buildMenuKarti(
              ikon: Icons.favorite_border,
              isim: 'Favorilerim',
              aciklama: 'Beğendiğiniz ayet ve sözler',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavorilerEkrani()),
                );
              },
            ),
            _buildMenuKarti(
              ikon: Icons.settings_outlined,
              isim: 'Ayarlar',
              aciklama: 'Uygulama temasını ve diğer ayarları değiştirin',
              onTap: () {
                // TODO: Ayarlar ekranına yönlendirme eklenecek
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              onPressed: () async {
                await _authService.signOut();
                // AuthYonlendirme zaten yönlendirmeyi yapacak
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginEkrani()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilKarti() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withOpacity(0.1),
            // Google'dan gelen profil resmini göster, yoksa standart ikon göster
            backgroundImage:
                _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
            child: _user?.photoURL == null
                ? Icon(Icons.person, size: 40, color: Colors.blue.shade300)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.displayName ?? 'Kullanıcı Adı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _user?.email ?? 'E-posta adresi bilgisi yok',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuKarti({
    required IconData ikon,
    required String isim,
    required String aciklama,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(ikon, color: Colors.blue.shade300),
        title: Text(isim,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(aciklama,
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white24, size: 16),
        onTap: onTap,
      ),
    );
  }
}
