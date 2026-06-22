import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:software_petroglifos/models/archivoMultimedia.dart';
import 'package:software_petroglifos/models/imagen.dart';

class Petroglifo {
  final String id;
  final String nombre;
  final List<archivoMultimedia> archivosMultimedia;
  final List<imagen> imagenes;

  // Mapa temporal o atributo para almacenar las imágenes en Base64 antes de subirlas
  Map<String, String> imagenesBase64 = {};

  Petroglifo({
    required this.id,
    required this.nombre,
    List<archivoMultimedia>? archivosMultimedia,
    List<imagen>? imagenes,
  })  : archivosMultimedia = archivosMultimedia ?? [],
        imagenes = imagenes ?? [];

  //transformacion de Ronald: Convierte archivos fisicos a cadenas Base64
  Future<void> transformacionDeRonald(List<File> archivosFotos) async {
    for (int i = 0; i < archivosFotos.length; i++) {
      List<int> imageBytes = await archivosFotos[i].readAsBytes();
      String base64String = base64Encode(imageBytes);
      //asignamos la cadena Base64 correspondiente al ID de la imagen del modelo
      if (i < imagenes.length) {
        imagenesBase64[imagenes[i].id] = base64String;
      }
    }
  }

  /// Método de persistencia que interactúa con la base de datos
  Future<void> guardarPetroglifo() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('petroglifos').doc(id).set({
      'id': id,
      'nombre': nombre,
      'imagenes': imagenes.map((img) => {
        'id': img.id,
        'nombreArchivo': img.nombreArchivo,
        'tipoArchivo': img.tipoArchivo,
        'isPrincipal': img.isPrincipal,
        // Almacenamos la imagen transformada en formato Base64 en lugar de una URL remota
        'base64Data': imagenesBase64[img.id] ?? '', 
      }).toList(),
      'archivosMultimedia': archivosMultimedia.map((arc) => {
        'id': arc.id,
        'nombreArchivo': arc.nombreArchivo,
        'tipoArchivo': arc.tipoArchivo,
        'rutaArchivo': arc.rutaArchivo,
      }).toList(),
    });
  }

  void agregarArchivoMultimedia(archivoMultimedia archivo) => archivosMultimedia.add(archivo);
  
  imagen obtenerImagenPrincipal() {
    if (imagenes.isEmpty) throw StateError('No hay imágenes disponibles');
    return imagenes.firstWhere((img) => img.isPrincipal, orElse: () => imagenes.first);
  }
}