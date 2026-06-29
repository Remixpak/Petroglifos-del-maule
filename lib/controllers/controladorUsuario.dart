import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:software_petroglifos/models/usuario.dart';
import 'package:software_petroglifos/controllers/ConexionFirestore.dart';

/*
  este archivo centraliza la logica para la gestión de usuarios, el control
  de acceso Actua como puente entre el formulario y el servicio de
  Firebase Authentication y los registros adicionales del perfil en Firestore.
  el registro listado y actulizacion funciona practicamente igual a lo que esta 
  en el controlador de gestion arqueologica asi que no voy a comentarlo
*/

class ControladorUsuario {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConexionFirestore _dbServicio = ConexionFirestore();

  Future<bool> registrarUsuario({
    required String nombre,
    required String correo,
    required String clave,
    required Rol rol,
    required String institucion,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: clave.trim(),
      );

      String uid = userCredential.user!.uid;
      Usuario nuevoUsuario = Usuario(
        id: uid,
        nombre: nombre.trim(),
        correo: correo.trim(),
        clave: clave.trim(),
        rol: rol,
        institucion: institucion.trim(),
        isActive: true, 
      );

      await _dbServicio.guardarUsuario(nuevoUsuario.id, nuevoUsuario.toFirestore());
      print('Usuario registrado con éxito en Auth y Firestore UID: $uid');
      return true;
    } catch (e) {
      print('Error en el registro: $e');
      return false;
    }
  }

  Stream<List<Usuario>> listarUsuarios() {
    return _dbServicio.obtenerStreamColeccion('usuarios').map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        Rol rolUsuario = Rol.values.firstWhere(
          (r) => r.name == data['rol'],
          orElse: () => Rol.investigador, 
        );

        return Usuario(
          id: data['id'] ?? doc.id,
          nombre: data['nombre'] ?? 'Sin Nombre',
          correo: data['correo'] ?? '',
          clave: '', 
          isActive: data['isActive'] ?? true,
          rol: rolUsuario,
          institucion: data['institucion'] ?? '',
        );
      }).toList();
    });
  }

  Future<Usuario?> buscarUsuario(String idParticipante) async {
    try {
      final doc = await _dbServicio.obtenerDocumentoPorId('usuarios', idParticipante);

      if (!doc.exists || doc.data() == null) {
        return null; 
      }

      final data = doc.data()!;

      return Usuario(
        id: data['id'] ?? doc.id,
        nombre: data['nombre'] ?? 'Sin Nombre',
        correo: data['correo'] ?? '',
        clave: '', 
        isActive: data['isActive'] ?? true,
        rol: Rol.values.firstWhere(
          (r) => r.name == data['rol'],
          orElse: () => Rol.investigador, 
        ),
        institucion: data['institucion'] ?? '',
      );
    } catch (e) {
      print('Error al buscar el participante con ID $idParticipante: $e');
      return null;
    }
  }

  /*
    esta funcion procesa la validacion de identidad e inicio de sesion en la plataforma. 
    Delega las credenciales de correo electrónico y contraseña ingresadas al motor de Firebase 
    Authentication para su correspondiente verificacion en el servidor y retorna un 
    indicador booleano que confirma el éxito de la operacion.
  */
  Future<bool> iniciarSesion({required String email, required String password}) async {
    try {
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

  /*
   chao chao
  */
  Future<bool> cerrarSesion() async {
    try {
      await _auth.signOut();
      print('Sesión cerrada con éxito de Firebase Auth.');
      return true;
    } catch (e) {
      print('Error al intentar cerrar sesión: $e');
      return false;
    }
  }

  /*
    esta funcion modifica de forma directa el estado de habilitacion de una cuenta de usuario. 
    Recibe el id y el nuevo indicador booleano de disponibilidad, mapeando la 
    operacion hacia el metodo de actualizacion generico para impactar la coleccion en la base de datos.
  */
  Future<void> cambiarEstadoCuenta(String idUsuario, bool nuevoEstado) async {
    try {
      await _dbServicio.actualizarDocumentoGenerico(
        nombreColeccion: 'usuarios',
        id: idUsuario,
        datosAActualizar: {'isActive': nuevoEstado},
      );
      print('Estado de la cuenta del usuario $idUsuario actualizado a $nuevoEstado');
    } catch (e) {
      print('Error al cambiar el estado de la cuenta del usuario $idUsuario: $e');
    }
  }
  
  
  Future<bool> actualizarUsuario({
    required Usuario usuario,
  }) async {
    try {
      await _dbServicio.actualizarDocumentoGenerico(
        nombreColeccion: 'usuarios', 
        id: usuario.id, 
        datosAActualizar: usuario.toFirestore()
      );
      return true;
    } catch (e) {
      print('error al actualizar usuario: $e');
      return false;
    }
  }
}