// lib/screens/favoriler_ekrani.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:huzur_app/models/sure.dart';
import 'package:huzur_app/screens/sure_detay_ekrani.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

// Firestore'dan gelen veriyi tutmak için basit bir model
class FavoriAyetGrubu {
  final String sureAdi;
  final int sureNo;
  final List<int> ayetler;

  FavoriAyetGrubu({
    required this.sureAdi,
    required this.sureNo,
    required this.ayetler,
  });
}

class FavorilerEkrani extends StatefulWidget {
  const FavorilerEkrani({super.key});

  @override
  State<FavorilerEkrani> createState() => _FavorilerEkraniState();
}

class _FavorilerEkraniState extends State<FavorilerEkrani> {
  final User? _user = FirebaseAuth.instance.currentUser;
  List<Sure> _tumSureler = [];

  @override
  void initState() {
    super.initState();
    _sureleriYukle();
  }

  // Sure detay ekranına atlamak için tüm sure verisine ihtiyacımız var.
  Future<void> _sureleriYukle() async {
    final cevap = await rootBundle.loadString('assets/kuran_tr.json');
    final List<dynamic> data = json.decode(cevap);
    if (mounted) {
      setState(() {
        _tumSureler = data.map((sureJson) => Sure.fromJson(sureJson)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Favorilerim', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Kullanıcının favori ayetler koleksiyonunu dinle
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('favori_ayetler')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Henüz favori ayetiniz bulunmuyor.',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            );
          }

          // Firestore'dan gelen dokümanları modelimize çevir
          final favoriGruplari = snapshot.data!.docs.map((doc) {
            return FavoriAyetGrubu(
              sureAdi: doc['sureAdi'],
              sureNo: doc['sureNo'],
              ayetler: List<int>.from(doc['ayetler']),
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: favoriGruplari.length,
            itemBuilder: (context, index) {
              final grup = favoriGruplari[index];
              return _buildSureGrubuKarti(grup);
            },
          );
        },
      ),
    );
  }

  Widget _buildSureGrubuKarti(FavoriAyetGrubu grup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${grup.sureAdi} Suresi",
            style: TextStyle(
              color: Colors.blue.shade300,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white12, height: 20),
          // Bu suredeki favori ayetleri listele
          ...grup.ayetler.map((ayetNo) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "$ayetNo. Ayet",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white24, size: 16),
              onTap: () {
                if (_tumSureler.isNotEmpty) {
                  try {
                    final ilgiliSure =
                        _tumSureler.firstWhere((s) => s.chapter == grup.sureNo);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SureDetay_Ekrani(
                          sure: ilgiliSure,
                          baslangicAyetIndex:
                              ayetNo - 1, // Ayet no 1'den, index 0'dan başlar
                        ),
                      ),
                    );
                  } catch (e) {
                    print("Sure bulunamadı: ${grup.sureNo}");
                  }
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
