import 'package:flutter/material.dart';

// Definición de Enums para estandarizar el registro arqueológico
enum MotivoPetroglifo { zoomorfo, antropomorfo, geometrico, mixto, indeterminado }
enum TecnicaGrabado { percusion, incision, raspado, mixto }
enum TipoRoca { basalto, granito, andesita, arenisca, otra }

class FichaTecnica {
  final String id;
  final String codigoPetroglifo; // Enlace primario (MAU-XX)
  final String descripcion;
  final MotivoPetroglifo motivo;
  final TecnicaGrabado tecnicaGrabado;
  final TipoRoca tpoRoca;

  FichaTecnica({
    required this.id,
    required this.codigoPetroglifo,
    required this.descripcion,
    required this.motivo,
    required this.tecnicaGrabado,
    required this.tpoRoca,
  });

  // Convierte la entidad a un mapa plano listo para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'codigoPetroglifo': codigoPetroglifo,
      'descripcion': descripcion,
      'motivo': motivo.name,         // Guardamos el string puro del enum (.name)
      'tecnicaGrabado': tecnicaGrabado.name,
      'tpoRoca': tpoRoca.name,
    };
  }
}