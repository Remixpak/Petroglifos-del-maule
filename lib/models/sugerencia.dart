
class Sugerencia{
  final String _idSugerencia;
  final String _descripcion;
  final DateTime _fecha;
  final bool _estado;//aprobada o no
  Sugerencia({
    required this._idSugerencia,
    required this._descripcion,
    required this._fecha,
    required this._estado
  });

  String get idSugerencia => _idSugerencia;
  String get descripcion => _descripcion;
  DateTime get fecha => _fecha;
  bool get estado => _estado;

  Map<String,dynamic> toFirestore()
  {
    return{
      'id': _idSugerencia, 
      'descripcion': _descripcion,
      'fecha': _fecha,
      'estado': _estado,
    };
  }

}