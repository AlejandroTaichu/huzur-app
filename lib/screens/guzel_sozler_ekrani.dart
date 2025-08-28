// lib/screens/guzel_sozler_ekrani.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Sözleri modellemek için basit bir sınıf
class GuzelSoz {
  final String soz;
  final String sahip;

  GuzelSoz({required this.soz, required this.sahip});

  factory GuzelSoz.fromJson(Map<String, dynamic> json) {
    return GuzelSoz(
      soz: json['soz'],
      sahip: json['sahip'],
    );
  }
}

class GuzelSozlerEkrani extends StatefulWidget {
  const GuzelSozlerEkrani({super.key});

  @override
  State<GuzelSozlerEkrani> createState() => _GuzelSozlerEkraniState();
}

class _GuzelSozlerEkraniState extends State<GuzelSozlerEkrani> {
  List<GuzelSoz> _guzelSozler = [];

  @override
  void initState() {
    super.initState();
    _veriYukle();
  }

  Future<void> _veriYukle() async {
    final cevap = await rootBundle.loadString('assets/guzel_sozler.json');
    final List<dynamic> data = json.decode(cevap);
    _guzelSozler = data.map((sozJson) => GuzelSoz.fromJson(sozJson)).toList();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title:
            const Text('Güzel Sözler', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _guzelSozler.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _guzelSozler.length,
              itemBuilder: (context, index) {
                final guzelSoz = _guzelSozler[index];
                return _buildGuzelSozKarti(guzelSoz);
              },
            ),
    );
  }

  Widget _buildGuzelSozKarti(GuzelSoz guzelSoz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${guzelSoz.soz}"',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "- ${guzelSoz.sahip}",
              style: TextStyle(
                fontSize: 15,
                color: Colors.blue.shade300,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
