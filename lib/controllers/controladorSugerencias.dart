import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:software_petroglifos/controllers/ConexionFirestore.dart';
import 'package:software_petroglifos/models/sugerencia.dart'; 

/*
controlador.mismaLogica()
*/

class Controladorsugerencias {
  final ConexionFirestore _dbServicio = ConexionFirestore();

  
  Future<bool> registrarSugerencia({
    required String id,
    required String descripcion,
    required DateTime fecha,
    required bool estado,
  }) async {
    try {
      Sugerencia nuevaSugerencia = Sugerencia(
        idSugerencia: id, 
        descripcion: descripcion, 
        fecha: fecha, 
        estado: estado
      );

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
}