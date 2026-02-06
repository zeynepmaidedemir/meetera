import 'models/map_place.dart'; // 🔥 BUNU EKLEMEZSEK PATLAR

class AiMessage {
  final String text;
  final bool isUser;
  final List<MapPlace>? places;

  AiMessage({required this.text, required this.isUser, this.places});
}
