// import 'package:flutter/material.dart';
// import 'package:woosh/models/client_stock_model.dart';
// import 'package:woosh/models/Products_Inventory/product_model.dart';
// import 'package:woosh/services/client_stock_service.dart';
// import 'package:woosh/services/api_service.dart';
// import 'package:woosh/utils/app_theme.dart';
// import 'package:woosh/widgets/gradient_app_bar.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class ClientStockPage extends StatefulWidget {
//   final int clientId;
//   final String clientName;

//   const ClientStockPage({
//     super.key,
//     required this.clientId,
//     required this.clientName,
//   });

//   @override
//   State<ClientStockPage> createState() => _ClientStockPageState();
// }

// class _ClientStockPageState extends State<ClientStockPage> {
//   List<ClientStock> _clientStocks = [];
//   List<ProductModel> _products = [];
//   final Map<int, TextEditingController> _controllers = {};
//   bool _loading = true;
//   bool _loadingProducts = false;
//   bool _updatingStock = false;
//   String? _errorMessage;
//   String _searchQuery = '';
//   String _selectedCategory = 'ALL';
//   bool _editMode = false;
//   final List<int> _changedProducts = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   @override
//   void dispose() {
//     for (var controller in _controllers.values) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   Future<void> _loadData() async {
//     setState(() {
//       _loading = true;
//       _errorMessage = null;
//     });

//     try {
//       await Future.wait([
//         _fetchClientStock(),
//         _fetchProducts(),
//       ]);
//       _initializeControllers();
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Failed to load data. Please try again.';
//       });
//     } finally {
//       setState(() {
//         _loading = false;
//       });
//     }
//   }

//   void _initializeControllers() {
//     _controllers.clear();
//     for (var product in _products) {
//       final stock = _clientStocks.firstWhere(
//         (stock) => stock.productId == product.id,
//         orElse: () => ClientStock(
//           id: 0,
//           quantity: 0,
//           clientId: widget.clientId,
//           productId: product.id,
//         ),
//       );
//       _controllers[product.id] = TextEditingController(
//         text: stock.quantity.toString(),
//       );
//     }
//   }

//   Future<void> _fetchClientStock() async {
//     try {
//       final stocks = await ClientStockService.getClientStock(widget.clientId);
//       setState(() {
//         _clientStocks = stocks;
//       });
//     } catch (e) {
//       print('Error fetching client stock: $e');
//     }
//   }

//   Future<void> _fetchProducts() async {
//     setState(() {
//       _loadingProducts = true;
//     });

//     try {
//       final products = await ApiService.getProducts(
//         limit: 1000,
//         clientId: widget.clientId,
//       );
//       setState(() {
//         _products = products;
//       });
//     } catch (e) {
//       print('Error fetching products: $e');
//       setState(() {
//         _products = [];
//       });
//     } finally {
//       setState(() {
//         _loadingProducts = false;
//       });
//     }
//   }

//   List<ProductModel> get _filteredProducts {
//     return _products.where((product) {
//       final matchesSearch =
//           product?.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//               (product?.description
//                       ?.toLowerCase()
//                       .contains(_searchQuery.toLowerCase()) ??
//                   false);
//       final matchesCategory =
//           _selectedCategory == 'ALL' || product?.category == _selectedCategory;
//       return matchesSearch && matchesCategory;
//     }).toList();
//   }

//   List<String> get _categories {
//     final categories = _products.map((p) => p?.category).toSet().toList();
//     categories.sort();
//     return ['ALL', ...categories];
//   }

//   void _onQuantityChanged(int productId) {
//     if (!_changedProducts.contains(productId)) {
//       setState(() {
//         _changedProducts.add(productId);
//       });
//     }
//   }

//   Future<void> _updateSingleStock(int productId) async {
//     final controller = _controllers[productId];
//     if (controller == null) return;

//     final quantity = int.tryParse(controller.text);
//     if (quantity == null || quantity < 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter a valid quantity'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _updatingStock = true;
//     });

//     try {
//       await ClientStockService.updateStock(
//         clientId: widget.clientId,
//         productId: productId,
//         quantity: quantity,
//       );

//       await _fetchClientStock();
//       setState(() {
//         _changedProducts.remove(productId);
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Stock updated successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to update stock: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _updatingStock = false;
//         });
//       }
//     }
//   }

//   Future<void> _updateAllChangedStock() async {
//     if (_changedProducts.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No changes to save'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _updatingStock = true;
//     });

//     int successCount = 0;
//     int errorCount = 0;

//     for (int productId in _changedProducts) {
//       final controller = _controllers[productId];
//       if (controller == null) continue;

//       final quantity = int.tryParse(controller.text);
//       if (quantity == null || quantity < 0) {
//         errorCount++;
//         continue;
//       }

//       try {
//         await ClientStockService.updateStock(
//           clientId: widget.clientId,
//           productId: productId,
//           quantity: quantity,
//         );
//         successCount++;
//       } catch (e) {
//         errorCount++;
//       }
//     }

//     await _fetchClientStock();
//     setState(() {
//       _changedProducts.clear();
//       _updatingStock = false;
//     });

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Updated: $successCount successful, $errorCount failed',
//           ),
//           backgroundColor: errorCount == 0 ? Colors.green : Colors.orange,
//         ),
//       );
//     }
//   }

//   void _toggleEditMode() {
//     setState(() {
//       _editMode = !_editMode;
//       if (!_editMode) {
//         _changedProducts.clear();
//         _initializeControllers(); // Reset controllers
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: appBackground,
//       appBar: GradientAppBar(
//         title: '${widget.clientName} - Stock',
//         actions: [
//           if (_editMode && _changedProducts.isNotEmpty)
//             IconButton(
//               icon: const Icon(Icons.save_alt),
//               onPressed: _updatingStock ? null : _updateAllChangedStock,
//               tooltip: 'Save All Changes (${_changedProducts.length})',
//             ),
//           IconButton(
//             icon: Icon(_editMode ? Icons.close : Icons.edit),
//             onPressed: _updatingStock ? null : _toggleEditMode,
//             tooltip: _editMode ? 'Cancel Edit' : 'Edit Mode',
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _updatingStock ? null : _loadData,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               // Search and filter section
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       offset: const Offset(0, 2),
//                       blurRadius: 4,
//                       color: Colors.grey.withOpacity(0.1),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           flex: 2,
//                           child: TextField(
//                             onChanged: (value) {
//                               setState(() {
//                                 _searchQuery = value;
//                               });
//                             },
//                             decoration: InputDecoration(
//                               hintText: 'Search products...',
//                               prefixIcon: const Icon(Icons.search),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 8,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: DropdownButtonFormField<String>(
//                             value: _selectedCategory,
//                             decoration: InputDecoration(
//                               labelText: 'Category',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 8,
//                               ),
//                             ),
//                             items: _categories.map((category) {
//                               return DropdownMenuItem(
//                                 value: category,
//                                 child: Text(
//                                   category,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               );
//                             }).toList(),
//                             onChanged: (value) {
//                               setState(() {
//                                 _selectedCategory = value!;
//                               });
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                     if (_editMode) ...[
//                       const SizedBox(height: 12),
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                           border:
//                               Border.all(color: Colors.blue.withOpacity(0.3)),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.info_outline,
//                                 color: Colors.blue, size: 16),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 'Edit Mode: Tap quantities to modify. ${_changedProducts.length} changes pending.',
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.blue,
//                                 ),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//               // Content
//               Expanded(
//                 child: _loading
//                     ? const Center(child: CircularProgressIndicator())
//                     : _errorMessage != null
//                         ? Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   _errorMessage!,
//                                   style: const TextStyle(color: Colors.red),
//                                   textAlign: TextAlign.center,
//                                 ),
//                                 const SizedBox(height: 16),
//                                 ElevatedButton(
//                                   onPressed: _loadData,
//                                   child: const Text('Retry'),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : _filteredProducts.isEmpty
//                             ? const Center(
//                                 child: Text('No products found'),
//                               )
//                             : ListView.builder(
//                                 padding: const EdgeInsets.all(12),
//                                 itemCount: _filteredProducts.length,
//                                 itemBuilder: (context, index) {
//                                   final product = _filteredProducts[index];
//                                   final stock = _clientStocks.firstWhere(
//                                     (s) => s.productId == product.id,
//                                     orElse: () => ClientStock(
//                                       id: 0,
//                                       quantity: 0,
//                                       clientId: widget.clientId,
//                                       productId: product.id,
//                                     ),
//                                   );
//                                   final controller = _controllers[product.id]!;
//                                   final hasChanges =
//                                       _changedProducts.contains(product.id);

//                                   return Card(
//                                     margin: const EdgeInsets.only(bottom: 8),
//                                     elevation: hasChanges ? 4 : 1,
//                                     color: hasChanges
//                                         ? Colors.blue.withOpacity(0.05)
//                                         : null,
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(12),
//                                       child: Row(
//                                         children: [
//                                           // Product image
//                                           Container(
//                                             width: 40,
//                                             height: 40,
//                                             decoration: BoxDecoration(
//                                               borderRadius:
//                                                   BorderRadius.circular(6),
//                                               color: Colors.grey[200],
//                                             ),
//                                             child: product.imageUrl != null
//                                                 ? ClipRRect(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                             6),
//                                                     child: CachedNetworkImage(
//                                                       imageUrl:
//                                                           product.imageUrl!,
//                                                       fit: BoxFit.cover,
//                                                       placeholder:
//                                                           (context, url) =>
//                                                               const Center(
//                                                         child: SizedBox(
//                                                           width: 16,
//                                                           height: 16,
//                                                           child:
//                                                               CircularProgressIndicator(
//                                                             strokeWidth: 2,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       errorWidget: (context,
//                                                               url, error) =>
//                                                           const Icon(
//                                                         Icons
//                                                             .image_not_supported,
//                                                         color: Colors.grey,
//                                                         size: 20,
//                                                       ),
//                                                     ),
//                                                   )
//                                                 : const Icon(
//                                                     Icons.inventory,
//                                                     color: Colors.grey,
//                                                     size: 20,
//                                                   ),
//                                           ),
//                                           const SizedBox(width: 12),
//                                           // Product details
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   product.name,
//                                                   style: const TextStyle(
//                                                     fontWeight: FontWeight.w600,
//                                                     fontSize: 13,
//                                                   ),
//                                                   maxLines: 2,
//                                                   overflow:
//                                                       TextOverflow.ellipsis,
//                                                 ),
//                                                 const SizedBox(height: 2),
//                                                 Text(
//                                                   product.category,
//                                                   style: TextStyle(
//                                                     fontSize: 11,
//                                                     color: Colors.grey[600],
//                                                   ),
//                                                   maxLines: 1,
//                                                   overflow:
//                                                       TextOverflow.ellipsis,
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                           // Stock quantity
//                                           SizedBox(
//                                             width: 80,
//                                             child: _editMode
//                                                 ? TextFormField(
//                                                     controller: controller,
//                                                     keyboardType:
//                                                         TextInputType.number,
//                                                     textAlign: TextAlign.center,
//                                                     style: const TextStyle(
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                       fontSize: 14,
//                                                     ),
//                                                     decoration: InputDecoration(
//                                                       border:
//                                                           OutlineInputBorder(
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(6),
//                                                         borderSide: BorderSide(
//                                                             color: Colors
//                                                                 .grey.shade300),
//                                                       ),
//                                                       focusedBorder:
//                                                           OutlineInputBorder(
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(6),
//                                                         borderSide:
//                                                             const BorderSide(
//                                                                 color:
//                                                                     Colors.blue,
//                                                                 width: 2),
//                                                       ),
//                                                       enabledBorder:
//                                                           OutlineInputBorder(
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(6),
//                                                         borderSide: BorderSide(
//                                                             color: Colors
//                                                                 .grey.shade300),
//                                                       ),
//                                                       contentPadding:
//                                                           const EdgeInsets
//                                                               .symmetric(
//                                                         horizontal: 4,
//                                                         vertical: 8,
//                                                       ),
//                                                       isDense: true,
//                                                       filled: true,
//                                                       fillColor: Colors.white,
//                                                     ),
//                                                     onChanged: (value) =>
//                                                         _onQuantityChanged(
//                                                             product.id),
//                                                   )
//                                                 : Container(
//                                                     height: 36,
//                                                     padding: const EdgeInsets
//                                                         .symmetric(
//                                                       horizontal: 8,
//                                                       vertical: 8,
//                                                     ),
//                                                     decoration: BoxDecoration(
//                                                       color: stock.quantity > 0
//                                                           ? Colors.green
//                                                               .withOpacity(0.1)
//                                                           : Colors.red
//                                                               .withOpacity(0.1),
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               6),
//                                                       border: Border.all(
//                                                         color: stock.quantity >
//                                                                 0
//                                                             ? Colors.green
//                                                                 .withOpacity(
//                                                                     0.3)
//                                                             : Colors.red
//                                                                 .withOpacity(
//                                                                     0.3),
//                                                       ),
//                                                     ),
//                                                     child: Center(
//                                                       child: Text(
//                                                         stock.quantity
//                                                             .toString(),
//                                                         style: TextStyle(
//                                                           fontWeight:
//                                                               FontWeight.bold,
//                                                           fontSize: 14,
//                                                           color: stock.quantity >
//                                                                   0
//                                                               ? Colors
//                                                                   .green[700]
//                                                               : Colors.red[700],
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                           ),
//                                           // Action button
//                                           if (!_editMode) ...[
//                                             const SizedBox(width: 8),
//                                             SizedBox(
//                                               width: 50,
//                                               height: 30,
//                                               child: ElevatedButton(
//                                                 onPressed: _updatingStock
//                                                     ? null
//                                                     : () => _updateSingleStock(
//                                                         product.id),
//                                                 style: ElevatedButton.styleFrom(
//                                                   padding: EdgeInsets.zero,
//                                                   textStyle: const TextStyle(
//                                                       fontSize: 11),
//                                                 ),
//                                                 child: const Text('Edit'),
//                                               ),
//                                             ),
//                                           ] else if (hasChanges) ...[
//                                             const SizedBox(width: 8),
//                                             const SizedBox(
//                                               width: 50,
//                                               child: Center(
//                                                 child: Icon(
//                                                   Icons.fiber_manual_record,
//                                                   color: Colors.blue,
//                                                   size: 12,
//                                                 ),
//                                               ),
//                                             ),
//                                           ] else ...[
//                                             const SizedBox(
//                                                 width: 58), // Maintain spacing
//                                           ],
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//               ),
//             ],
//           ),
//           // Loading overlay
//           if (_updatingStock)
//             Container(
//               color: Colors.black54,
//               child: const Center(
//                 child: Card(
//                   child: Padding(
//                     padding: EdgeInsets.all(20),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CircularProgressIndicator(),
//                         SizedBox(height: 16),
//                         Text('Updating stock...'),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       // Floating action button for bulk update
//       floatingActionButton: _editMode && _changedProducts.isNotEmpty
//           ? FloatingActionButton.extended(
//               onPressed: _updatingStock ? null : _updateAllChangedStock,
//               icon: const Icon(Icons.save),
//               label: Text('Save ${_changedProducts.length}'),
//               backgroundColor: Colors.green,
//             )
//           : null,
//     );
//   }
// }
