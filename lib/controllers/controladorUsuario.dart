import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:software_petroglifos/models/usuario.dart';
import 'package:software_petroglifos/controllers/firestoreService.dart';
/*
CAMBIAR NOMBRE A CONTROLADORUSUARIO
*/



class ControladorUsuario {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _dbServicio = FirestoreService();

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
      Usuario nuevoUsuario = Usuario(
        id: uid,
        nombre: nombre.trim(),
        correo: correo.trim(),
        clave: clave.trim(),
        rol: rol,
        institucion: institucion.trim(),
        estado: true, 
      );

      
     await _dbServicio.guardarUsuario(nuevoUsuario.id, nuevoUsuario.toFirestore());
        

      print('Usuario registrado con éxito en Auth y Firestore UID: $uid');
      return true;
    } catch (e) {
      print('Error en el registro: $e');
      return false;
    }
  }

  /// Lista los usuarios desde Firestore en tiempo real como un Stream de objetos [Usuario]
  Stream<List<Usuario>> listarUsuarios() {
    return _dbServicio.obtenerStreamColeccion('usuarios').map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Mapeo seguro del Rol (String a Enum)
        Rol rolUsuario = Rol.values.firstWhere(
          (r) => r.name == data['rol'],
          orElse: () => Rol.investigador, // Corregido a tu capitalización exacta
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

  Future<Usuario?> buscarUsuario(String idParticipante) async {
  try {
    
    final doc = await _dbServicio.obtenerDocumentoPorId('usuarios', idParticipante);

    // Si el documento no existe o viene vacío, retornamos el ID como fallback
    if (!doc.exists || doc.data() == null) {
      return null; 
    }

    final data = doc.data()!;

    // 2. PROCESAMOS EL RESULTADO: Extraemos el campo 'nombre' de forma segura
    return Usuario(
      id: data['id'] ?? doc.id,
      nombre: data['nombre'] ?? 'Sin Nombre',
      correo: data['correo'] ?? '',
      clave: '', // <--- AQUÍ: Pasamos string vacío ya que la clave no se guarda en Firestore
      estado: data['estado'] ?? true,
      rol: Rol.values.firstWhere(
        (r) => r.name == data['rol'],
        orElse: () => Rol.investigador, // Corregido a tu capitalización exacta
      ),
      institucion: data['institucion'] ?? '',
    );

    } catch (e) {
      print('Error al buscar el participante con ID $idParticipante: $e');
      return null;
    }
  }

  Future<bool> iniciarSesion({required String email, required String password}) async {
  try {
    // Firebase se encarga de validar la contraseña cifrada internamente en sus servidores
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
   
    return userCredential.user != null;
  } catch (e) {
    print('Error de login en ControladorUsuario: $e');
    return false;
  }
}
}