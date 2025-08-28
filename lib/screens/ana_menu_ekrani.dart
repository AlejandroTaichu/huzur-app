// lib/screens/ana_menu_ekrani.dart
import 'package:flutter/material.dart';
import 'package:huzur_app/screens/guzel_sozler_ekrani.dart';
import 'package:provider/provider.dart';
import 'package:huzur_app/providers/theme_provider.dart';
import 'package:huzur_app/screens/sureler_ekrani.dart';
import 'package:huzur_app/screens/kible_bul_ekran.dart';
import 'package:huzur_app/screens/ayetler_ekrani.dart';
import 'package:huzur_app/screens/namaz_vakitleri_ekrani.dart';

class AnaMenuEkrani extends StatelessWidget {
  const AnaMenuEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    // Yeni tema renklerimizi burada tanımlıyoruz
    final Color backgroundColor = const Color(0xFF0A0E27);
    final Color primaryTextColor = Colors.white;
    final Color secondaryTextColor = Colors.white.withOpacity(0.7);
    final Color accentColor = Colors.blue.shade300;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Huzur Uygulaması',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent, // Arka planı şeffaf yapıyoruz
        elevation: 0, // Gölgeleri kaldırıyoruz
        actions: [
          // Theme toggle butonu
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: primaryTextColor,
                ),
                tooltip: themeProvider.isDarkMode ? 'Açık tema' : 'Koyu tema',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20.0),
        crossAxisSpacing: 20.0,
        mainAxisSpacing: 20.0,
        children: <Widget>[
          _buildMenuKarti(
            context,
            ikon: Icons.book_outlined,
            isim: 'Sureler',
            sayfa: const AnaSayfa(),
            accentColor: accentColor,
            textColor: primaryTextColor,
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.format_quote_outlined,
            isim: 'Ayetler',
            sayfa: const AyetlerEkrani(),
            accentColor: accentColor,
            textColor: primaryTextColor,
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.article_outlined,
            isim: 'Güzel Sözler',
            sayfa: const GuzelSozlerEkrani(),
            accentColor: accentColor,
            textColor: primaryTextColor,
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.explore_outlined,
            isim: 'Kıble Bul',
            sayfa: const KibleBulEkrani(),
            accentColor: accentColor,
            textColor: primaryTextColor,
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.schedule_outlined,
            isim: 'Namaz Vakitleri',
            sayfa: const NamazVakitleriEkrani(),
            accentColor: accentColor,
            textColor: primaryTextColor,
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.settings_outlined,
            isim: 'Ayarlar',
            sayfa: const SettingsScreen(),
            accentColor: accentColor,
            textColor: primaryTextColor,
          ),
        ],
      ),
    );
  }

  // YENİ TASARIMA UYGUN KART WIDGET'I
  Widget _buildMenuKarti(
    BuildContext context, {
    required IconData ikon,
    required String isim,
    required Widget sayfa,
    required Color accentColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => sayfa));
      },
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.purple.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              ikon,
              size: 50.0,
              color: accentColor,
            ),
            const SizedBox(height: 12.0),
            Text(
              isim,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ayarlar Ekranı (Temayı yeni arka plana uyumlu hale getirmek için küçük bir güncelleme)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: const Text('Koyu Tema',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('Gözlerinizi yormaması için',
                      style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: Colors.blue.shade300,
                  ),
                );
              },
            ),
          ),
          // Diğer ayar kartları da benzer şekilde tasarlanabilir...
        ],
      ),
    );
  }
}
