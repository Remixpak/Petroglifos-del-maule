import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:software_petroglifos/models/archivoMultimedia.dart';
import 'package:software_petroglifos/models/imagen.dart'; // Asegúrate de que coincida con 'imagen' o 'Imagen'
import 'package:software_petroglifos/models/petroglifo.dart';
import 'package:software_petroglifos/models/sitio.dart';
// import 'package:software_petroglifos/models/bitacora.dart'; // Descomenta cuando crees el modelo Bitacora

class ControladorGestionArqueologica {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // SECCIÓN 1: GESTIÓN DE PETROGLIFOS
  // ==========================================

  /// Obtiene un flujo (Stream) en tiempo real de los petroglifos guardados en Firestore
  Stream<List<Petroglifo>> listarPetroglifos() {
    return _firestore.collection('petroglifos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Mapeamos la lista de mapas que guardamos de 'imagenes' de vuelta al modelo 'imagen'
        final List<dynamic> imgsData = data['imagenes'] ?? [];
        final List<imagen> listaImagenes = imgsData.map((img) {
          return imagen(
            id: img['id'] ?? '',
            nombreArchivo: img['nombreArchivo'] ?? '',
            tipoArchivo: img['tipoArchivo'] ?? '',
            rutaArchivo: img['rutaArchivo'] ?? '',
            // Nota: Al usar la transformación de Ronald, la data se guarda en 'base64Data'
            url: img['base64Data'] ?? img['url'] ?? '', 
            isPrincipal: img['isPrincipal'] ?? false,
          );
        }).toList();

        // Mapeamos la lista de archivos multimedia adicionales
        final List<dynamic> arcData = data['archivosMultimedia'] ?? [];
        final List<archivoMultimedia> listaMultimedia = arcData.map((arc) {
          return archivoMultimedia(
            id: arc['id'] ?? '',
            nombreArchivo: arc['nombreArchivo'] ?? '',
            tipoArchivo: arc['tipoArchivo'] ?? '',
            rutaArchivo: arc['rutaArchivo'] ?? '',
          );
        }).toList();

        return Petroglifo(
          id: data['id'] ?? doc.id,
          nombre: data['nombre'] ?? 'Sin Nombre',
          imagenes: listaImagenes,
          archivosMultimedia: listaMultimedia,
        );
      }).toList();
    });
  }
  Future<bool> registrarPetroglifo({
    required String nombre,
    required List<File> fotosFisicas,
    required int indicePrincipal,
    required List<PlatformFile> archivosExtra,
    required Sitio sitioSeleccionado,
  }) async {
    try {
      String nuevoPetroglifoId = _firestore.collection('petroglifos').doc().id;

      // 1. Mapeamos las fotos capturadas al modelo 'imagen'
      List<imagen> listaImagenes = [];
      for (int i = 0; i < fotosFisicas.length; i++) {
        String idImg = _firestore.collection('placeholder').doc().id;
        listaImagenes.add(imagen(
          id: idImg,
          nombreArchivo: fotosFisicas[i].path.split('/').last,
          tipoArchivo: 'image/jpeg',
          rutaArchivo: fotosFisicas[i].path,
          url: '', // No se usa URL porque guardaremos en Base64
          isPrincipal: i == indicePrincipal,
        ));
      }

      // 2. Mapeamos los archivos multimedia extras
      List<archivoMultimedia> listaMultimedia = archivosExtra.map((file) {
        return archivoMultimedia(
          id: _firestore.collection('placeholder').doc().id,
          nombreArchivo: file.name,
          tipoArchivo: file.extension ?? 'desconocido',
          rutaArchivo: file.path ?? '',
        );
      }).toList();

      // 3. Instanciamos el Petroglifo
      Petroglifo nuevoPetroglifo = Petroglifo(
        id: nuevoPetroglifoId,
        nombre: nombre.trim(),
        imagenes: listaImagenes,
        archivosMultimedia: listaMultimedia,
      );

      // 4. Transformación de Ronald (Conversión a Base64)
      await nuevoPetroglifo.transformacionDeRonald(fotosFisicas);

      // 5. Guardado del Petroglifo mediante su propio método interno
      await nuevoPetroglifo.guardarPetroglifo();

      // 6. Asociar al Sitio seleccionado en memoria y persistirlo en la BD
sitioSeleccionado.AgregarPetroglifo(nuevoPetroglifo.id); // <--- CAMBIADO: .id añadido
await sitioSeleccionado.actualizarPetroglifosAsociados();

      return true;
    } catch (e) {
      print('Error al registrar Petroglifo en el controlador: $e');
      return false;
    }
  }

  Future<bool> guardarPetroglifo(Petroglifo petroglifo) async {
    try {
      // Lógica futura para persistir Petroglifos en Firestore
      print('Guardando petroglifo: ${petroglifo.nombre}');
      return true;
    } catch (e) {
      print('Error al guardar petroglifo: $e');
      return false;
    }
  }

  // ==========================================
  // SECCIÓN 2: GESTIÓN DE SITIOS ARQUEOLÓGICOS
  // ==========================================

  /// Procesa los datos de la interfaz, instancia el modelo Sitio y llama a su propio método guardar
  Future<bool> registrarSitio({
    required String nombre,
    required String codigoInterno,
    required String comuna,
    required String descripcion,
    required EstadoAcceso estadoAcceso,
    required double latitud,
    required double longitud,
  }) async {
    try {
      // Generamos un ID alfanumérico único directamente desde Firestore
      String nuevoId = _firestore.collection('sitios').doc().id;

      // Instanciamos el objeto del modelo Sitio
      Sitio nuevoSitio = Sitio(
        id: nuevoId,
        nombre: nombre.trim(),
        codigoInterno: codigoInterno.trim(),
        comuna: comuna.trim(),
        descripcion: descripcion.trim(),
        estadoAcceso: estadoAcceso,
        latitud: latitud,
        longitud: longitud,
      );

      //guardar en la BD es el de la clase Sitio
      await nuevoSitio.guardarSitio();
      
      print('Sitio registrado exitosamente a través del modelo con ID: $nuevoId');
      return true;
    } catch (e) {
      print('Error en ControladorGestionArqueologica al registrar sitio: $e');
      return false;
    }
  }



  /// Obtiene un flujo (Stream) en tiempo real de los sitios guardados en Firestore
  Stream<List<Sitio>> listarSitios() {
    return _firestore.collection('sitios').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Mapeamos el String que viene de la BD de vuelta al Enum de Dart
        final estadoEnum = EstadoAcceso.values.firstWhere(
          (e) => e.name == data['estadoAcceso'],
          orElse: () => EstadoAcceso.publico, // Valor por defecto en caso de datos inconsistentes
        );

        return Sitio(
  id: data['id'] ?? '',
  nombre: data['nombre'] ?? '',
  codigoInterno: data['codigoInterno'] ?? '',
  comuna: data['comuna'] ?? '',
  descripcion: data['descripcion'] ?? '',
  estadoAcceso: estadoEnum,
  latitud: (data['latitud'] as num?)?.toDouble() ?? 0.0,
  longitud: (data['longitud'] as num?)?.toDouble() ?? 0.0,
  // CAMBIADO: Usamos el nuevo parámetro y transformamos de forma segura la data de Firebase a una Lista de Strings
  petroglifosIds: List<String>.from(data['petroglifosIds'] ?? []), 
);
      }).toList();
    });
  }
 
}