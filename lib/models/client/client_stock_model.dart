class ClientStock {
  final int id;
  final int quantity;
  final int clientId;
  final int productId;
  final ClientStockClient? client;
  final ClientStockProduct? product;

  ClientStock({
    required this.id,
    required this.quantity,
    required this.clientId,
    required this.productId,
    this.client,
    this.product,
  });

  factory ClientStock.fromJson(Map<String, dynamic> json) {
    return ClientStock(
      id: json['id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      clientId: json['clientId'] ?? 0,
      productId: json['productId'] ?? 0,
      client: json['client'] != null
          ? ClientStockClient.fromJson(json['client'])
          : null,
      product: json['product'] != null
          ? ClientStockProduct.fromJson(json['product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'clientId': clientId,
      'productId': productId,
      if (client != null) 'client': client!.toJson(),
      if (product != null) 'product': product!.toJson(),
    };
  }
}

class ClientStockClient {
  final int id;
  final String name;
  final String? contact;

  ClientStockClient({
    required this.id,
    required this.name,
    this.contact,
  });

  factory ClientStockClient.fromJson(Map<String, dynamic> json) {
    return ClientStockClient(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      contact: json['contact'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (contact != null) 'contact': contact,
    };
  }
}

class ClientStockProduct {
  final int id;
  final String name;
  final String category;
  final String unitCost;
  final String? description;
  final String? image;

  ClientStockProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.unitCost,
    this.description,
    this.image,
  });

  factory ClientStockProduct.fromJson(Map<String, dynamic> json) {
    return ClientStockProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      unitCost: json['unit_cost'] ?? '0.00',
      description: json['description'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit_cost': unitCost,
      if (description != null) 'description': description,
      if (image != null) 'image': image,
    };
  }
}
