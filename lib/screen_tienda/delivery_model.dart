import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryOrder {
  final String id;
  final String usuario;
  final String direccion;
  final String referencia;
  final String telefono;
  final String orden;
  final double total;
  final bool entregado;
  final List<dynamic> productos;
  final Timestamp? timestamp;

  DeliveryOrder({
    required this.id,
    required this.usuario,
    required this.direccion,
    required this.referencia,
    required this.telefono,
    required this.orden,
    required this.total,
    required this.entregado,
    required this.productos,
    required this.timestamp,
  });

  factory DeliveryOrder.fromFirestore(String id, Map<String, dynamic> data) {    
    return DeliveryOrder(
      id: id,
      usuario: data['usuario'] ?? '',
      direccion: data['direccion'] ?? '',
      referencia: data['referencia'] ?? '',
      telefono: data['telefono'] ?? '',
      orden: data['orden'] ?? '',
      total: (data['total'] ?? 0).toDouble(),
      entregado: data['entregado'] ?? false,
      productos: data['descripcion'] ?? [],
      timestamp: data['timestamp'],
    );
  }
}