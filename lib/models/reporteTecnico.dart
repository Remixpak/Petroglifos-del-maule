class ReporteTecnico
{
  String _id;
  DateTime _fechaGeneracion;
  DateTime _rangoFecha;
  List<String> _idBitacoras;

  String get id => _id;
  DateTime get fechaGeneracion => _fechaGeneracion;
  DateTime get rangoFecha => _rangoFecha;
  List<String> get idBitacoras => _idBitacoras;
  ReporteTecnico({
    required this._id,
    required this._fechaGeneracion,
    required this._rangoFecha,
    required this._idBitacoras,
  });


  Map<String, dynamic> toFirestore()
   {
    return {
      'id': id.toString(),
      'fechaGeneracion': fechaGeneracion.toIso8601String(),
      'rangoFecha': rangoFecha.toIso8601String(),
      'idBitacoras': idBitacoras,
    };
  }
}