class Buddy {
  final String id;
  final String name;
  final String city;
  final String bio;
  final List<String> interests;

  const Buddy({
    required this.id,
    required this.name,
    required this.city,
    required this.bio,
    required this.interests,
  });
}

const mockBuddies = [
  Buddy(
    id: 'b1',
    name: 'Alex',
    city: 'Krakow',
    bio: 'Computer Science student',
    interests: ['Books', 'Coffee'],
  ),
  Buddy(
    id: 'b2',
    name: 'Maria',
    city: 'Lublin',
    bio: 'Erasmus lover 🌍',
    interests: ['Travel', 'Photography'],
  ),
  Buddy(
    id: 'b3',
    name: 'Luca',
    city: 'Lublin',
    bio: 'Startup & coffee ☕',
    interests: ['Travel', 'Coffee'],
  ),
];
