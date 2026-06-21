import 'package:flutter/material.dart';
class FichaTecnica {
  final String id;
  final String codigoPetroglifo;
  final String descripcion;
  //revisar estas ya que pueden ser enums
  final String motivo;
  final String tecnicaGrabado;

  FichaTecnica({
    required this.id,
    required this.codigoPetroglifo,
    required this.descripcion,
    required this.motivo,
    required this.tecnicaGrabado,
  });
}