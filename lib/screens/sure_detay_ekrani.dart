// lib/screens/sure_detay_ekrani.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:huzur_app/models/sure.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SureDetay_Ekrani extends StatefulWidget {
  final Sure sure;
  final int? baslangicAyetIndex;

  const SureDetay_Ekrani({
    super.key,
    required this.sure,
    this.baslangicAyetIndex,
  });

  @override
  State<SureDetay_Ekrani> createState() => _SureDetay_EkraniState();
}

class _SureDetay_EkraniState extends State<SureDetay_Ekrani> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  // YENİ: Favori ayetlerin ID'lerini tutacak bir set
  final Set<int> _favoriAyetler = {};
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    if (widget.baslangicAyetIndex != null &&
        widget.baslangicAyetIndex! < widget.sure.verses.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(index: widget.baslangicAyetIndex!);
      });
    }

    _itemPositionsListener.itemPositions.addListener(_pozisyonKaydet);
    _favorileriYukle(); // Ekran açıldığında mevcut favorileri yükle
  }

  // YENİ: Firestore'dan mevcut favorileri çeken fonksiyon
  Future<void> _favorileriYukle() async {
    if (_user == null || _user!.isAnonymous) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('favori_ayetler')
        .doc(widget.sure.chapter.toString());

    final doc = await docRef.get();
    if (doc.exists && doc.data() != null) {
      final ayetListesi = List<int>.from(doc.data()!['ayetler'] ?? []);
      setState(() {
        _favoriAyetler.addAll(ayetListesi);
      });
    }
  }

  // YENİ: Bir ayeti favorilere ekleyen/kaldıran fonksiyon
  Future<void> _favoriToggle(int ayetNumarasi) async {
    if (_user == null || _user!.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Favorilere eklemek için lütfen giriş yapın.')),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('favori_ayetler')
        .doc(widget.sure.chapter.toString());

    if (_favoriAyetler.contains(ayetNumarasi)) {
      // Favorilerden kaldır
      setState(() {
        _favoriAyetler.remove(ayetNumarasi);
      });
      await docRef.update({
        'ayetler': FieldValue.arrayRemove([ayetNumarasi])
      });
    } else {
      // Favorilere ekle
      setState(() {
        _favoriAyetler.add(ayetNumarasi);
      });
      // SetOptions(merge: true) doküman yoksa oluşturur, varsa günceller
      await docRef.set({
        'sureAdi': widget.sure.name,
        'sureNo': widget.sure.chapter,
        'ayetler': FieldValue.arrayUnion([ayetNumarasi])
      }, SetOptions(merge: true));
    }
  }

  Future<void> _pozisyonKaydet() async {
    // ... Bu fonksiyon aynı kalıyor
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_pozisyonKaydet);
    super.dispose(); // <-- BU SATIRI EKLEYİN
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: Text("${widget.sure.name} Suresi",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ScrollablePositionedList.builder(
        itemCount: widget.sure.verses.length,
        itemScrollController: _scrollController,
        itemPositionsListener: _itemPositionsListener,
        itemBuilder: (context, index) {
          final ayet = widget.sure.verses[index];
          final isFavori = _favoriAyetler.contains(ayet.verse);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.1),
                  Colors.purple.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.sure.chapter}:${ayet.verse}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade300,
                      ),
                    ),
                    // YENİ: Favori butonu
                    IconButton(
                      icon: Icon(
                        isFavori ? Icons.favorite : Icons.favorite_border,
                        color: isFavori ? Colors.pink.shade300 : Colors.white54,
                      ),
                      onPressed: () => _favoriToggle(ayet.verse),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ayet.text,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 26, fontFamily: 'Amiri', color: Colors.white),
                ),
                const Divider(
                  height: 32,
                  thickness: 1,
                  color: Colors.white12,
                ),
                Text(
                  ayet.translation,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
