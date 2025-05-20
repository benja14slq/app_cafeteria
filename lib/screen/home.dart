import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/narbarComponent/narbar.dart';
import 'package:app_cafeteria/screen/pedidos.dart';
import 'package:app_cafeteria/screen/perfil_page.dart';
import 'package:app_cafeteria/screen/store_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; //Controla que pestaña esta activa

  // Aquí tus pantallas SIN Scaffold ni NavBar
  final List<Widget> _pages = const [StorePage(), OrderPage(), AccountPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // Usamos IndexedStack para que mantenga estado de cada página
      body: IndexedStack(index: _currentIndex, children: _pages),

      // NavBar 100% estático y siempre abajo
      bottomNavigationBar: FloatingNavBar(
        initialIndex: _currentIndex,
        onTabChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}