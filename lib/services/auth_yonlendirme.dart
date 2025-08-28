// lib/screens/auth/auth_yonlendirme.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:huzur_app/screens/ana_menu_ekrani.dart';
import 'package:huzur_app/services/login_ekran.dart';

class AuthYonlendirme extends StatefulWidget {
  const AuthYonlendirme({super.key});

  @override
  State<AuthYonlendirme> createState() => _AuthYonlendirmeState();
}

class _AuthYonlendirmeState extends State<AuthYonlendirme> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Bağlantı bekleniyor...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        // Kullanıcı giriş yapmış mı?
        if (snapshot.hasData) {
          return const AnaMenuEkrani(); // Giriş yapmışsa ana menüye git
        }
        // Kullanıcı giriş yapmamış
        return const LoginEkrani(); // Giriş yapmamışsa login ekranına git
      },
    );
  }
}
