import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:software_petroglifos/models/usuario.dart';

/*
CAMBIAR NOMBRE A CONTROLADORUSUARIO
*/



class ControladorUsuario {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _dbServicio = FirebaseFirestore.instance;

  // Trasladar este método luego a la clase usuario
  Future<bool> registrarUsuario({
    required String nombre,
    required String correo,
    required String clave,
    required Rol rol,
    required String institucion,
  }) async {
    try {
      // 1. Crear el usuario en Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: clave.trim(),
      );

      // Obtener el ID único generado por Firebase Auth
      String uid = userCredential.user!.uid;

      // 2. Guardar los datos complementarios del perfil en Cloud Firestore
      await _dbServicio.collection('usuarios').doc(uid).set({
        'id': uid,
        'nombre': nombre.trim(),
        'correo': correo.trim(),
        'estado': true, // Por defecto activo
        'rol': rol.name, // Guardamos el enum como String ('Administrador' o 'Investigador')
        'institucion': institucion.trim(),
      });

      print('Usuario registrado con éxito en Auth y Firestore UID: $uid');
      return true;
    } catch (e) {
      print('Error en el registro: $e');
      return false;
    }
  }

  /// Lista los usuarios desde Firestore en tiempo real como un Stream de objetos [Usuario]
  Stream<List<Usuario>> listarUsuarios() {
    return _dbServicio.collection('usuarios').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Mapeo seguro del Rol (String a Enum)
        Rol rolUsuario = Rol.values.firstWhere(
          (r) => r.name == data['rol'],
          orElse: () => Rol.Investigador, // Corregido a tu capitalización exacta
        );

        return Usuario(
          id: data['id'] ?? doc.id,
          nombre: data['nombre'] ?? 'Sin Nombre',
          correo: data['correo'] ?? '',
          clave: '', // <--- AQUÍ: Pasamos string vacío ya que la clave no se guarda en Firestore
          estado: data['estado'] ?? true,
          rol: rolUsuario,
          institucion: data['institucion'] ?? '',
        );
      }).toList();
    });
  }

  Future<String> buscarUsuario(String idParticipante) async {
  try {
    // Buscamos el documento directamente en la colección 'usuarios' usando su ID
    final doc = await _dbServicio
        .collection('usuarios')
        .doc(idParticipante)
        .get();

    // Si el documento no existe o viene vacío, retornamos el ID como fallback
    if (!doc.exists || doc.data() == null) {
      return idParticipante; 
    }

    final data = doc.data()!;

    // Extraemos el nombre de manera segura mapeando con un string por defecto si es nulo
    return data['nombre'] ?? 'Sin nombre';

  } catch (e) {
    print('Error al buscar el participante con ID $idParticipante: $e');
    // En caso de excepción, devolvemos el ID original para no romper el flujo visual
    return idParticipante;
  }
}
}