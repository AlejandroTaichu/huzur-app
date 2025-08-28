// lib/screens/namaz_vakitleri_ekrani.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class NamazVakitleri {
  final String imsak;
  final String gunes;
  final String ogle;
  final String ikindi;
  final String aksam;
  final String yatsi;

  NamazVakitleri({
    required this.imsak,
    required this.gunes,
    required this.ogle,
    required this.ikindi,
    required this.aksam,
    required this.yatsi,
  });

  factory NamazVakitleri.fromJson(Map<String, dynamic> json) {
    return NamazVakitleri(
      imsak: json['fajr'],
      gunes: json['shurooq'],
      ogle: json['dhuhr'],
      ikindi: json['asr'],
      aksam: json['maghrib'],
      yatsi: json['isha'],
    );
  }
}

class NamazVakitleriEkrani extends StatefulWidget {
  const NamazVakitleriEkrani({super.key});

  @override
  State<NamazVakitleriEkrani> createState() => _NamazVakitleriEkraniState();
}

class _NamazVakitleriEkraniState extends State<NamazVakitleriEkrani> {
  String _durumMesaji = "Namaz vakitleri yükleniyor...";
  NamazVakitleri? _vakitler;
  String? _sehir;
  Timer? _timer;
  String? _sonrakiVakit;
  String? _kalanSure;

  @override
  void initState() {
    super.initState();
    _konumAlVeVeriCek();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _konumAlVeVeriCek() async {
    try {
      setState(() => _durumMesaji = "Konumunuz tespit ediliyor...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _durumMesaji = "Konum servisleri kapalı.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _durumMesaji = "Konum izni verilmedi.");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _durumMesaji = "Konum izni kalıcı olarak reddedildi.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      String sehirAdi =
          placemarks.first.administrativeArea ?? "Konum Bulunamadı";

      await _namazVakitleriniCek(sehirAdi);
    } catch (e) {
      setState(() => _durumMesaji = "Konum alınamadı: ${e.toString()}");
    }
  }

  Future<void> _namazVakitleriniCek(String sehir) async {
    try {
      setState(() => _durumMesaji = "$sehir için vakitler alınıyor...");

      final url = Uri.parse('https://muslimsalat.com/$sehir.json?key=_');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status_code'] == 1) {
          setState(() {
            _vakitler = NamazVakitleri.fromJson(data['items'][0]);
            _sehir = data['city'];
            _kalanSureyiHesapla();
            _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (mounted) {
                _kalanSureyiHesapla();
              } else {
                timer.cancel();
              }
            });
          });
        } else {
          setState(() => _durumMesaji =
              "Vakitler alınamadı: ${data['status_description']}");
        }
      } else {
        setState(() =>
            _durumMesaji = "Veri çekilemedi. Hata: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _durumMesaji = "İnternet bağlantınızı kontrol edin.");
    }
  }

  // --- BU FONKSİYON GÜNCELLENDİ (SAĞLAMLAŞTIRILDI) ---
  DateTime _saatiDonustur(String saatStr) {
    final now = DateTime.now();
    final parts = saatStr.split(' ');
    final timeParts = parts[0].split(':');

    int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);
    final String ampm = parts[1].toLowerCase();

    if (ampm == 'pm' && hour != 12) {
      hour += 12;
    }
    if (ampm == 'am' && hour == 12) {
      // Gece 12 durumu
      hour = 0;
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  void _kalanSureyiHesapla() {
    if (_vakitler == null) return;

    final now = DateTime.now();
    final vakitListesi = {
      'İmsak': _vakitler!.imsak,
      'Güneş': _vakitler!.gunes,
      'Öğle': _vakitler!.ogle,
      'İkindi': _vakitler!.ikindi,
      'Akşam': _vakitler!.aksam,
      'Yatsı': _vakitler!.yatsi,
    };

    DateTime? sonrakiVakitZamani;
    String? sonrakiVakitAdi;

    for (var vakit in vakitListesi.entries) {
      final bugunkuVakit = _saatiDonustur(vakit.value);

      if (bugunkuVakit.isAfter(now)) {
        sonrakiVakitZamani = bugunkuVakit;
        sonrakiVakitAdi = vakit.key;
        break;
      }
    }

    if (sonrakiVakitZamani == null) {
      final yarin = now.add(const Duration(days: 1));
      final imsakZamani = _saatiDonustur(_vakitler!.imsak);
      sonrakiVakitZamani = DateTime(yarin.year, yarin.month, yarin.day,
          imsakZamani.hour, imsakZamani.minute);
      sonrakiVakitAdi = 'İmsak';
    }

    final kalan = sonrakiVakitZamani.difference(now);
    final saat = kalan.inHours.toString().padLeft(2, '0');
    final dakika = (kalan.inMinutes % 60).toString().padLeft(2, '0');
    final saniye = (kalan.inSeconds % 60).toString().padLeft(2, '0');

    if (mounted) {
      setState(() {
        _sonrakiVakit = sonrakiVakitAdi;
        _kalanSure = '$saat:$dakika:$saniye';
      });
    }
  }

  // --- build METODU VE DİĞER WIDGET'LAR AYNI KALIYOR ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Namaz Vakitleri',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _vakitler == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_durumMesaji,
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : _buildVakitlerListesi(),
    );
  }

  Widget _buildVakitlerListesi() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildAnaBilgiKarti(),
        const SizedBox(height: 20),
        _buildVakitKarti('İmsak', _vakitler!.imsak, Icons.brightness_4_outlined,
            _sonrakiVakit == 'İmsak'),
        _buildVakitKarti('Güneş', _vakitler!.gunes, Icons.wb_sunny_outlined,
            _sonrakiVakit == 'Güneş'),
        _buildVakitKarti(
            'Öğle', _vakitler!.ogle, Icons.wb_sunny, _sonrakiVakit == 'Öğle'),
        _buildVakitKarti('İkindi', _vakitler!.ikindi,
            Icons.brightness_6_outlined, _sonrakiVakit == 'İkindi'),
        _buildVakitKarti('Akşam', _vakitler!.aksam, Icons.brightness_5_outlined,
            _sonrakiVakit == 'Akşam'),
        _buildVakitKarti('Yatsı', _vakitler!.yatsi, Icons.nights_stay_outlined,
            _sonrakiVakit == 'Yatsı'),
      ],
    );
  }

  Widget _buildAnaBilgiKarti() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withOpacity(0.5),
            Colors.purple.shade900.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('dd MMMM yyyy, EEEE').format(DateTime.now()),
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            _sehir ?? "Konum alınıyor...",
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
          ),
          const Divider(color: Colors.white24, height: 30),
          Text(
            _sonrakiVakit != null
                ? '$_sonrakiVakit Vaktine Kalan Süre'
                : 'Vakitler Hesaplanıyor...',
            style: TextStyle(
                color: Colors.blue.shade300,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _kalanSure ?? '--:--:--',
            style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildVakitKarti(
      String isim, String saat, IconData ikon, bool sonrakiMi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: sonrakiMi
            ? Colors.blue.withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: sonrakiMi
            ? Border.all(color: Colors.blue.shade300, width: 2)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(ikon,
                  color: sonrakiMi
                      ? Colors.blue.shade300
                      : Colors.white.withOpacity(0.7),
                  size: 28),
              const SizedBox(width: 16),
              Text(
                isim,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            saat,
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
