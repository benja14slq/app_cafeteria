import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/screen_tienda/delivery_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StoreDeliveryPage extends StatefulWidget {
  const StoreDeliveryPage({super.key});

  @override
  State<StoreDeliveryPage> createState() => _StoreDeliveryPageState();
}

class _StoreDeliveryPageState extends State<StoreDeliveryPage> {
  List<DeliveryOrder> _deliveryOrders = [];

  @override
  void initState() {
    super.initState();
    _loadDeliveryOrders();
  }

  Future<void> _loadDeliveryOrders() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('Vouches')
            .where('tipo', isEqualTo: 'Delivery')
            .orderBy('timestamp', descending: true)
            .get();

    final orders =
        snapshot.docs
            .map((doc) => DeliveryOrder.fromFirestore(doc.id, doc.data()))
            .toList();

    setState(() {
      _deliveryOrders = orders;
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
          _deliveryOrders.isEmpty
              ? const Center(child: Text('No hay pedidos registrados'))
              : ListView.builder(
                itemCount: _deliveryOrders.length,
                itemBuilder: (context, index) {
                  final order = _deliveryOrders[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text('Orden: ${order.orden} - ${order.usuario}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total: \$${order.total.toStringAsFixed(2)}'),
                          Text('Dirección: ${order.direccion}'),
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
