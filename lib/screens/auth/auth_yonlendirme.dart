// lib/screens/auth/auth_yonlendirme.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:huzur_app/screens/ana_menu_ekrani.dart';
import 'package:huzur_app/screens/auth/login_ekran.dart';

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
        // ✅ AnaMenuEkrani'na yönlendir - AnaSayfa değil
        _currentScreen = const AnaMenuEkrani();
      } else {
        _currentScreen = const LoginEkrani();
      }
      _isInitialized = true;
    });

    // Auth değişikliklerini dinle
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;

      print(
        'Auth state changed - User: ${user?.uid}, isAnonymous: ${user?.isAnonymous}',
      );

      // Sadece gerçek durum değişikliklerinde screen değiştir
      final shouldShowAnaMenu = user != null;
      final isCurrentlyShowingAnaMenu = _currentScreen is AnaMenuEkrani;

      if (shouldShowAnaMenu != isCurrentlyShowingAnaMenu) {
        setState(() {
          _currentScreen = shouldShowAnaMenu
              ? const AnaMenuEkrani()
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
