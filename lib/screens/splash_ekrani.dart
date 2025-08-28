// lib/screens/splash_ekrani.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:huzur_app/services/auth_service.dart';
import 'package:huzur_app/services/auth_yonlendirme.dart';
// <-- BU SATIRI EKLEYİN

class SplashEkrani extends StatefulWidget {
  const SplashEkrani({super.key});
  @override
  State<SplashEkrani> createState() => _SplashEkraniState();
}

class _SplashEkraniState extends State<SplashEkrani>
    with SingleTickerProviderStateMixin {
  // Animasyon için TickerProvider ekledik
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcüsünü ayarlıyoruz
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // Animasyon süresi
      vsync: this,
    );

    // Fade (belirme) ve Scale (büyüme) animasyonlarını tanımlıyoruz
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Animasyonu başlat
    _controller.forward();

    // Belirlenen süre sonunda ana ekrana geç
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthYonlendirme()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Controller'ı temizle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Yeni tasarım dilimizdeki renkler
    final Color backgroundColor = const Color(0xFF0A0E27);
    final Color primaryTextColor = Colors.white;
    final Color accentColor = Colors.blue.shade300;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mosque_outlined,
                  size: 80.0,
                  color: accentColor, // Vurgu rengini kullan
                ),
                const SizedBox(height: 20),
                Text(
                  'Huzur Uygulaması',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Kalbinize Huzur...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: primaryTextColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
