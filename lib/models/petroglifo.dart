import 'package:software_petroglifos/models/archivoMultimedia.dart';
import 'package:software_petroglifos/models/imagen.dart';

class Petroglifo {
  // Variables privadas
  final String _id;
  final String _nombre;
  final List<ArchivoMultimedia> _archivosMultimedia; // Se asume UpperCamelCase en el modelo
  final List<Imagen> _imagenes;                      // Se asume UpperCamelCase en el modelo
  
  // Mapa privado que almacena el resultado procesado por la Transformación de Ronald
  Map<String, String> _imagenesBase64 = {};

  // Getters Públicos
  String get id => _id;
  String get nombre => _nombre;
  List<ArchivoMultimedia> get archivosMultimedia => _archivosMultimedia;
  List<Imagen> get imagenes => _imagenes;
  Map<String, String> get imagenesBase64 => _imagenesBase64;

  // Setter opcional por si necesitas reasignar las imágenes procesadas por Ronald desde fuera
  set imagenesBase64(Map<String, String> nuevoMapeo) {
    _imagenesBase64 = nuevoMapeo;
  }

  // Constructor corregido apuntando a las variables privadas en la lista de inicialización
  Petroglifo({
    required String id,
    required String nombre,
    List<ArchivoMultimedia>? archivosMultimedia,
    List<Imagen>? imagenes,
  })  : _id = id,
        _nombre = nombre,
        _archivosMultimedia = archivosMultimedia ?? [],
        _imagenes = imagenes ?? [];

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nombre': nombre,
      'imagenes': imagenes.map((img) {
        return {
          'id': img.id.toString(),
          'nombreArchivo': img.nombreArchivo.toString(),
          'tipoArchivo': img.tipoArchivo.toString(),
          'isPrincipal': img.isPrincipal == true,
          'base64Data': (_imagenesBase64[img.id] ?? '').toString(), // Usa la variable privada interna directamente
          'rutaArchivo': img.rutaArchivo.toString(),
        };
      }).toList(),
      'archivosMultimedia': archivosMultimedia.map((arc) {
        return {
          'id': arc.id.toString(),
          'nombreArchivo': arc.nombreArchivo.toString(),
          'tipoArchivo': arc.tipoArchivo.toString(),
          'rutaArchivo': arc.rutaArchivo.toString(), 
        };
      }).toList(),
    };
  }

  // Implementación del método para eliminar un archivo multimedia por su ID
  void eliminarArchivoMultimedia(String idArchivo) {
    _archivosMultimedia.removeWhere((arc) => arc.id == idArchivo);
  }

  // Implementación complementaria para eliminar una imagen y su rastro en base64 si es necesario
  void eliminarImagen(String idImagen) {
    _imagenes.removeWhere((img) => img.id == idImagen);
    _imagenesBase64.remove(idImagen);
  }

  Imagen obtenerImagenPrincipal() {
    if (imagenes.isEmpty) throw StateError('No hay imágenes disponibles');
    return imagenes.firstWhere((img) => img.isPrincipal, orElse: () => imagenes.first);
  }
}