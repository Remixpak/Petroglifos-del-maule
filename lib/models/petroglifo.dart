import 'package:software_petroglifos/models/archivoMultimedia.dart';
import 'package:software_petroglifos/models/imagen.dart';

class Petroglifo {
  // Variables privadas
  final String _id;
  final String _nombre;
  final List<ArchivoMultimedia> _archivosMultimedia; 
  final List<Imagen> _imagenes;                      
  
 
  Map<String, String> _imagenesBase64 = {};

  
  String get id => _id;
  String get nombre => _nombre;
  List<ArchivoMultimedia> get archivosMultimedia => _archivosMultimedia;
  List<Imagen> get imagenes => _imagenes;
  Map<String, String> get imagenesBase64 => _imagenesBase64;

  
  set imagenesBase64(Map<String, String> nuevoMapeo) {
    _imagenesBase64 = nuevoMapeo;
  }

  
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
          'base64Data': (_imagenesBase64[img.id] ?? '').toString(), 
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

  
  Imagen obtenerImagenPrincipal() {
    if (imagenes.isEmpty) throw StateError('No hay imágenes disponibles');
    return imagenes.firstWhere((img) => img.isPrincipal, orElse: () => imagenes.first);
  }
}