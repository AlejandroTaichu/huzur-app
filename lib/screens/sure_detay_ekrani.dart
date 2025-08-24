// lib/screens/sure_detay_ekrani.dart
import 'package:flutter/material.dart';
import 'package:huzur_app/models/sure.dart'; // import yolunu kontrol et

class SureDetay_Ekrani extends StatelessWidget {
  final Sure sure;
  const SureDetay_Ekrani({super.key, required this.sure});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${sure.name} Suresi"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: sure.verses.length,
        itemBuilder: (context, index) {
          final ayet = sure.verses[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${sure.chapter}:${ayet.verse}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ayet.text,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 24, fontFamily: 'Amiri'),
                  ),
                  const Divider(
                    height: 32,
                    thickness: 1,
                    color: Colors.black12,
                  ),
                  Text(
                    ayet.translation,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
