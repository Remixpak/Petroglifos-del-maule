
class Bitacora
{
  String _id;
  DateTime _fechaInicio;
  DateTime _fechaFin;
  List<String> _idParticipantes;
  String _actividad;
  String _observaciones;

  String get id => _id;
  DateTime get fechaInicio => _fechaInicio;
  DateTime get fechaFin => _fechaFin;
  List<String> get idParticipantes => _idParticipantes;
  String get actividad => _actividad;
  String get observaciones => _observaciones;

  Bitacora({
    required this._id,
    required this._fechaInicio,
    required this._fechaFin,
    required this._idParticipantes,
    required this._actividad,
    required this._observaciones,
  });

  Map<String, dynamic> toFirestore()
   {
    return {
      'id': id.toString(),
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'idParticipantes': idParticipantes,
      'actividad': actividad.trim(),
      'observaciones': observaciones.trim(),
    };
  }
  
}