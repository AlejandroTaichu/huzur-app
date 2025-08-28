// lib/main.dart
import 'package:flutter/material.dart';
import 'package:huzur_app/providers/theme_provider.dart';
import 'package:huzur_app/screens/splash_ekrani.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  // Flutter'ın ve diğer servislerin düzgün çalışması için gerekli başlatmalar
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';

  runApp(const HuzurApp());
}

class HuzurApp extends StatelessWidget {
  const HuzurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Huzur Uygulaması',
            // AppTheme'in theme_provider.dart içinde tanımlandığını varsayıyorum
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashEkrani(),
          );
        },
      ),
    );
  }
}
