class archivoMultimedia {
  //revisar atributos ya que no me acuerdo cuales eran
  String id;
  String nombreArchivo;
  String tipoArchivo;
  String rutaArchivo;
 // Nuevo atributo para marcar si es la imagen principal

  archivoMultimedia({
    required this.id,
    required this.nombreArchivo,
    required this.tipoArchivo,
    required this.rutaArchivo,
 // Por defecto no es la imagen principal
  });


}