class BadgeEngine {
  static List<String> calculate({
    required int visited,
    required int favorites,
    required int wishes,
    required int streak,
    required List<String> current,
  }) {
    final set = {...current};

    if (visited >= 1) set.add("First Pin 📍");
    if (visited >= 3) set.add("3 Places Visited ✅");
    if (favorites >= 3) set.add("3 Favorites ❤️");
    if (wishes >= 5) set.add("Planner 🧭");
    if (streak >= 2) set.add("2 Day Streak 🔥");
    if (streak >= 5) set.add("5 Day Streak 🔥🔥");

    return set.toList();
  }
}
