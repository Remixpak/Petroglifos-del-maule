import 'package:software_petroglifos/models/archivoMultimedia.dart';
import 'package:software_petroglifos/models/imagen.dart';

class Petroglifo {
  final String id;
  final String nombre;
  final List<archivoMultimedia> archivosMultimedia;
  final List<imagen> imagenes;

  // Mapa que almacena el resultado procesado por la Transformación de Ronald
  Map<String, String> imagenesBase64 = {};

  Petroglifo({
    required this.id,
    required this.nombre,
    List<archivoMultimedia>? archivosMultimedia,
    List<imagen>? imagenes,
  })  : archivosMultimedia = archivosMultimedia ?? [],
        imagenes = imagenes ?? [];

  Map<String, dynamic> toFirestore() {
    return {
      'id': id.toString(),
      'nombre': nombre.toString(),
      'imagenes': imagenes.map((img) {
        return {
          'id': img.id.toString(),
          'nombreArchivo': img.nombreArchivo.toString(),
          'tipoArchivo': img.tipoArchivo.toString(),
          'isPrincipal': img.isPrincipal == true,
          'base64Data': (imagenesBase64[img.id] ?? '').toString(), // Extrae el Base64 usando el ID mapeado por Ronald
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

  imagen obtenerImagenPrincipal() {
    if (imagenes.isEmpty) throw StateError('No hay imágenes disponibles');
    return imagenes.firstWhere((img) => img.isPrincipal, orElse: () => imagenes.first);
  }
}