import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/models/cart_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String category;
  final VoidCallback onAddToCart;
  final void Function(dynamic q)? onQuantityChanged;

  const ProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context, listen: false);
    //Se utiliza Provider para obtener el modelo de carrito de compras
    //CartModel, sin escuchar cambios.

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3, // Añadimos sombra para dar profundidad
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Bordes más redondeados
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Padding aumentado
        child: Row(
          children: [
            // Imagen del producto con efecto de sombra
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  width: 90, // Ligeramente más grande
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90,
                      height: 90,
                      color: AppColors.secondaryLight,
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppColors.primaryDark,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17, // Texto ligeramente más grande
                      color: AppColors.primaryDark, // Usando color de AppColors
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Categoría del producto
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Precio con estilo mejorado
                  Text(
                    '\$${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color:
                          AppColors.accent1, // Color destacado para el precio
                    ),
                  ),
                ],
              ),
            ),
            // Botón para agregar al carrito con icono
            ElevatedButton.icon(
              onPressed: () {
                cart.addItem(id, name, imageUrl, price, category);

                // Llamar callback si está definido
                onQuantityChanged?.call(1);

                // Mostrar un SnackBar con animación
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$name agregado al carrito',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.primaryMedium,
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'DESHACER',
                      textColor: Colors.white,
                      onPressed: () {
                        cart.removeItem(id);
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, // Usando color de AppColors
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2, // Sombra para el botón
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text(
                'Agregar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
