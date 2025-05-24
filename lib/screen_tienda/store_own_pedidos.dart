import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/screen_tienda/narbar_tienda.dart';
import 'package:app_cafeteria/screen/pedidos.dart';
import 'package:app_cafeteria/screen/perfil_page.dart';
import 'package:app_cafeteria/screen_tienda/store_Retiro.dart';
import 'package:app_cafeteria/screen_tienda/store_delivery.dart';
import 'package:app_cafeteria/screen_tienda/store_own_page.dart';
import 'package:flutter/material.dart';

class StoreOwnPedidos extends StatefulWidget {
  const StoreOwnPedidos({super.key});

  @override
  State<StoreOwnPedidos> createState() => _StoreOwnPedidosState();
}

class _StoreOwnPedidosState extends State<StoreOwnPedidos> {
  int _currentIndex = 0; //Controla que pestaña esta activa

  // Aquí tus pantallas SIN Scaffold ni NavBar
  final List<Widget> _pages = const [StoreRetiroPage(),StoreDeliveryPage (), StoreOwnPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // Usamos IndexedStack para que mantenga estado de cada página
      body: IndexedStack(index: _currentIndex, children: _pages),

      // NavBar 100% estático y siempre abajo
      bottomNavigationBar: FloatingNavBarTienda(
        initialIndex: _currentIndex,
        onTabChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}