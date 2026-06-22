import 'package:cloud_firestore/cloud_firestore.dart';
import 'petroglifo.dart';

enum EstadoAcceso { publico, privado }

class Sitio {
  final String id;
  final String nombre;
  final String codigoInterno;
  final String comuna;
  final String descripcion;
  final EstadoAcceso estadoAcceso;
  final double latitud;
  final double longitud;
  final List<Petroglifo> petroglifos;

  Sitio({
    required this.id,
    required this.nombre,
    required this.codigoInterno,
    required this.comuna,
    required this.descripcion,
    required this.estadoAcceso,
    required this.latitud,
    required this.longitud,
    List<Petroglifo>? petroglifos,
  }) : petroglifos = petroglifos ?? [];

  //metodo de persistencia interno delegando a Firebase Cloud Firestore
  Future<void> guardarSitio() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    await firestore.collection('sitios').doc(id).set({
      'id': id,
      'nombre': nombre,
      'codigoInterno': codigoInterno,
      'comuna': comuna,
      'descripcion': descripcion,
      'estadoAcceso': estadoAcceso.name,
      'latitud': latitud,
      'longitud': longitud,
      
      'petroglifosIds': petroglifos.map((p) => p.id).toList(),
    });
  }

  void editarSitio(String nuevoNombre, String nuevaDescripcion, String nuevoEstadoAcceso) {}
  void eliminarSitio() {}
  void AgregarPetroglifo(Petroglifo petroglifo) {
    petroglifos.add(petroglifo);
  }
  Future<void> actualizarPetroglifosAsociados() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('sitios').doc(id).update({
      'petroglifosIds': petroglifos.map((p) => p.id).toList(),
    });
  }

  // Dentro de tu clase Sitio en sitio.dart:

@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is Sitio && runtimeType == other.runtimeType && id == other.id;

@override
int get hashCode => id.hashCode;
}

