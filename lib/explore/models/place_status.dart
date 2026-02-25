enum ExploreStatus { wish, visited, favorite }

extension ExploreStatusExt on ExploreStatus {
  String get key => name;

  static ExploreStatus fromKey(String key) {
    return ExploreStatus.values.firstWhere(
      (e) => e.name == key,
      orElse: () => ExploreStatus.wish,
    );
  }
}
