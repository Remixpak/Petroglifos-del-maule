import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
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
    // Registra el documento en la colección 'bitacoras' usando el ID provisto
    await _firestore.collection('bitacoras').doc(id).set(data);
  }
  Future<void> guardarReporte(String id, Map<String, dynamic> data) async {
    // Registra el documento en la colección 'reportes' usando el ID provisto
    await _firestore.collection('reportes').doc(id).set(data);
  }

  Future<void> guardarUsuario(String id, Map<String, dynamic> data) async {
    await _firestore.collection('usuarios').doc(id).set(data);
  }

  // En FirestoreService
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
  // Streams de datos para el controlador
  Stream<QuerySnapshot<Map<String, dynamic>>> obtenerStreamColeccion(String coleccion) {
    return _firestore.collection(coleccion).snapshots();
  }
}