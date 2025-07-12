import 'package:flutter/material.dart';
import 'package:woosh/models/client/client_payment_model.dart';

/// Widget for displaying payment history with filtering and sorting
class PaymentHistoryCard extends StatefulWidget {
  final List<ClientPayment> payments;
  final bool loading;
  final Function() onRefresh;

  const PaymentHistoryCard({
    super.key,
    required this.payments,
    required this.loading,
    required this.onRefresh,
  });

  @override
  State<PaymentHistoryCard> createState() => _PaymentHistoryCardState();
}

class _PaymentHistoryCardState extends State<PaymentHistoryCard> {
  String _selectedStatus = 'ALL';
  String _selectedSort = 'NEWEST';

  List<ClientPayment> get _filteredPayments {
    List<ClientPayment> filtered = _selectedStatus == 'ALL'
        ? widget.payments
        : widget.payments
            .where((p) => (p.status ?? '').toUpperCase() == _selectedStatus)
            .toList();
    switch (_selectedSort) {
      case 'NEWEST':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'OLDEST':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'AMOUNT_HIGH':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'AMOUNT_LOW':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment History',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<String>(
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(
                    value: 'ALL',
                    child: Text('All',
                        style: TextStyle(fontSize: 11, color: Colors.black))),
                DropdownMenuItem(
                    value: 'PENDING',
                    child: Text('Pending',
                        style: TextStyle(fontSize: 11, color: Colors.black))),
                DropdownMenuItem(
                    value: 'VERIFIED',
                    child: Text('Verified',
                        style: TextStyle(fontSize: 11, color: Colors.black))),
                DropdownMenuItem(
                    value: 'REJECTED',
                    child: Text('Rejected',
                        style: TextStyle(fontSize: 11, color: Colors.black))),
              ],
              onChanged: (val) {
                setState(() => _selectedStatus = val!);
              },
              style: const TextStyle(fontSize: 11, color: Colors.black),
              isDense: true,
              iconSize: 16,
              dropdownColor: Colors.white,
            ),
            DropdownButton<String>(
              value: _selectedSort,
              items: const [
                DropdownMenuItem(
                    value: 'NEWEST',
                    child: Text('Newest',
                        style: TextStyle(fontSize: 11, color: Colors.black))),
                DropdownMenuItem(
                    value: 'OLDEST',
                    child: Text('Oldest',
                        style: TextStyle(fontSize: 11, color: Colors.black))),
                DropdownMenuItem(
                    value: 'AMOUNT_HIGH',
                    child: Text('Amount ↑',
                        style: TextStyle(fontSize: 11, color: Colors.black))),
                DropdownMenuItem(
                    value: 'AMOUNT_LOW',
                    child: Text('Amount ↓',
                        style: TextStyle(fontSize: 11, color: Colors.black))),
              ],
              onChanged: (val) {
                setState(() => _selectedSort = val!);
              },
              style: const TextStyle(fontSize: 11, color: Colors.black),
              isDense: true,
              iconSize: 16,
              dropdownColor: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: widget.loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                    ? const Text('No payments yet.',
                        style: TextStyle(fontSize: 11))
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredPayments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final p = _filteredPayments[idx];
                          return InkWell(
                            onTap: p.imageUrl != null
                                ? () => showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Image.network(p.imageUrl!),
                                      ),
                                    )
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left side: Image or Icon
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.grey[100],
                                    ),
                                    child: p.imageUrl != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: Image.network(
                                              p.imageUrl!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(Icons.receipt_long,
                                            size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  // Middle: Payment details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.method ?? 'No Method',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(p.status)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            p.status,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _getStatusColor(p.status),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Right side: Date and Amount
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        p.date
                                            .toLocal()
                                            .toString()
                                            .split(".")[0],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Ksh ${p.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'VERIFIED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
