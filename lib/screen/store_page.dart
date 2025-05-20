import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/card_productos/productos_card.dart';
import 'package:app_cafeteria/widgets/header_page.dart';
import 'package:flutter/material.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final int _currentIndex = 0;
  String _selectedCategory = 'Todo';
  final List<String> _categories = [
    'Todo',
    'Empanadas',
    'Snacks',
    'Bebidas',
    'Sandwich',
  ];
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'Alfajor',
      'imageUrl':
          'https://as1.ftcdn.net/v2/jpg/01/40/12/82/1000_F_140128263_jMlP85mDNLgdxmN3tOGtC9DyST0ONsUx.jpg',
      'price': 550.0,
      'category': 'Snacks',
    },
    {
      'id': '2',
      'name': 'Completo',
      'imageUrl':
          'https://rosselotsurdelivery.cl/wp-content/uploads/2022/09/Mesa-de-trabajo-1@170x-20.jpg',
      'price': 2500.0,
      'category': 'Sandwich',
    },
    {
      'id': '3',
      'name': 'Empanada de queso',
      'imageUrl': 'https://www.chefandcook.cl/carta/queso-solo-fritas.jpg',
      'price': 2800.0,
      'category': 'Empanadas',
    },
    {
      'id': '4',
      'name': 'Sopaipilla',
      'imageUrl':
          'https://ik.imagekit.io/admsys/elpalacio/tr:n-product_square/site/resources/uploads/productos/normal/176793871e4061429fc20cdfc6256840.jpg',
      'price': 300.0,
      'category': 'Empanadas',
    },
    {
      'id': '5',
      'name': 'Papas Fritas',
      'imageUrl':
          'https://dojiw2m9tvv09.cloudfront.net/41056/product/X_793793.jpg?82&time=1745014867',
      'price': 1600.0,
      'category': 'Snacks',
    },
    {
      'id': '6',
      'name': 'Ramitas',
      'imageUrl':
          'https://es.chinchileproducts.com/cdn/shop/products/Ramitas-Evercrisp-Original_1176x1176.jpg?v=1613625001',
      'price': 1400.0,
      'category': 'Snacks',
    },
    {
      'id': '7',
      'name': 'Sopaipilla',
      'imageUrl':
          'https://ik.imagekit.io/admsys/elpalacio/tr:n-product_square/site/resources/uploads/productos/normal/176793871e4061429fc20cdfc6256840.jpg',
      'price': 300.0,
      'category': 'Empanadas',
    },
    {
      'id': '8',
      'name': 'Coca-cola',
      'imageUrl':
          'https://cdnx.jumpseller.com/gino/image/41447594/BEBIDAS_COCA_COLA_LATA_350.png?1736958180',
      'price': 1200.0,
      'category': 'Bebidas',
    },
    {
      'id': '9',
      'name': 'Churrascos',
      'imageUrl':
          'https://cecinasllanquihue.cl/blog/wp-content/uploads/2022/01/churrasco-italiano-carne-500x367-1.jpeg',
      'price': 2400.0,
      'category': 'Sandwich',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> categoryFiltered =
        _selectedCategory == 'Todo'
            ? _products
            : _products
                .where((p) => p['category'] == _selectedCategory)
                .toList();

    if (_searchTerm.isNotEmpty) {
      return categoryFiltered
          .where(
            (p) => p['name'].toString().toLowerCase().contains(
              _searchTerm.toLowerCase(),
            ),
          )
          .toList();
    }

    return categoryFiltered;
  }

  void _onQuantityChanged(int index, int quantity) {
    print('Producto: ${_filteredProducts[index]['name']}, Cantidad: $quantity');
    // aquí tu lógica de carrito
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const HeaderPage(
        showBackButton: false,
      ), // Added HeaderPage as the AppBar
      body: SafeArea(
        child: Column(
          children: [
            // Removed the header container that was here before

            // — Buscador —
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchTerm = value;
                  });
                },
              ),
            ),

            // — Categorías —
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final sel = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color:
                            sel
                                ? AppColors.primaryMedium
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.black,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // — Lista de Productos —
            Expanded(
              child:
                  _filteredProducts.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron productos',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (ctx, i) {
                          final p = _filteredProducts[i];
                          return ProductCard(
                            id: p['id'],
                            name: p['name'],
                            imageUrl: p['imageUrl'],
                            price: p['price'],
                            category: p['category'],
                            onQuantityChanged: (q) => _onQuantityChanged(i, q),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}