import 'package:app_cafeteria/app_colors/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistorialPedidos extends StatefulWidget {
  const HistorialPedidos({super.key});

  @override
  State<HistorialPedidos> createState() => _HistorialPedidosState();
}

class _HistorialPedidosState extends State<HistorialPedidos> {
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPedidos();
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

    final snapshot =
        await FirebaseFirestore.instance
            .collection('Vouches')
            .where('usuarioId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

    final pedidos =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'orden': data['orden'] ?? '',
            'tipo': data['tipo'] ?? '',
            'total': (data['total'] ?? 0).toDouble(),
            'fecha':
                data['timestamp'] != null
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Historial de Pedidos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pedidos.isEmpty
              ? const Center(child: Text('No tienes pedidos registrados'))
              : ListView.builder(
                  itemCount: _pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = _pedidos[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(
                          'Orden: ${pedido['orden']} - ${pedido['tipo']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total: \$${pedido['total'].toStringAsFixed(2)}'),
                            if (pedido['fecha'] != null)
                              Text('Fecha: ${pedido['fecha']}'),
                            Text('Entregado: ${pedido['entregado'] ? "Sí" : "No"}'),
                            const SizedBox(height: 5),
                            const Text('Productos:'),
                            for (var prod in pedido['productos'])
                              Text(
                                '- ${prod['producto']} x${prod['cantidad']} (\$${prod['subtotal']})',
                                style: const TextStyle(fontSize: 12),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
