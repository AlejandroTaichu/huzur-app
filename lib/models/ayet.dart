// lib/models/ayet.dart
class Ayet {
  final int verse;
  final String text;
  final String translation;

  Ayet({required this.verse, required this.text, required this.translation});

  // Bu factory, bir JSON parçasını (Map) Ayet nesnesine çevirir.
  factory Ayet.fromJson(Map<String, dynamic> json) {
    return Ayet(
      verse: json['id'], // 'verse' yerine 'id' kullandık
      text: json['text'],
      translation: json['translation'],
    );
  }
}
