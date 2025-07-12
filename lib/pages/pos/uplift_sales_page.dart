import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/uplift_sale_model.dart';
import 'package:woosh/services/core/uplift_sale_service.dart';
import 'package:woosh/utils/date_utils.dart' as custom_date;
import 'package:woosh/utils/currency_utils.dart';
import 'package:woosh/pages/client/viewclient_page.dart';
import 'package:woosh/pages/pos/upliftSaleCart_page.dart';
import 'package:woosh/models/client/client_model.dart';

class UpliftSalesPage extends StatefulWidget {
  const UpliftSalesPage({super.key});

  @override
  State<UpliftSalesPage> createState() => _UpliftSalesPageState();
}

class _UpliftSalesPageState extends State<UpliftSalesPage> {
  final RxList<UpliftSale> _sales = <UpliftSale>[].obs;
  final RxString _selectedStatus = 'all'.obs;
  final Rx<DateTime?> _startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> _endDate = Rx<DateTime?>(null);
  final RxInt _selectedClientId = RxInt(0);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final sales = await UpliftSaleService.getUpliftSales(
        status: _selectedStatus.value == 'all' ? null : _selectedStatus.value,
        startDate: _startDate.value,
        endDate: _endDate.value,
        clientId: _selectedClientId.value == 0 ? null : _selectedClientId.value,
      );

      _sales.value = sales;
    } catch (e) {
      _errorMessage.value = 'Failed to load sales: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate.value ?? DateTime.now()
          : _endDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isStartDate) {
        _startDate.value = picked;
      } else {
        _endDate.value = picked;
      }
      _loadSales();
    }
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => DropdownButtonFormField<String>(
                value: _selectedStatus.value,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: [
                  'all',
                  'pending',
                  'completed',
                  'cancelled',
                ].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status.capitalizeFirst!),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    _selectedStatus.value = value;
                    _loadSales();
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => TextButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Flexible(
                        child: Text(
                          _startDate.value != null
                              ? custom_date.DateUtils.formatDate(
                                  _startDate.value!)
                              : 'Start Date',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(
                    () => TextButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Flexible(
                        child: Text(
                          _endDate.value != null
                              ? custom_date.DateUtils.formatDate(
                                  _endDate.value!)
                              : 'End Date',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleItem(UpliftSale sale) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          _showSaleDetails(sale);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sale #${sale.id} - ${sale.client?.name ?? 'No Client'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(sale.status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      sale.status.capitalizeFirst!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items: ${sale.items.length}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Total: ${CurrencyUtils.format(sale.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Date: ${custom_date.DateUtils.formatDateTime(sale.createdAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSaleDetails(UpliftSale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sale #${sale.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${sale.status.capitalizeFirst}'),
              const SizedBox(height: 8),
              if (sale.client != null) ...[
                Text('Client: ${sale.client!.name}'),
                const SizedBox(height: 8),
              ],
              Text('Total Amount: ${CurrencyUtils.format(sale.totalAmount)}'),
              const SizedBox(height: 8),
              Text(
                  'Date: ${custom_date.DateUtils.formatDateTime(sale.createdAt)}'),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sale.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${item.product?.name ?? 'Product #${item.productId}'} - '
                      'Qty: ${item.quantity}, '
                      'Price: ${CurrencyUtils.format(item.unitPrice)}, '
                      'Total: ${CurrencyUtils.format(item.total)}',
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uplift Sales'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Get.offAllNamed('/home');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: Obx(() {
              if (_isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_errorMessage.value.isNotEmpty) {
                return Center(
                  child: Text(
                    _errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (_sales.isEmpty) {
                return const Center(
                  child: Text('No uplift sales found'),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadSales,
                child: ListView.builder(
                  itemCount: _sales.length,
                  itemBuilder: (context, index) {
                    final sale = _sales[index];
                    return _buildSaleItem(sale);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(
            () => const ViewClientPage(forUpliftSale: true),
            preventDuplicates: true,
            transition: Transition.rightToLeft,
          )?.then((selectedClient) {
            if (selectedClient != null && selectedClient is Client) {
              Get.off(
                () => UpliftSaleCartPage(
                  outlet: selectedClient,
                ),
                transition: Transition.rightToLeft,
              );
            }
          });
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
