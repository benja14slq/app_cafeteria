import 'package:app_cafeteria/models/cart_model.dart';
import 'package:app_cafeteria/screen_tienda/cart_inventario_model.dart';
import 'package:app_cafeteria/screen_tienda/inventario_card.dart';
import 'package:app_cafeteria/widgets/header_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StoreOwnPage extends StatefulWidget {
  const StoreOwnPage({super.key});

  @override
  State<StoreOwnPage> createState() => _StoreOwnPageState();
}

class _StoreOwnPageState extends State<StoreOwnPage> {
  List<CartInventario> _allProducts = [];
  String _selectedCategory = 'Todo';
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Productos').get();
    final productos =
        snapshot.docs.map((doc) => CartInventario.fromMap(doc.id, doc.data())).toList();
    setState(() {
      _allProducts = productos;
    });
  }

  List<String> get _categories {
    final uniqueCategories =
        _allProducts.map((p) => p.category).toSet().toList();
    return ['Todo', ...uniqueCategories];
  }

  List<CartInventario> get _filteredProducts {
    List<CartInventario> categoryFiltered = _selectedCategory == 'Todo'
        ? _allProducts
        : _allProducts.where((p) => p.category == _selectedCategory).toList();

    if (_searchTerm.isNotEmpty) {
      return categoryFiltered
          .where((p) => p.name.toLowerCase().contains(_searchTerm.toLowerCase()))
          .toList();
    }

    return categoryFiltered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

    return Scaffold(
      appBar: const HeaderPage(showBackButton: false),
      body: Column(
        children: [
          // 🔍 Buscador
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onChanged: (value) => setState(() => _searchTerm = value),
            ),
          ),

          // 🏷️ Filtro de Categorías
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // 📦 Lista de productos
          Expanded(
            child: _allProducts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No se encontraron productos',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final p = _filteredProducts[index];
                          return InventarioCard(
                            id: p.id,
                            name: p.name,
                            imageUrl: p.imageUrl,
                            price: p.price,
                            category: p.category,
                            stock: p.stock,
                            onQuantityChanged: (newValue) async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('Productos')
                                    .doc(p.id)
                                    .update({'stock': newValue});

                                setState(() {
                                  _allProducts = _allProducts.map((prod) {
                                    if (prod.id == p.id) {
                                      return CartInventario(
                                        id: prod.id,
                                        name: prod.name,
                                        imageUrl: prod.imageUrl,
                                        price: prod.price,
                                        category: prod.category,
                                        stock: newValue.toString(),
                                        quantity: prod.quantity,
                                      );
                                    }
                                    return prod;
                                  }).toList();
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Stock actualizado')),
                                );
                              } catch (e) {
                                print('Error al actualizar el stock: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Error al actualizar el stock')),
                                );
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
