// lib/models/sure.dart
import 'package:huzur_app/models/ayet.dart';

class Sure {
  final int chapter;
  final String name;
  final List<Ayet> verses;

  Sure({required this.chapter, required this.name, required this.verses});

  // Bu factory, bir JSON parçasını (Map) Sure nesnesine çevirir.
  factory Sure.fromJson(Map<String, dynamic> json) {
    var ayetlerListesi = json['verses'] as List;
    List<Ayet> ayetler = ayetlerListesi
        .map((ayetJson) => Ayet.fromJson(ayetJson))
        .toList();

    return Sure(
      chapter: json['id'], // 'chapter' yerine 'id' kullandık
      name: json['translation'], // 'name' yerine 'translation' kullandık
      verses: ayetler,
    );
  }
}
