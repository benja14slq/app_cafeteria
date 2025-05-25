import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/models/cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StoreRetiroPage extends StatefulWidget {
  const StoreRetiroPage({super.key});

  @override
  State<StoreRetiroPage> createState() => _StoreRetiroPageState();
}

class _StoreRetiroPageState extends State<StoreRetiroPage> {
  List<CartItem> _allProducts = [];
  final String _selectedCategory = 'Todo';
  final String _searchTerm = '';
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
        snapshot.docs
            .map((doc) => CartItem.fromMap(doc.id, doc.data()))
            .toList();
    setState(() {
      _allProducts = productos;
    });
  }

  List<String> get _categories {
    final uniqueCategories =
        _allProducts.map((p) => p.category).toSet().toList();
    return ['Todo', ...uniqueCategories];
  }

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Cafetería Express',
          style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
        ],
      ),
    );
  }
}
