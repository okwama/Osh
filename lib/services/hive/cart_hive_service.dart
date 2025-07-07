import 'package:hive/hive.dart';
import 'package:woosh/models/order/orderitem_model.dart';

class CartHiveService {
  static const String _boxName = 'cart_items';
  late Box<Map> _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<OrderItem> getCartItems() {
    final items = <OrderItem>[];
    for (int i = 0; i < _box.length; i++) {
      final data = _box.getAt(i);
      if (data != null) {
        items.add(OrderItem.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return items;
  }

  Future<void> addItem(OrderItem item) async {
    await _box.add(item.toJson());
  }

  Future<void> updateItem(int index, OrderItem item) async {
    await _box.putAt(index, item.toJson());
  }

  Future<void> removeItem(int index) async {
    await _box.deleteAt(index);
  }

  Future<void> clearCart() async {
    await _box.clear();
  }

  Future<void> close() async {
    await _box.close();
  }
}
