// lib/widgets/search_filter_row.dart
import 'package:flutter/material.dart';

enum TimeRange { today, yesterday, lastWeek, lastMonth }

typedef TimeRangeChanged = void Function(TimeRange range);

class SearchFilterRow extends StatefulWidget {
  final TimeRange initial;
  final TimeRangeChanged? onChanged;

  const SearchFilterRow({
    super.key,
    this.initial = TimeRange.today,
    this.onChanged,
  });

  @override
  State<SearchFilterRow> createState() => _SearchFilterRowState();
}

class _SearchFilterRowState extends State<SearchFilterRow> {
  late TimeRange _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  void _select(TimeRange r) {
    if (_selected == r) return;
    setState(() => _selected = r);
    widget.onChanged?.call(r);
  }

  Widget _pill(String label, TimeRange r) {
    final isActive = _selected == r;
    return GestureDetector(
      onTap: () => _select(r),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEEEEE) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 900;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 0, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Products + pills (scrollable)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Products :',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _pill('Today', TimeRange.today),
                  _pill('Yesterday', TimeRange.yesterday),
                  _pill('Last week', TimeRange.lastWeek),
                  _pill('Last month', TimeRange.lastMonth),
                ],
              ),
            ),
          ),

          // Right: Search & Icons (hide on small screens)
          if (!isSmall) ...[
            const SizedBox(width: 24),
            Container(
              width: 260,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                "Search",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ),
            const SizedBox(width: 20),
            InkWell(
              onTap: () {},
              child: const Icon(Icons.grid_view_rounded, color: Colors.black87, size: 24),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () {},
              child: const Icon(Icons.view_agenda, color: Colors.black54, size: 24),
            ),
          ],
        ],
      ),
    );
  }
}
