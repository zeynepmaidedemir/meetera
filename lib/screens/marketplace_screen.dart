import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/marketplace_state.dart';
import '../state/app_state.dart';
import '../models/marketplace_item_model.dart';
import 'marketplace_add_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String? _currentCityId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortMode = 'newest'; // newest, price_low, price_high

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppState>();
    final cityId = appState.cityId;
    final cityLabel = appState.cityLabel;
    
    if (cityId != null && cityId.isNotEmpty && cityId != _currentCityId) {
      _currentCityId = cityId;
      context.read<MarketplaceState>().fetchItems(cityLabel);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sort Items",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Newest First"),
                trailing: _sortMode == 'newest' ? const Icon(Icons.check, color: Color(0xFF6366F1)) : null,
                onTap: () {
                  setState(() => _sortMode = 'newest');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text("Price: Low to High"),
                trailing: _sortMode == 'price_low' ? const Icon(Icons.check, color: Color(0xFF6366F1)) : null,
                onTap: () {
                  setState(() => _sortMode = 'price_low');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text("Price: High to Low"),
                trailing: _sortMode == 'price_high' ? const Icon(Icons.check, color: Color(0xFF6366F1)) : null,
                onTap: () {
                  setState(() => _sortMode = 'price_high');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MarketplaceState>();
    
    // Filtering
    List<MarketplaceItemModel> filteredItems = state.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.title.toLowerCase().contains(q) || item.description.toLowerCase().contains(q);
    }).toList();

    // Sorting
    filteredItems.sort((a, b) {
      if (_sortMode == 'price_low') return a.price.compareTo(b.price);
      if (_sortMode == 'price_high') return b.price.compareTo(a.price);
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '2nd Hand Market',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1), // Purple
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Sell Item", style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketplaceAddScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Search for items...",
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                        prefixIcon: Icon(Icons.search, color: Colors.black45),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: Colors.black54),
                        SizedBox(width: 6),
                        Text(
                          "Filter",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 8),

          // Grid View
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                    ? const Center(
                        child: Text(
                          "No items found.\nTry another search or be the first to sell!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _MarketItemCard(item: item);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _MarketItemCard extends StatefulWidget {
  final MarketplaceItemModel item;

  const _MarketItemCard({required this.item});

  @override
  State<_MarketItemCard> createState() => _MarketItemCardState();
}

class _MarketItemCardState extends State<_MarketItemCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isFavorite = prefs.getBool('fav_market_${widget.item.id}') ?? false;
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFavorite = !_isFavorite;
    });
    await prefs.setBool('fav_market_${widget.item.id}', _isFavorite);
  }

  // Extract condition from description logic
  String _getCondition(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('new') || lower.contains('yeni')) return 'Like New';
    if (lower.contains('good') || lower.contains('iyi')) return 'Good Condition';
    if (lower.contains('used') || lower.contains('kullan')) return 'Used';
    return 'Used - Good'; // default
  }

  @override
  Widget build(BuildContext context) {
    final condition = _getCondition(widget.item.description);
    final hasImage = widget.item.imageUrls.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: hasImage
                      ? Image.network(
                          widget.item.imageUrls.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        ),
                ),
                // Favorite Heart
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: _isFavorite ? Colors.redAccent : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Details Section
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        condition,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  
                  Text(
                    widget.item.price == 0 ? "Free" : "\$${widget.item.price.toStringAsFixed(1)}",
                    style: const TextStyle(
                      color: Color(0xFF6366F1), // Purple
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
