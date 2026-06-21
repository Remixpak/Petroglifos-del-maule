import 'petroglifo.dart';
class Sitio {

  final String id;
  final String nombre;
  final String codigoInterno;
  final String comuna;
  final String descripcion;
  final String estadoAcceso;//puede ser enum
  final double latitud;
  final double longitud;
  final List<Petroglifo> petroglifos; // Lista de petroglifos asociados al sitio

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

  void guardarSitio() {
    // Lógica para guardar el sitio en la base de datos o almacenamiento local
  }
  void editarSitio(String nuevoNombre, String nuevaDescripcion, String nuevoEstadoAcceso) {
    // Lógica para editar el sitio, actualizando su nombre, descripción y estado de acceso
  }
  void eliminarSitio() {
    // Lógica para eliminar el sitio de la base de datos o almacenamiento local
  }

  void agregarPetroglifo(Petroglifo petroglifo) {
    petroglifos.add(petroglifo);
  }

}

