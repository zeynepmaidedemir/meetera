import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ErasmusChecklistCard extends StatefulWidget {
  final String text;

  const ErasmusChecklistCard({super.key, required this.text});

  @override
  State<ErasmusChecklistCard> createState() => _ErasmusChecklistCardState();
}

class _ErasmusChecklistCardState extends State<ErasmusChecklistCard> {
  final List<ChecklistItem> _items = [];
  bool _isLoading = true;
  String _title = "";
  String _description = "";

  @override
  void initState() {
    super.initState();
    _parseAndLoad();
  }

  @override
  void didUpdateWidget(covariant ErasmusChecklistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _parseAndLoad();
    }
  }

  Future<void> _parseAndLoad() async {
    setState(() => _isLoading = true);

    _items.clear();
    final lines = widget.text.split('\n');
    final prefs = await SharedPreferences.getInstance();

    final itemRegex = RegExp(r'^(\s*[-*•]\s+|\s*\d+\.\s+)(.*)$');

    List<String> headerLines = [];
    List<String> descLines = [];
    bool foundFirstItem = false;

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = itemRegex.firstMatch(line);
      if (match != null) {
        foundFirstItem = true;
        final itemText = match.group(2) ?? '';
        // Generate a unique persistence key based on the content hash to avoid conflicts
        final key = 'chk_${widget.text.hashCode}_${itemText.hashCode}';
        final isCompleted = prefs.getBool(key) ?? false;
        
        _items.add(ChecklistItem(
          text: itemText,
          key: key,
          isCompleted: isCompleted,
        ));
      } else {
        if (!foundFirstItem) {
          headerLines.add(trimmed);
        } else {
          descLines.add(trimmed);
        }
      }
    }

    if (headerLines.isNotEmpty) {
      _title = headerLines.first;
      if (headerLines.length > 1) {
        _description = headerLines.sublist(1).join('\n');
      }
    } else {
      _title = "Erasmus Checklist";
    }
    
    if (descLines.isNotEmpty) {
      if (_description.isEmpty) {
        _description = descLines.join('\n');
      } else {
        _description += '\n' + descLines.join('\n');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleItem(int index) async {
    final item = _items[index];
    final newValue = !item.isCompleted;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(item.key, newValue);

    if (mounted) {
      setState(() {
        _items[index] = item.copyWith(isCompleted: newValue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final hasDescription = _description.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.12), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6366F1).withOpacity(0.03),
              const Color(0xFF8B5CF6).withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fact_check_rounded,
                      color: Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _title.replaceAll('#', '').trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasDescription) ...[
                const SizedBox(height: 10),
                Text(
                  _description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Checklist Items
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () => _toggleItem(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: item.isCompleted
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: item.isCompleted
                                      ? const Color(0xFF10B981)
                                      : Colors.grey.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: item.isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: item.isCompleted ? FontWeight.w500 : FontWeight.w600,
                                  color: item.isCompleted
                                      ? Colors.grey
                                      : Theme.of(context).textTheme.bodyLarge?.color,
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  height: 1.35,
                                ),
                                child: Text(item.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              
              // Progress Bar
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _items.where((i) => i.isCompleted).length / _items.length,
                    minHeight: 6,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_items.where((i) => i.isCompleted).length} of ${_items.length} completed",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      "${((_items.where((i) => i.isCompleted).length / _items.length) * 100).round()}% Done",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class ChecklistItem {
  final String text;
  final String key;
  final bool isCompleted;

  ChecklistItem({
    required this.text,
    required this.key,
    required this.isCompleted,
  });

  ChecklistItem copyWith({bool? isCompleted}) {
    return ChecklistItem(
      text: text,
      key: key,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
