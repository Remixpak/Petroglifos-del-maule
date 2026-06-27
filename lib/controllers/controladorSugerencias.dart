import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:software_petroglifos/controllers/firestoreService.dart';
import 'package:software_petroglifos/models/sugerencia.dart'; 

class Controladorsugerencias {
  final FirestoreService _dbServicio = FirestoreService();

  /// Registra una nueva sugerencia o reporte de mejora en la colección de Firestore
  Future<bool> registrarSugerencia({
    required String id,
    required String descripcion,
    required DateTime fecha,
    required bool estado,
  }) async {
    try {
      
      Sugerencia nuevaSugerencia = Sugerencia(idSugerencia: id, descripcion: descripcion, fecha: fecha, estado: estado);

      await _dbServicio.guardarSugerencia(nuevaSugerencia.idSugerencia, nuevaSugerencia.toFirestore());

      print('Sugerencia $id registrada de manera exitosa.');
      return true;
    } catch (e) {
      print('Error al registrar la sugerencia: $e');
      return false;
    }
  }


  Stream<List<Map<String, dynamic>>> listarSugerencias() {
    return _dbServicio.obtenerStreamColeccion('sugerencias').map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Procesamos la fecha de forma segura tolerando nulos o Timestamps nativos
        DateTime fechaConvertida = DateTime.now();
        if (data['fecha'] != null) {
          fechaConvertida = (data['fecha'] as Timestamp).toDate();
        }

        return {
          'id': data['id'] ?? doc.id,
          'descripcion': data['descripcion'] ?? 'Sin descripción',
          'fecha': fechaConvertida,
          'estado': data['estado'] ?? false,
        };
      }).toList();
    });
  }

  /// Método reservado para implementaciones futuras
  Future<void> editarSugerencia(String id, String descripcion, DateTime fecha, bool estado) async {
    // Se omitirá temporalmente según requerimiento
  }
}