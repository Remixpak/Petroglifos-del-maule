import 'package:flutter/material.dart';

class Bitacora
{
  String id;
  DateTime fechaInicio;
  DateTime fechaFin;
  List<String> idParticipantes;
  String actividad;
  String observaciones;

  Bitacora({
    required this.id,

    required this.fechaInicio,
    required this.fechaFin,
    required this.idParticipantes,
    required this.actividad,
    required this.observaciones,
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