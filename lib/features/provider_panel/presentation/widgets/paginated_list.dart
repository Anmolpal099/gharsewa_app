import 'package:flutter/material.dart';

/// Paginates in-memory lists beyond [pageSize] (plan 28.3).
class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int pageSize;
  final EdgeInsetsGeometry? padding;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.pageSize = 20,
    this.padding,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  int _page = 0;

  int get _totalPages =>
      widget.items.isEmpty ? 1 : (widget.items.length / widget.pageSize).ceil();

  List<T> get _visibleItems {
    final start = _page * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, widget.items.length);
    if (start >= widget.items.length) return [];
    return widget.items.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._visibleItems.map(
          (item) => widget.itemBuilder(context, item),
        ),
        if (widget.items.length > widget.pageSize) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _page > 0
                    ? () => setState(() => _page--)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
              ),
              Text('Page ${_page + 1} of $_totalPages'),
              IconButton(
                onPressed: _page < _totalPages - 1
                    ? () => setState(() => _page++)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ],
    );
  }
}
