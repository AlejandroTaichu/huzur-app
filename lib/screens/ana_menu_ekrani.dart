// lib/screens/ana_menu_ekrani.dart
import 'package:flutter/material.dart';
import 'package:huzur_app/screens/sureler_ekrani.dart'; // Sureler ekranına gitmek için

class AnaMenuEkrani extends StatelessWidget {
  const AnaMenuEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Huzur Uygulaması'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        // Buraya daha sonra profil ikonu eklenebilir
      ),
      body: GridView.count(
        crossAxisCount: 2, // Her satırda 2 buton olsun
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: <Widget>[
          _buildMenuKarti(
            context,
            ikon: Icons.book_outlined,
            isim: 'Sureler',
            sayfa:
                const AnaSayfa(), // AnaSayfa'nın yeni adı SurelerEkrani olacak
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.format_quote_outlined,
            isim: 'Ayetler',
            sayfa: const Scaffold(
              body: Center(child: Text("Ayetler (Yakında)")),
            ), // Henüz hazır değil
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.article_outlined,
            isim: 'Güzel Sözler',
            sayfa: const Scaffold(
              body: Center(child: Text("Güzel Sözler (Yakında)")),
            ), // Henüz hazır değil
          ),
          _buildMenuKarti(
            context,
            ikon: Icons.explore_outlined,
            isim: 'Kıble Bul',
            sayfa: const Scaffold(
              body: Center(child: Text("Kıble Bul (Yakında)")),
            ), // Henüz hazır değil
          ),
        ],
      ),
    );
  }

  // Butonları tekrar tekrar yazmamak için bir yardımcı metot
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
            Icon(ikon, size: 50.0, color: Colors.green[700]),
            const SizedBox(height: 10.0),
            Text(isim, style: const TextStyle(fontSize: 18.0)),
          ],
        ),
      ),
    );
  }
}
