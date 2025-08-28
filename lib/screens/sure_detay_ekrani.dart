// lib/screens/sure_detay_ekrani.dart
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
  }

  Future<void> _pozisyonKaydet() async {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final enUsttekiAyetIndex = positions
        .where((p) => p.itemLeadingEdge >= 0)
        .reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b)
        .index;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sonOkunanSureNo', widget.sure.chapter);
    await prefs.setInt('sonOkunanAyetIndex', enUsttekiAyetIndex);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_pozisyonKaydet);
    super.dispose();
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
                Text(
                  '${widget.sure.chapter}:${ayet.verse}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade300,
                  ),
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
