import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/models/cart_model.dart';
import 'package:app_cafeteria/screen/pedidos.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Un AppBar reutilizable que:
///  • Usa AppColors.primary de fondo.
///  • Muestra título configurable (por defecto "Cafetería Express").
///  • Muestra el botón de back según el parámetro showBackButton.
///  • Incluye siempre el icono de carrito con badge.
class HeaderPage extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool
  showBackButton; // Nuevo parámetro para controlar la visibilidad del botón

  const HeaderPage({
    super.key,
    this.title = 'Cafetería Express',
    this.showBackButton = true, // Por defecto se muestra
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading:
          showBackButton // Usa el parámetro en lugar de Navigator.canPop()
              ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
              : null,
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const OrderPage()),
                );
              },
            ),
            Consumer<CartModel>(
              builder:
                  (ctx, cart, _) => Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}