import 'package:app_cafeteria/screen_tienda/store_own_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app_cafeteria/app_colors/app_colors.dart';

class AgregarProductoPage extends StatefulWidget {
  const AgregarProductoPage({super.key});

  @override
  State<AgregarProductoPage> createState() => _AgregarProductoPageState();
}

class _AgregarProductoPageState extends State<AgregarProductoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _imagenController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();

  Future<void> _guardarProducto() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('Productos').add({
          'producto': _nombreController.text.trim(),
          'precio': double.parse(_precioController.text.trim()),
          'stock': _stockController.text.trim(),
          'imagen': _imagenController.text.trim(),
          'categoria': _categoriaController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto agregado correctamente')),
        );
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const StoreOwnPage())
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto' ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.backgroundLight,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto',
                        labelStyle: TextStyle(
                          color: Color.fromARGB(255, 0, 43, 107),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio',
                labelStyle: TextStyle(
                          color: Color.fromARGB(255, 0, 43, 107),
                          fontWeight: FontWeight.bold,
                        ),),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock',
                labelStyle: TextStyle(
                          color: Color.fromARGB(255, 0, 43, 107),
                          fontWeight: FontWeight.bold,
                        ),),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imagenController,
                decoration: const InputDecoration(labelText: 'URL de imagen',
                labelStyle: TextStyle(
                          color: Color.fromARGB(255, 0, 43, 107),
                          fontWeight: FontWeight.bold,
                        ),),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoria del Producto',
                labelStyle: TextStyle(
                          color: Color.fromARGB(255, 0, 43, 107),
                          fontWeight: FontWeight.bold,
                        ),),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _guardarProducto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Guardar',
                  style: TextStyle(color: AppColors.backgroundLight),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: AppColors.backgroundLight,
    );
  }
}
