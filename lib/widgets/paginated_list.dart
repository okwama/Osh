import 'package:flutter/material.dart';
import 'package:woosh/utils/pagination_utils.dart';

class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final VoidCallback onLoadMore;
  final ScrollController? scrollController;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.emptyWidget,
    this.errorWidget,
    this.loadingWidget,
    this.scrollController,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (PaginationHelper.shouldLoadMore(_scrollController) &&
        !widget.isLoading &&
        widget.hasMore) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return widget.errorWidget ??
          PaginationHelper.buildEmptyState(widget.error!);
    }

    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ??
          PaginationHelper.buildEmptyState('No items found');
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          return widget.loadingWidget ??
              PaginationHelper.buildLoadingIndicator();
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }
}
