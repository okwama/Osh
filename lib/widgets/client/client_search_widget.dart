import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientSearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final Function(String) onSearchChanged;
  final VoidCallback? onClear;

  const ClientSearchWidget({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onSearchChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search clients...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: isSearching
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : const Icon(Icons.search, size: 18),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        controller.clear();
                        onClear?.call();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }
}
