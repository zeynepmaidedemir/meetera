import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/marketplace_state.dart';
import '../state/app_state.dart';

import 'marketplace_add_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String? _currentCityId;

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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MarketplaceState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('2nd Hand Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceAddScreen()),
              );
            },
          )
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? const Center(child: Text("No items available in your city yet."))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: item.imageUrls.isNotEmpty
                                  ? Image.network(item.imageUrls.first, fit: BoxFit.cover)
                                  : Container(color: Colors.grey.shade300, child: const Icon(Icons.image, size: 50, color: Colors.grey)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.price == 0 ? "Free" : "\$${item.price}",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
