import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:app_cafeteria/screen_tienda/delivery_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
            .get();

    final orders =
        snapshot.docs
            .map((doc) => DeliveryOrder.fromFirestore(doc.id, doc.data()))
            .toList();

    orders.sort((a, b) {
      // Primero los no entregados
      if (a.entregado != b.entregado) {
        return a.entregado ? 1 : -1;
      }

      final aTime = a.timestamp ?? Timestamp.now();
      final bTime = b.timestamp ?? Timestamp.now();
      // Si es 'No entregado' -> ordenar por fecha ascendente
      // Si es 'Entregado' -> Ordenar por fecha descendente
      return a.entregado ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
    });

    setState(() {
      _deliveryOrders = orders;
    });
  }

  Future<void> _marcarComoEntregado(String id) async {
    await FirebaseFirestore.instance.collection('Vouches').doc(id).update({
      'entregado': true,
    });
    _loadDeliveryOrders(); // Recargar lista
  }

  String _formatearFechaHora(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy - HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                          Text('Total: \$${order.total.toStringAsFixed(2)}',style: const TextStyle( fontSize: 14),),
                          Text('Dirección: ${order.direccion}',style: const TextStyle( fontSize: 14),),
                          Text('Teléfono: ${order.telefono}',style: const TextStyle( fontSize: 14),),
                          if (order.timestamp != null)
                            Text(
                              'Compra: ${_formatearFechaHora(order.timestamp!)}',style: const TextStyle( fontSize: 14),
                            ),
                          Text('Entregado: ${order.entregado ? "Sí" : "No"}',style: const TextStyle( fontSize: 14),),
                          const SizedBox(height: 5),
                          const Text('Productos',style: const TextStyle( fontSize: 14),),
                          for (var prod in order.productos)
                            Text(
                              '- ${prod['producto']} x${prod['cantidad']} (\$${prod['subtotal']})',
                              style: const TextStyle(fontSize: 14),
                            ),
                          if (!order.entregado)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _marcarComoEntregado(order.id),
                                icon: const Icon(Icons.check),
                                label: const Text('Marcar como entregado'),
                              ),
                            ),
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
