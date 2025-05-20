import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String category;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    this.quantity = 1,
  });

  factory CartItem.fromMap(String id, Map<String, dynamic> data) {
    return CartItem(
      id: id,
      name: data['producto'] ?? '',
      price: (data['precio'] ?? 0).toDouble(),
      category: data['categoria'] ?? '',
      imageUrl: data['imagen'] ?? '',
    );
  }

  double get total => price * quantity;
}

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.total);

  void addItem(
    String id,
    String name,
    String imageUrl,
    double price,
    String category,
  ) {
    final existingItemIndex = _items.indexWhere((item) => item.id == id);

    if (existingItemIndex >= 0) {
      _items[existingItemIndex].quantity += 1;
    } else {
      _items.add(
        CartItem(
          id: id,
          name: name,
          imageUrl: imageUrl,
          price: price,
          category: category,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    final existingItemIndex = _items.indexWhere((item) => item.id == id);

    if (existingItemIndex >= 0) {
      if (_items[existingItemIndex].quantity > 1) {
        _items[existingItemIndex].quantity -= 1;
      } else {
        _items.removeAt(existingItemIndex);
      }
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}