import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/Products_Inventory/store_model.dart';
import 'package:woosh/controllers/cartcontroller/cart_controller.dart';
import 'package:woosh/models/client/client_model.dart';

/// Widget for selecting a store for order placement
class StoreSelectorWidget extends StatefulWidget {
  final Client outlet;
  final Function(Store) onStoreSelected;
  final Store? initialStore;

  const StoreSelectorWidget({
    super.key,
    required this.outlet,
    required this.onStoreSelected,
    this.initialStore,
  });

  @override
  State<StoreSelectorWidget> createState() => _StoreSelectorWidgetState();
}

class _StoreSelectorWidgetState extends State<StoreSelectorWidget> {
  final RxBool isLoading = false.obs;
  final RxList<Store> availableStores = <Store>[].obs;
  final Rx<Store?> selectedStore = Rx<Store?>(null);

  @override
  void initState() {
    super.initState();
    selectedStore.value = widget.initialStore;
    _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      isLoading.value = true;
      final stores = await Get.find<CartController>().loadStores(widget.outlet);
      availableStores.value = stores;

      if (stores.isNotEmpty) {
        selectedStore.value = widget.initialStore ?? stores.first;
        if (selectedStore.value != null) {
          widget.onStoreSelected(selectedStore.value!);
        }
      }
    } catch (e) {
      print('❌ Error in StoreSelectorWidget [_loadStores]: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Select Store',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (isLoading.value) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Loading stores...'),
                  ],
                ),
              );
            }

            return DropdownButtonFormField<Store>(
              value: selectedStore.value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: 'Select a store',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              icon: const Icon(Icons.store, color: Colors.grey),
              dropdownColor: Colors.white,
              elevation: 3,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              items: availableStores.map((store) {
                return DropdownMenuItem(
                  value: store,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          store.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (store.region != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${store.region!.name}${store.region!.country != null ? ', ${store.region!.country!.name}' : ''}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ] else ...[
                          const SizedBox(height: 2),
                          Text(
                            'No region Assigned',
                            style: TextStyle(
                              fontSize: 6,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (Store? newValue) {
                if (newValue != null) {
                  selectedStore.value = newValue;
                  widget.onStoreSelected(newValue);
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a store';
                }
                return null;
              },
            );
          }),

          // Selected store info
          Obx(() {
            if (selectedStore.value != null) {
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: ${selectedStore.value!.name}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                              fontSize: 14,
                            ),
                          ),
                          if (selectedStore.value!.region != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${selectedStore.value!.region!.name}${selectedStore.value!.region!.country != null ? ', ${selectedStore.value!.region!.country!.name}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
