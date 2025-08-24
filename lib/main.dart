// lib/main.dart
import 'package:flutter/material.dart';
import 'package:huzur_app/screens/ana_menu_ekrani.dart';
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
      home: const AnaMenuEkrani(),
    );
  }
}
