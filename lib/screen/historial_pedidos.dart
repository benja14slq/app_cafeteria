import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HistorialPedidos extends StatefulWidget {
  const HistorialPedidos({super.key});

  @override
  State<HistorialPedidos> createState() => _HistorialPedidosState();
}

class _HistorialPedidosState extends State<HistorialPedidos>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPedidos();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPedidos() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Vouches')
          .where('usuarioId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final pedidos = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'orden': data['orden'] ?? '',
          'tipo': data['tipo'] ?? '',
          'total': (data['total'] ?? 0).toDouble(),
          'fecha': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : null,
          'productos': List<Map<String, dynamic>>.from(
            data['descripcion'] ?? [],
          ),
          'entregado': data['entregado'] ?? false,
        };
      }).toList();

      setState(() {
        _pedidos = pedidos;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _pedidos.isEmpty
                    ? _buildEmptyState()
                    : _buildPedidosList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial de Pedidos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Revisa tus pedidos anteriores',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando historial...',
            style: TextStyle(
              color: AppColors.primaryMedium,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sin pedidos aún',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cuando realices tu primer pedido,\naparecerá aquí tu historial',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: const Text(
                  'Hacer mi primer pedido',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPedidosList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadPedidos,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _pedidos.length,
          itemBuilder: (context, index) {
            final pedido = _pedidos[index];
            return _buildPedidoCard(pedido, index);
          },
        ),
      ),
    );
  }

  Widget _buildPedidoCard(Map<String, dynamic> pedido, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPedidoHeader(pedido),
                const SizedBox(height: 16),
                _buildPedidoInfo(pedido),
                const SizedBox(height: 16),
                _buildProductosList(pedido['productos']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPedidoHeader(Map<String, dynamic> pedido) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTipoColor(pedido['tipo']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTipoIcon(pedido['tipo']),
            color: _getTipoColor(pedido['tipo']),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orden #${pedido['orden']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                pedido['tipo'].toString().toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getTipoColor(pedido['tipo']),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _buildEstadoChip(pedido['entregado']),
      ],
    );
  }

  Widget _buildEstadoChip(bool entregado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: entregado ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            entregado ? Icons.check_circle : Icons.access_time,
            size: 16,
            color: entregado ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            entregado ? 'Entregado' : 'Pendiente',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: entregado ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoInfo(Map<String, dynamic> pedido) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.primaryMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pedido['fecha'] != null
                          ? DateFormat('dd/MM/yyyy - HH:mm').format(pedido['fecha'])
                          : 'Fecha no disponible',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '\$${pedido['total'].toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosList(List<dynamic> productos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 16,
              color: AppColors.primaryMedium,
            ),
            const SizedBox(width: 8),
            Text(
              'Productos (${productos.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...productos.map((producto) => _buildProductoItem(producto)),
      ],
    );
  }

  Widget _buildProductoItem(Map<String, dynamic> producto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              producto['producto'] ?? 'Producto',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'x${producto['cantidad']}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${producto['subtotal']}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'delivery':
        return Icons.delivery_dining;
      case 'retiro':
      case 'pickup':
        return Icons.store;
      default:
        return Icons.shopping_bag;
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'delivery':
        return AppColors.primary;
      case 'retiro':
      case 'pickup':
        return AppColors.secondary;
      default:
        return AppColors.primaryMedium;
    }
  }
}
