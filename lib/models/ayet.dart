// models/ayet.dart
class Ayet {
  final int id;
  final int verse; // Ayet numarası için eklendi
  final String text;
  final String translation;

  Ayet({
    required this.id,
    required this.verse,
    required this.text,
    required this.translation,
  });

  factory Ayet.fromJson(Map<String, dynamic> json) {
    return Ayet(
      id: json['id'] ?? 0,
      verse: json['verse'] ?? json['id'] ?? 0, // verse yoksa id'yi kullan
      text: json['text'] ?? '',
      translation: json['translation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'verse': verse,
      'text': text,
      'translation': translation,
    };
  }
}
