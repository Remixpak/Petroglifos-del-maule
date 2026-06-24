class ReporteTecnico
{
  String id;
  DateTime fechaGeneracion;
  DateTime rangoFecha;
  List<String> idBitacoras;
  ReporteTecnico({
    required this.id,
    required this.fechaGeneracion,
    required this.rangoFecha,
    required this.idBitacoras,
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