// lib/screens/ana_menu_ekrani.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:huzur_app/providers/theme_provider.dart';
import 'package:huzur_app/screens/sureler_ekrani.dart';
import 'package:provider/provider.dart';

class AnaMenuEkrani extends StatelessWidget {
  const AnaMenuEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Huzur Uygulaması'),
        actions: [
          // Theme toggle butonu
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
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
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: <Widget>[
          _buildMenuKarti(
            context,
            ikon: Icons.book_outlined,
            isim: 'Sureler',
            sayfa: const AnaSayfa(),
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.format_quote_outlined,
            isim: 'Ayetler',
            sayfa: const Scaffold(
              body: Center(child: Text("Ayetler (Yakında)")),
            ),
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.article_outlined,
            isim: 'Güzel Sözler',
            sayfa: const Scaffold(
              body: Center(child: Text("Güzel Sözler (Yakında)")),
            ),
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.explore_outlined,
            isim: 'Kıble Bul',
            sayfa: const Scaffold(
              body: Center(child: Text("Kıble Bul (Yakında)")),
            ),
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.schedule_outlined,
            isim: 'Namaz Vakitleri',
            sayfa: const Scaffold(
              body: Center(child: Text("Namaz Vakitleri (Yakında)")),
            ),
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.settings_outlined,
            isim: 'Ayarlar',
            sayfa: const SettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuKarti(
    BuildContext context, {
    required IconData ikon,
    required String isim,
    required Widget sayfa,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => sayfa));
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              ikon,
              size: 50.0,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10.0),
            Text(isim, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

// Basit ayarlar ekranı
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: const Text('Koyu Tema'),
                  subtitle: const Text('Gözlerinizi yormaması için'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              title: Text('Font Boyutu'),
              subtitle: Text('Yakında eklenecek'),
              leading: Icon(Icons.text_fields),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              title: Text('Bildirimler'),
              subtitle: Text('Yakında eklenecek'),
              leading: Icon(Icons.notifications),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          ),
        ],
      ),
    );
  }
}
