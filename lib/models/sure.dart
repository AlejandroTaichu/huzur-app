// models/sure.dart
import 'package:huzur_app/models/ayet.dart';

class Sure {
  final int chapter;
  final String name;
  final String arabicName;
  final String transliteration;
  final String translation;
  final String revelation;
  final int totalVerses;
  final List<Ayet> verses;

  Sure({
    required this.chapter,
    required this.name,
    required this.arabicName,
    required this.transliteration,
    required this.translation,
    required this.revelation,
    required this.totalVerses,
    required this.verses,
  });

  factory Sure.fromJson(Map<String, dynamic> json) {
    var versesList = json['verses'] as List? ?? [];
    List<Ayet> verses = versesList.map((i) => Ayet.fromJson(i)).toList();

    return Sure(
      chapter: json['chapter'] ?? json['id'] ?? 0,
      name: json['name'] ?? json['translation'] ?? 'İsimsiz Sure',
      arabicName: json['arabicName'] ?? json['name'] ?? '',
      transliteration: json['transliteration'] ?? '',
      translation: json['translation'] ?? 'Çeviri Yok',
      revelation: json['revelation'] ?? json['type'] ?? 'Bilinmiyor',
      totalVerses: json['total_verses'] ?? json['totalVerses'] ?? verses.length,
      verses: verses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapter': chapter,
      'name': name,
      'arabicName': arabicName,
      'transliteration': transliteration,
      'translation': translation,
      'revelation': revelation,
      'total_verses': totalVerses,
      'verses': verses.map((v) => v.toJson()).toList(),
    };
  }
}
