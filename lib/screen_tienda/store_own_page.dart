import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/screen_tienda/agregar_producto.dart';
import 'package:app_cafeteria/screen_tienda/cart_inventario_model.dart';
import 'package:app_cafeteria/screen_tienda/inventario_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StoreOwnPage extends StatefulWidget {
  const StoreOwnPage({super.key});

  @override
  State<StoreOwnPage> createState() => _StoreOwnPageState();
}

class _StoreOwnPageState extends State<StoreOwnPage> {
  String _selectedCategory = 'Todo';
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: const Text(
          'Cafetería Express',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.backgroundLight),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AgregarProductoPage(),
                ),
              );
            },
          ),
        ],
      ),
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

          // 📦 Productos en tiempo real
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Productos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final allProducts = docs.map((doc) =>
                  CartInventario.fromMap(doc.id, doc.data() as Map<String, dynamic>)
                ).toList();

                final categories = ['Todo', ...{
                  for (var p in allProducts) p.category
                }];

                // 🏷️ Filtro de Categorías
                final filteredProducts = allProducts.where((p) {
                  final matchCategory = _selectedCategory == 'Todo' || p.category == _selectedCategory;
                  final matchSearch = p.name.toLowerCase().contains(_searchTerm.toLowerCase());
                  return matchCategory && matchSearch;
                }).toList();

                return Column(
                  children: [
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
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

                    // 📋 Lista de productos
                    filteredProducts.isEmpty
                        ? const Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No se encontraron productos', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                ],
                              ),
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final p = filteredProducts[index];
                                return InventarioCard(
                                  id: p.id,
                                  name: p.name,
                                  imageUrl: p.imageUrl,
                                  price: p.price,
                                  category: p.category,
                                  stock: p.stock,
                                  onStockUpdated: (newStockStr) async {
                                    final newStock = int.tryParse(newStockStr);
                                    if (newStock == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Stock inválido')),
                                      );
                                      return;
                                    }

                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('Productos')
                                          .doc(p.id)
                                          .update({'stock': newStock});
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
