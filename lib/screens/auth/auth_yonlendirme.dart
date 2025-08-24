// lib/screens/auth/auth_yonlendirme.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:huzur_app/screens/ana_menu_ekrani.dart';
import 'package:huzur_app/screens/auth/login_ekran.dart';
import 'package:huzur_app/screens/sureler_ekrani.dart'; // Yeni import

class AuthYonlendirme extends StatefulWidget {
  const AuthYonlendirme({super.key});

  @override
  State<AuthYonlendirme> createState() => _AuthYonlendirmeState();
}

class _AuthYonlendirmeState extends State<AuthYonlendirme> {
  Widget? _currentScreen;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() {
    final user = FirebaseAuth.instance.currentUser;
    print(
      'Initial auth check - User: ${user?.uid}, isAnonymous: ${user?.isAnonymous}',
    );

    setState(() {
      if (user != null) {
        _currentScreen = const AnaMenuEkrani();
      } else {
        _currentScreen = const LoginEkrani();
      }
      _isInitialized = true;
    });

    // Auth değişikliklerini dinle ama sadece gerekli durumlarda screen değiştir
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;

      print(
        'Auth state changed - User: ${user?.uid}, isAnonymous: ${user?.isAnonymous}',
      );

      // Sadece gerçek durum değişikliklerinde screen değiştir
      final shouldShowAnaSayfa = user != null;
      final isCurrentlyShowingAnaSayfa = _currentScreen is AnaSayfa;

      if (shouldShowAnaSayfa != isCurrentlyShowingAnaSayfa) {
        setState(() {
          _currentScreen = shouldShowAnaSayfa
              ? const AnaSayfa()
              : const LoginEkrani();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _currentScreen ??
        const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
