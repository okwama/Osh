class ClientPayment {
  final int id;
  final int clientId;
  final int userId;
  final double amount;
  final String? method;
  final String? imageUrl;
  final String status;
  final DateTime date;

  ClientPayment({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.amount,
    this.imageUrl,
    this.method,
    required this.status,
    required this.date,
  });

  // Factory method for creating a payment request
  static Map<String, dynamic> createPaymentRequest({
    required int clientId,
    required double amount,
  }) {
    return {
      'client_id': clientId, // Server might expect snake_case
      'amount': amount.toString(), // Convert to string to ensure proper format
    };
  }

  factory ClientPayment.fromJson(Map<String, dynamic> json) {
    return ClientPayment(
      id: json['id'],
      clientId: json['clientId'],
      userId: json['userId'],
      amount: json['amount'].toDouble(),
      imageUrl: json['imageUrl'],
      method: json['method'],
      status: json['status'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'userId': userId,
      'amount': amount,
      'imageUrl': imageUrl,
      'method': method,
      'status': status,
      'date': date.toIso8601String(),
    };
  }
}
