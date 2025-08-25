// lib/screens/splash_ekrani.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:huzur_app/screens/auth/auth_yonlendirme.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SplashEkrani extends StatefulWidget {
  const SplashEkrani({super.key});
  @override
  State<SplashEkrani> createState() => _SplashEkraniState();
}

class _SplashEkraniState extends State<SplashEkrani> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthYonlendirme()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.green[800],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mosque_outlined, size: 80.0, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Huzur Uygulaması',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            // Geçici test butonu
            ElevatedButton(
              onPressed: () {
                themeProvider.toggleTheme();
              },
              child: const Text("Toggle Theme"),
            ),
          ],
        ),
      ),
    );
  }
}
