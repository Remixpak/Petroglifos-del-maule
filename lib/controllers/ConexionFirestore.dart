import 'package:cloud_firestore/cloud_firestore.dart';

class ConexionFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Persistencia para Sitios
  Future<void> guardarSitio(String id, Map<String, dynamic> data) async {
    await _firestore.collection('sitios').doc(id).set(data);
  }

  Future<void> actualizarPetroglifosEnSitio(String id, List<String> petroglifosIds) async {
    await _firestore.collection('sitios').doc(id).update({
      'petroglifosIds': petroglifosIds,
    });
  }

  CollectionReference<Map<String, dynamic>> obtenerColeccion(String nombreColeccion) {
    return _firestore.collection(nombreColeccion);
  }

  // Persistencia para Petroglifos
  Future<void> guardarPetroglifo(String id, Map<String, dynamic> data) async {
    await _firestore.collection('petroglifos').doc(id).set(data);
  }

  Future<void> guardarBitacora(String id, Map<String, dynamic> data) async {
    await _firestore.collection('bitacoras').doc(id).set(data);
  }
  
  Future<void> guardarReporte(String id, Map<String, dynamic> data) async {
    await _firestore.collection('reportes').doc(id).set(data);
  }

  Future<void> guardarUsuario(String id, Map<String, dynamic> data) async {
    await _firestore.collection('usuarios').doc(id).set(data);
  }

  Future<void> guardarSugerencia(String id, Map<String, dynamic> data) async {
    await _firestore.collection('sugerencias').doc(id).set(data);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> obtenerDocumentosPorFiltro({
    required String nombreColeccion,
    required String campo,
    required String operacion,
    required dynamic valor,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(nombreColeccion);

    if (operacion == 'lessThanOrEqualTo') {
      query = query.where(campo, isLessThanOrEqualTo: valor);
    } else if (operacion == 'isEqualTo') {
      query = query.where(campo, isEqualTo: valor);
    }

    return await query.get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> obtenerDocumentoPorId(
      String nombreColeccion, String docId) async {
    return await _firestore.collection(nombreColeccion).doc(docId).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> obtenerStreamColeccion(String coleccion) {
    return _firestore.collection(coleccion).snapshots();
  }

  // ====================================================================
  // NUEVO MÉTODO GENÉRICO DE ACTUALIZACIÓN
  // ====================================================================
  /// Actualiza campos específicos de cualquier documento en cualquier colección.
  /// 
  /// [nombreColeccion] es el nodo en Firestore (ej: 'usuarios', 'petroglifos').
  /// [id] es el identificador único del documento.
  /// [datosAActualizar] contiene los pares clave-valor que se van a modificar.
  Future<void> actualizarDocumentoGenerico({
    required String nombreColeccion,
    required String id,
    required Map<String, dynamic> datosAActualizar,
  }) async {
    try {
      await _firestore
          .collection(nombreColeccion)
          .doc(id)
          .update(datosAActualizar);
    } catch (e) {
      print("Error genérico al actualizar en la colección $nombreColeccion: $e");
      rethrow; // Lanza el error para que el controlador pueda manejarlo (ej: mostrar un diálogo)
    }
  }
}