// lib/widgets/category_picker_producthunt.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:prodhunt/model/categories_data.dart';

typedef CategorySelectCallback = void Function(String category, String subCategory);

Future<void> showProductHuntCategoryPicker(
  BuildContext context, {
  required CategorySelectCallback onSelected,
  String? initialCategory,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: _ProductHuntCategoryPicker(
        initialCategory: initialCategory,
        onSelected: onSelected,
      ),
    ),
  );
}

class _ProductHuntCategoryPicker extends StatefulWidget {
  final CategorySelectCallback onSelected;
  final String? initialCategory;

  const _ProductHuntCategoryPicker({
    super.key,
    required this.onSelected,
    this.initialCategory,
  });

  @override
  State<_ProductHuntCategoryPicker> createState() => _ProductHuntCategoryPickerState();
}

class _ProductHuntCategoryPickerState extends State<_ProductHuntCategoryPicker> with SingleTickerProviderStateMixin {
  late final List<String> _categories;
  late int _selectedIndex;
  String _subSearch = '';
  late ScrollController _leftController;
  late ScrollController _rightController;
  final _subSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categories = kProductHuntCategories.keys.toList();
    _selectedIndex = 0;
    if (widget.initialCategory != null) {
      final idx = _categories.indexOf(widget.initialCategory!);
      if (idx >= 0) _selectedIndex = idx;
    }
    _leftController = ScrollController();
    _rightController = ScrollController();
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _subSearchController.dispose();
    super.dispose();
  }

  List<String> get _currentSubcategories {
    final list = kProductHuntCategories[_categories[_selectedIndex]] ?? [];
    if (_subSearch.trim().isEmpty) return list;
    final q = _subSearch.toLowerCase();
    return list.where((s) => s.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxWidth = mq.size.width * 0.9;
    final dialogWidth = maxWidth.clamp(720.0, 1200.0).toDouble();
    final dialogHeight = mq.size.height * 0.78;
    final leftWidth = dialogWidth * 0.24;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: dialogWidth,
      height: dialogHeight,
      child: Column(
        children: [
          // HEADER (icon + title + subtitle + close)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.emoji_events_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                     
                      Text('Awards powered by what reviewers actually say', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Row(
              children: [
                // LEFT: categories list with scrollbar
                Container(
                  width: leftWidth,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Scrollbar(
                    controller: _leftController,
                    thumbVisibility: true,
                    thickness: 10,
                    child: ListView.builder(
                      controller: _leftController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _categories.length,
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final isSelected = i == _selectedIndex;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedIndex = i;
                              _subSearch = '';
                              _subSearchController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            color: isSelected ? cs.primary.withOpacity(0.06) : Colors.transparent,
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? cs.primary : Colors.grey[800],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // center divider
                Container(width: 1, color: Colors.grey.shade100),

                // RIGHT: subcategories + search
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // title row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _categories[_selectedIndex],
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${(kProductHuntCategories[_categories[_selectedIndex]]?.length ?? 0)}',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // search
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _subSearchController,
                                  decoration: const InputDecoration.collapsed(hintText: 'Search subcategories'),
                                  onChanged: (v) => setState(() => _subSearch = v),
                                ),
                              ),
                              if (_subSearch.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _subSearch = '';
                                      _subSearchController.clear();
                                    });
                                  },
                                  child: Icon(Icons.close, color: Colors.grey.shade500, size: 18),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // animated grid of subcategories
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _SubcategoryGrid(
                              key: ValueKey('${_categories[_selectedIndex]}|$_subSearch'),
                              items: _currentSubcategories,
                              onTap: (sub) {
                                widget.onSelected(_categories[_selectedIndex], sub);
                                Navigator.of(context).pop();
                              },
                              controller: _rightController,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// right side grid
class _SubcategoryGrid extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onTap;
  final ScrollController controller;

  const _SubcategoryGrid({
    super.key,
    required this.items,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text('No results', style: TextStyle(color: Colors.grey[600])));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      int columns = 3;
      if (width < 420) {
        columns = 1;
      } else if (width < 720) columns = 2;
      else if (width < 1000) columns = 3;
      else columns = 4;

      return Scrollbar(
        controller: controller,
        thumbVisibility: true,
        thickness: 10,
        radius: const Radius.circular(8),
        child: GridView.builder(
          controller: controller,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 6.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final label = items[idx];
            return _SubcategoryTile(
              label: label,
              onTap: () => onTap(label),
            );
          },
        ),
      );
    });
  }
}

class _SubcategoryTile extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SubcategoryTile({super.key, required this.label, required this.onTap});

  @override
  State<_SubcategoryTile> createState() => _SubcategoryTileState();
}

class _SubcategoryTileState extends State<_SubcategoryTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hover ? Colors.grey.shade50 : Colors.white;
    final border = _hover ? Colors.grey.shade300 : Colors.grey.shade100;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
            boxShadow: _hover ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)] : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
