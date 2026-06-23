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

  // Streams de datos para el controlador
  Stream<QuerySnapshot<Map<String, dynamic>>> obtenerStreamColeccion(String coleccion) {
    return _firestore.collection(coleccion).snapshots();
  }

  // =========================================================================
  // EJEMPLO DE ESCALABILIDAD: ¿Cómo añadir una nueva entidad/clase en el futuro?
  // Si mañana agregas el modelo 'Bitacora', solo vienes aquí y agregas su método:
  //
  // Future<void> guardarBitacora(String id, Map<String, dynamic> data) async {
  //   await _firestore.collection('bitacoras').doc(id).set(data);
  // }
  // =========================================================================
}