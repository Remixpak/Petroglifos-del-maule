import 'package:software_petroglifos/models/archivoMultimedia.dart';
class Imagen extends ArchivoMultimedia {
  String _url; 
  bool _isPrincipal;

  String get url => _url;
  bool get isPrincipal => _isPrincipal;

  Imagen({
    required String id,
    required String nombreArchivo,
    required String tipoArchivo,
    required String rutaArchivo,

    required this._url,
    required this._isPrincipal,
  }) : super(
          id: id,
          nombreArchivo: nombreArchivo,
          tipoArchivo: tipoArchivo,
          rutaArchivo: rutaArchivo,
        );


}