import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketplace_item_model.dart';
import '../services/auth_service.dart';

import 'dart:async';

class MarketplaceState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  List<MarketplaceItemModel> _items = [];
  bool _isLoading = false;
  StreamSubscription? _sub;

  List<MarketplaceItemModel> get items => _items;
  bool get isLoading => _isLoading;

  void fetchItems(String city) {
    _isLoading = true;
    notifyListeners();

    _sub?.cancel();

    _sub = _firestore
        .collection('marketplace_items')
        .where('city', isEqualTo: city)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      final unsortedItems = snapshot.docs
          .map((doc) => MarketplaceItemModel.fromFirestore(doc))
          .toList();
          
      // Sort in memory to avoid requiring a Firebase Composite Index
      unsortedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _items = unsortedItems;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error streaming marketplace items: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
