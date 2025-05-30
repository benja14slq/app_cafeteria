import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/screen_tienda/pedidos_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StoreRetiroPage extends StatefulWidget {
  const StoreRetiroPage({super.key});

  @override
  State<StoreRetiroPage> createState() => _StoreRetiroPageState();
}

class _StoreRetiroPageState extends State<StoreRetiroPage> {
  List<PedidosOrder> _pedidosOrders = [];

  @override
  void initState() {
    super.initState();
    _loadRetiroOrders();
  }

  Future<void> _loadRetiroOrders() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('Vouches')
            .where('tipo', isEqualTo: 'Retiro en Local')
            .orderBy('timestamp', descending: true)
            .get();

    final orders =
        snapshot.docs
            .map((doc) => PedidosOrder.fromFirestore(doc.id, doc.data()))
            .toList();

    setState(() {
      _pedidosOrders = orders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: Text(
          'Cafetería Express',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _pedidosOrders.isEmpty
              ? const Center(child: Text('No hay pedidos registrados'))
              : ListView.builder(
                itemCount: _pedidosOrders.length,
                itemBuilder: (context, index) {
                  final order = _pedidosOrders[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text('Orden: ${order.orden} - ${order.usuario}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total: \$${order.total.toStringAsFixed(2)}'),
                          Text('Fecha Retiro: ${order.fecha}'),
                          Text('Hora Retiro: ${order.hora}'),
                          Text('Teléfono: ${order.telefono}'),
                          Text('Entregado: ${order.entregado ? "Sí" : "No"}'),
                          const SizedBox(height: 5),
                          const Text('Productos'),
                          for (var prod in order.productos)
                            Text(
                              '- ${prod['producto']} x${prod['cantidad']} (\$${prod['subtotal']})',
                              style: const TextStyle(fontSize: 12),
                            )
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
    );
  }
}
