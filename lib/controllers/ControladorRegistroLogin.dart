import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:software_petroglifos/models/usuario.dart'; // Ajusta la ruta a tu modelo

class Controladorregistrologin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Transladar este metodo luego a la clase usuario
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
      await _firestore.collection('usuarios').doc(uid).set({
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
  




}