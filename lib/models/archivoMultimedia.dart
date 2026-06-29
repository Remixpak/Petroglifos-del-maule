class ArchivoMultimedia {
  //revisar atributos ya que no me acuerdo cuales eran
  String _id;
  String _nombreArchivo;
  String _tipoArchivo;
  String _rutaArchivo;//REVISAR ESTO YA QUE NO ME ACUERDO SI ERA NECESARIO
  /*no era necesario pero si lo quito se rompe todo y que lata ir archivo por archivo
  cambiando cosas que en una de esas termina rompiendo mas cosas
  */
  //bool visibilidad en una de esas si se pone

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