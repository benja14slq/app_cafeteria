import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class EditarProductoPage extends StatefulWidget {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String category;
  final String stock;

  const EditarProductoPage({
    super.key,
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.stock,
    });



  @override
  State<EditarProductoPage> createState() => _EditarProductoPageState();
}

class _EditarProductoPageState extends State<EditarProductoPage> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _stockController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _priceController = TextEditingController(text: widget.price.toString());
    _imageUrlController = TextEditingController(text: widget.imageUrl);
    _stockController = TextEditingController(text: widget.stock);
    _categoryController = TextEditingController(text: widget.category);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    try {
      await FirebaseFirestore.instance.collection("Productos").doc(widget.id).update({
        'name': _nameController.text,
        'price': double.tryParse(_priceController.text) ?? 0,
        'imageUrl': _imageUrlController.text,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'category': _categoryController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto Actualizado')),
      );

      Navigator.pop(context);
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar los cambios')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.backgroundLight,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'URL de imagen'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardarCambios, 
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.backgroundLight,
              ),
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.backgroundLight,
    );
  }
}