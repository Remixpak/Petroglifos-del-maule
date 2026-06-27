
class Sugerencia{
  final String idSugerencia;
  final String descripcion;
  final DateTime fecha;
  final bool estado;//aprobada o no
  Sugerencia({
    required this.idSugerencia,
    required this.descripcion,
    required this.fecha,
    required this.estado
  });

  Map<String,dynamic> toFirestore()
  {
    return{
      'id': idSugerencia, 
      'descripcion': descripcion,
      'fecha': fecha,
      'estado': estado,
    };
  }

}