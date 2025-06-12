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
            .get();

    final orders =
        snapshot.docs
            .map((doc) => PedidosOrder.fromFirestore(doc.id, doc.data()))
            .toList();

    // Reordenar: primero no entregados (por hora), luego no entregados
    orders.sort((a, b) {
      if (a.entregado == b.entregado) {
        // Comparar por hora si ambos son 'No Entregados'
        if (!a.entregado) {
          final horaA = _parseHora(a.hora);
          final horaB = _parseHora(b.hora);
          return horaA.compareTo(horaB);
        }
        return 0;
      }
      return a.entregado ? 1 : -1;
    });

    setState(() {
      _pedidosOrders = orders;
    });
  }

  TimeOfDay _parseHora(String hora) {
    try {
      final parts = hora.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  Future<void> _marcarEntregado(String id) async {
    await FirebaseFirestore.instance.collection('Vouches').doc(id).update({
      'entregado': true,
    });

    _loadRetiroOrders(); //Recargar para actualizar la lista
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
                          Text('Fecha Retiro: ${order.fecha}',style: const TextStyle( fontSize: 14),),
                          Text('Hora Retiro: ${order.hora}',style: const TextStyle( fontSize: 14),),
                          Text('Teléfono: ${order.telefono}',style: const TextStyle( fontSize: 14),),
                          Text('Entregado: ${order.entregado ? "Sí" : "No"}',style: const TextStyle( fontSize: 14),),
                          const SizedBox(height: 5),
                          const Text('Productos',style: const TextStyle( fontSize: 14),),
                          for (var prod in order.productos)
                            Text(
                              '- ${prod['producto']} x${prod['cantidad']} (\$${prod['subtotal']})',
                              style: const TextStyle( fontSize: 14),
                            ),
                          if (!order.entregado)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _marcarEntregado(order.id), 
                                icon:  const Icon(Icons.check),
                                label: const Text('Marcar como Entregado')),
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
