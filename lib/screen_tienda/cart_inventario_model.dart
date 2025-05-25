import 'package:flutter/foundation.dart';

// Modelo de un producto en el carrito de Inventario
class CartInventario {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String category;
  final String stock;

  // Constructor
  CartInventario({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.stock,
  });

  // Crear una instancia desde un mapa de Datos
  factory CartInventario.fromMap(String id, Map<String, dynamic> data) {
    return CartInventario(
      id: id,
      name: data['producto'] ?? '',
      price: (data['precio'] ?? 0).toDouble(),
      category: data['categoria'] ?? '',
      imageUrl: data['imagen'] ?? '',
      stock: (data['stock'] ?? '').toString(),
    );
  }
}

// Modelo general del carrito de inventario
class CartModelInventario extends ChangeNotifier {
  final List<CartInventario> _items = []; //Lista de productos

  // Getter para exponer una lista inmodificables de productos
  List<CartInventario> get items => List.unmodifiable(_items);

  void setItems(List<CartInventario> newItems) {
    _items.clear();
    _items.addAll(newItems);
    notifyListeners();
  }
}
