import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/card_productos/productos_card.dart';
import 'package:app_cafeteria/models/cart_model.dart';
import 'package:app_cafeteria/widgets/header_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  List<CartItem> _allProducts = []; //Lista de los productos obtenidos desde Firestore
  String _selectedCategory = 'Todo'; // Categoria actualmente seleccionada
  String _searchTerm = ''; // Búsqueda ingresada por el usuario
  final TextEditingController _searchController = TextEditingController(); // Controlador del campo de búsqueda

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Cargar productos al iniciar pantalla
  }

// Obtener productos desde 'Productos' de Firestrore 
  Future<void> _loadProducts() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Productos').get();
    final productos =
        snapshot.docs
            .map((doc) => CartItem.fromMap(doc.id, doc.data())) // Convertir cada documento en CartItem
            .toList();
    setState(() {
      _allProducts = productos;
    });
  }

// Obtener todas las categorías únicas de los productos
  List<String> get _categories {
    final uniqueCategories =
        _allProducts.map((p) => p.category).toSet().toList();
    return ['Todo', ...uniqueCategories]; // Agrega 'Todo' al inicio
  }

 // Filtrar producto según la categoría y el termino de búsqueda
  List<CartItem> get _filteredProducts {
    List<CartItem> categoryFiltered =
        _selectedCategory == 'Todo'
            ? _allProducts
            : _allProducts
                .where((p) => p.category == _selectedCategory)
                .toList();

    if (_searchTerm.isNotEmpty) {
      return categoryFiltered
          .where(
            (p) => p.name.toLowerCase().contains(_searchTerm.toLowerCase()),
          )
          .toList();
    }

    return categoryFiltered;
  }

  @override
  void dispose() {
    _searchController.dispose(); // Liberar recursos
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
              onChanged: (value) => setState(() => _searchTerm = value), // Actualizar término de búsqueda
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
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
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
            child:
                _allProducts.isEmpty
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
                        return ProductCard(
                          id: p.id,
                          name: p.name,
                          imageUrl: p.imageUrl,
                          price: p.price,
                          category: p.category,
                          onAddToCart: () {
                            cart.addItem(
                              p.id,
                              p.name,
                              p.imageUrl,
                              p.price,
                              p.category,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${p.name} agregado al carrito'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
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
