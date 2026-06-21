import 'package:software_petroglifos/models/archivoMultimedia.dart';
class imagen extends archivoMultimedia {
  // Atributos específicos para la clase imagen
  String url; // URL de la imagen
  bool isPrincipal; // Indica si esta imagen es la principal del petroglifo
  imagen({
    required String id,
    required String nombreArchivo,
    required String tipoArchivo,
    required String rutaArchivo,

    required this.url, // Requerimos la URL al crear una instancia de imagen
    required this.isPrincipal, // Requerimos el indicador de imagen principal
  }) : super(
          id: id,
          nombreArchivo: nombreArchivo,
          tipoArchivo: tipoArchivo,
          rutaArchivo: rutaArchivo,
        );


}