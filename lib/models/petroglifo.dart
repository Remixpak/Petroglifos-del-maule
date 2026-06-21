import 'package:flutter/material.dart';
import 'package:software_petroglifos/models/fichaTecnica.dart';
import 'package:software_petroglifos/models/archivoMultimedia.dart';
import 'package:software_petroglifos/models/imagen.dart';
class Petroglifo {
  final String id;
  final String nombre;
  //final FichaTecnica fichaTecnica;
/*al momento de registrar el petroglifo se rellena tambien la ficha tecnica, asi que se guarda
primero la ficha y se le asigna al petroglifo
*/
  final List<archivoMultimedia> archivosMultimedia; // Lista de archivos multimedia asociados al petroglifo
  final List<imagen> imagenes; // Lista de imágenes asociadas al petroglifo
  Petroglifo({
    required this.id,
    required this.nombre,
    //required this.fichaTecnica,
    List<archivoMultimedia>? archivosMultimedia,
    List<imagen>? imagenes,
  })  : archivosMultimedia = archivosMultimedia ?? [],
       imagenes = imagenes ?? [];

  void agregarArchivoMultimedia(archivoMultimedia archivo) {
    archivosMultimedia.add(archivo);
  }
  void eliminarArchivoMultimedia(String idArchivo) {
    archivosMultimedia.removeWhere((archivo) => archivo.id == idArchivo);
  }
  void guardarPetroglifo() {
    // Lógica para guardar el petroglifo en la base de datos o almacenamiento local
  }
  void editarPetroglifo(String nuevoNombre, FichaTecnica nuevaFichaTecnica) {
    // Lógica para editar el petroglifo, actualizando su nombre y ficha técnica
  }
  void eliminarPetroglifo() {
    // Lógica para eliminar el petroglifo de la base de datos o almacenamiento local
  }
  imagen ObtenerImagenPrincipal() {
    // Lógica para obtener la imagen principal del petroglifo, por ejemplo, el primer archivo multimedia de tipo imagen
    if (imagenes.isEmpty) {
      throw StateError('No hay imágenes disponibles');
    }
    // Buscamos el archivo marcado como principal, si no existe, tomamos el primero
    return imagenes.firstWhere(
      (imagen) => imagen.isPrincipal,
      orElse: () => imagenes.first,
    );
  }
}