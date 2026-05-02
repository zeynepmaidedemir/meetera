import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceItemModel {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price; // 0.0 means free/exchange
  final List<String> imageUrls;
  final String city;
  final String country;
  final DateTime createdAt;
  final String status; // 'active', 'sold'

  MarketplaceItemModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.city,
    required this.country,
    required this.createdAt,
    required this.status,
  });

  factory MarketplaceItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MarketplaceItemModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      city: data['city'] ?? '',
      country: data['country'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'city': city,
      'country': country,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}
