import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PedidosOrder {
  final String id;
  final String usuario;
  final String fecha;
  final String hora;
  final String telefono;
  final String orden;
  final double total;
  final bool entregado;
  final List<dynamic> productos;

  PedidosOrder({
    required this.id,
    required this.usuario,
    required this.fecha,
    required this.hora,
    required this.telefono,
    required this.orden,
    required this.total,
    required this.entregado,
    required this.productos,
  });

  factory PedidosOrder.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['fecha retiro'];
    final horaTimeStamp = data['hora retiro'];

    String fechaformateada = '';
    String horaformateada = '';

    if (timestamp is Timestamp) {
      fechaformateada = DateFormat('dd-MM-yyyy').format(timestamp.toDate());
    }

    if (horaTimeStamp is Timestamp) {
    horaformateada = DateFormat('HH:mm').format(horaTimeStamp.toDate());
  } else {
    horaformateada = horaTimeStamp ?? '';
  }

    return PedidosOrder(
      id: id,
      usuario: data['usuario'] ?? '',
      fecha: fechaformateada,
      hora: horaformateada,
      telefono: data['telefono'] ?? '',
      orden: data['orden'] ?? '',
      total: (data['total'] ?? 0).toDouble(),
      entregado: data['entregado'] ?? false,
      productos: data['descripcion'] ?? [],
    );
  }
}
