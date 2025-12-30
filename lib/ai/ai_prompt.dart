class AiPromptBuilder {
  static String build({
    required String userMessage,
    required String city,
    required int eventCount,
  }) {
    return '''
Kullanıcının bulunduğu şehir: $city
Bu şehirdeki etkinlik sayısı: $eventCount

Kullanıcının mesajı:
"$userMessage"

Yukarıdaki bilgilere göre kullanıcıya samimi, yardımcı ve kısa bir cevap ver.
''';
  }
}
