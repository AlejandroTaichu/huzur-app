// lib/screens/auth/auth_yonlendirme.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:huzur_app/main.dart';
import 'package:huzur_app/screens/auth/login_ekran.dart';

class AuthYonlendirme extends StatelessWidget {
  const AuthYonlendirme({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const AnaSayfa();
        }
        return const LoginEkrani();
      },
    );
  }
}
