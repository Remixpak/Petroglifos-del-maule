class ArchivoMultimedia {
  //revisar atributos ya que no me acuerdo cuales eran
  String _id;
  String _nombreArchivo;
  String _tipoArchivo;
  String _rutaArchivo;//REVISAR ESTO YA QUE NO ME ACUERDO SI ERA NECESARIO
  //bool visibilidad en bola si se pone

  String get id => _id;
  String get nombreArchivo => _nombreArchivo;
  String get tipoArchivo => _tipoArchivo;
  String get rutaArchivo => _tipoArchivo;
  ArchivoMultimedia({
    required this._id,
    required this._nombreArchivo,
    required this._tipoArchivo,
    required this._rutaArchivo,

  });


}