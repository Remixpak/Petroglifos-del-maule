import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:software_petroglifos/models/fichaTecnica.dart';
import 'package:uuid/uuid.dart';
import 'package:software_petroglifos/models/archivoMultimedia.dart';
import 'package:software_petroglifos/models/imagen.dart'; 
import 'package:software_petroglifos/models/petroglifo.dart';
import 'package:software_petroglifos/models/sitio.dart';
import 'package:software_petroglifos/controllers/firestoreService.dart';
import 'package:software_petroglifos/models/bitacora.dart';
import 'package:software_petroglifos/models/reporteTecnico.dart';

class ControladorGestionArqueologica {
  final FirestoreService _dbServicio = FirestoreService();
  final _uuid = const Uuid();

  // =========================================================================
  // ALGORITMO: TRANSFORMACIÓN DE RONALD (Implementado en la Capa de Negocio)
  // =========================================================================
  Future<Map<String, String>> transformacionDeRonald({
    required List<PlatformFile> fotosVisualizables, 
    required List<Imagen> imagenes
  }) async {
    Map<String, String> resultadoBase64 = {};
    
    for (int i = 0; i < fotosVisualizables.length; i++) {
      String base64String = '';
      
      // Intentamos leer preferentemente desde memoria (bytes crudos) para evitar bloqueos del SO móvil
      if (fotosVisualizables[i].bytes != null) {
        base64String = base64Encode(fotosVisualizables[i].bytes!);
      } else if (fotosVisualizables[i].path != null && fotosVisualizables[i].path!.isNotEmpty) {
        final File archivoFisico = File(fotosVisualizables[i].path!);
        List<int> imageBytes = await archivoFisico.readAsBytes();
        base64String = base64Encode(imageBytes);
      }
      
      // Vinculamos la cadena generada con el ID correspondiente que tendrá el modelo
      if (i < imagenes.length) {
        resultadoBase64[imagenes[i].id] = base64String;
      }
    }
    return resultadoBase64;
  }

  // ==========================================
  // SECCIÓN 1: GESTIÓN DE PETROGLIFOS
  // ==========================================
  Stream<List<Petroglifo>> listarPetroglifos() {
    return _dbServicio.obtenerStreamColeccion('petroglifos').map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final List<dynamic> imgsData = data['imagenes'] ?? [];
        final List<Imagen> listaImagenes = imgsData.map((img) {
          return Imagen(
            id: img['id'] ?? '',
            nombreArchivo: img['nombreArchivo'] ?? '',
            tipoArchivo: img['tipoArchivo'] ?? '',
            rutaArchivo: img['rutaArchivo'] ?? '',
            url: img['base64Data'] ?? img['url'] ?? '', 
            isPrincipal: img['isPrincipal'] ?? false,
          );
        }).toList();

        final List<dynamic> arcData = data['archivosMultimedia'] ?? [];
        final List<ArchivoMultimedia> listaMultimedia = arcData.map((arc) {
          return ArchivoMultimedia(
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

  Future<String> generarSiguienteCodigoPetroglifo() async {
    try {
      // Obtenemos los documentos directamente del servicio de Firestore
      final snapshot = await _dbServicio.obtenerColeccion('petroglifos').get();
      
      if (snapshot.docs.isEmpty) {
        // Si no hay ningún petroglifo, empezamos con el primero
        return 'MAU-01';
      }

      int maxNumero = 0;

      // Iteramos sobre todos los petroglifos existentes para encontrar de forma segura el número más alto
      // (Esto previene errores si algún documento intermedio fue eliminado)
      for (var doc in snapshot.docs) {
        String idActual = doc.id; // Ejemplo: "MAU-03"
        
        if (idActual.startsWith('MAU-')) {
          // Extraemos la parte numérica después del guion
          String parteNumerica = idActual.substring(4); 
          int? numero = int.tryParse(parteNumerica);
          
          if (numero != null && numero > maxNumero) {
            maxNumero = numero;
          }
        }
      }

      // Incrementamos en 1 el valor máximo encontrado
      int siguienteNumero = maxNumero + 1;

      // Retornamos el código formateado con dos dígitos usando padLeft (ej: 4 -> '04')
      return 'MAU-${siguienteNumero.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error al generar código secuencial, usando respaldo por defecto: $e');
      // Respaldo seguro ante fallos imprevistos de red
      return 'MAU-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<bool> registrarPetroglifo({
    required String nombre,
    required List<PlatformFile> fotosCandidatas, 
    required int indicePrincipal,
    required List<PlatformFile> archivosExtra,
    required Sitio sitioSeleccionado,
    // RECIBIMOS LOS CAMPOS DE LA FICHA TÉCNICA REQUERIDOS DESDE LA INTERFAZ
    required String descripcionFicha,
    required MotivoPetroglifo motivoFicha,
    required TecnicaGrabado tecnicaFicha,
    required TipoRoca rocaFicha,
  }) async {
    try {
      // 1. Solicitamos de forma asíncrona el siguiente código secuencial disponible (Ej: "MAU-05")
      String nuevoPetroglifoId = await generarSiguienteCodigoPetroglifo();

      // 2. Estructuramos las entidades de imágenes con IDs únicos
      List<Imagen> listaImagenes = [];
      for (int i = 0; i < fotosCandidatas.length; i++) {
        final fileCandidate = fotosCandidatas[i];
        String rutaSegura = (fileCandidate.path != null && fileCandidate.path!.isNotEmpty) 
            ? fileCandidate.path! 
            : 'memoria_cache_temporal';

        listaImagenes.add(Imagen(
          id: 'img_${_uuid.v4()}',
          nombreArchivo: fileCandidate.name,
          tipoArchivo: 'image/jpeg',
          rutaArchivo: rutaSegura,
          url: '', 
          isPrincipal: i == indicePrincipal,
        ));
      }

      // 3. Estructuramos los archivos multimedia adicionales
      List<ArchivoMultimedia> listaMultimedia = archivosExtra.map((file) {
        String rutaSeguraMultimedia = (file.path != null && file.path!.isNotEmpty) 
            ? file.path! 
            : 'multimedia_cache_temporal';

        return ArchivoMultimedia(
          id: 'arc_${_uuid.v4()}',
          nombreArchivo: file.name,
          tipoArchivo: file.extension ?? 'desconocido',
          rutaArchivo: rutaSeguraMultimedia,
        );
      }).toList();

      // 4. Instanciamos el objeto de dominio Petroglifo usando el nuevo ID secuencial
      Petroglifo nuevoPetroglifo = Petroglifo(
        id: nuevoPetroglifoId, 
        nombre: nombre.trim(),
        imagenes: listaImagenes,
        archivosMultimedia: listaMultimedia,
      );

      // 5. EJECUCIÓN DEL ALGORITMO: Transformación de Ronald
      nuevoPetroglifo.imagenesBase64 = await transformacionDeRonald(
        fotosVisualizables: fotosCandidatas, 
        imagenes: nuevoPetroglifo.imagenes
      );

      // 6. Transacción Pura 1: Envío del Petroglifo a su respectiva colección
      await _dbServicio.guardarPetroglifo(nuevoPetroglifo.id, nuevoPetroglifo.toFirestore());

      // 7. Transacción Pura 2: Instanciar y Guardar la Ficha Técnica oficial enlazada
      FichaTecnica nuevaFicha = FichaTecnica(
        id: 'ficha_$nuevoPetroglifoId',
        codigoPetroglifo: nuevoPetroglifoId, // <--- Relación de Clave Foránea
        descripcion: descripcionFicha.trim(),
        motivo: motivoFicha,
        tecnicaGrabado: tecnicaFicha,
        tpoRoca: rocaFicha,
      );

      // Guardamos la ficha en una colección dedicada compartiendo la llave del documento
      await _dbServicio.obtenerColeccion('fichas_tecnicas')
          .doc(nuevaFicha.id)
          .set(nuevaFicha.toFirestore());

      // 8. Sincronización en el Sitio Arqueológico correspondiente
      sitioSeleccionado.AgregarPetroglifo(nuevoPetroglifo.id);
      await _dbServicio.actualizarPetroglifosEnSitio(sitioSeleccionado.id, sitioSeleccionado.petroglifosIds);

      return true;
    } catch (e) {
      print('Error crítico al registrar Petroglifo con Ficha Técnica: $e');
      return false;
    }
  }

  Future<FichaTecnica?> buscarFicha(String petroglifoId) async {
    try {
      // Buscamos el documento cuyo ID estructural es 'ficha_MAU-XX'
      
      final doc = await _dbServicio.obtenerDocumentoPorId('fichas_tecnicas', 'ficha_$petroglifoId');
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;

      // Reconvertimos de manera segura los Strings de Firestore a los Enums de Dart
      final motivoEnum = MotivoPetroglifo.values.firstWhere(
        (e) => e.name == data['motivo'],
        orElse: () => MotivoPetroglifo.indeterminado,
      );

      final tecnicaEnum = TecnicaGrabado.values.firstWhere(
        (e) => e.name == data['tecnicaGrabado'],
        orElse: () => TecnicaGrabado.percusion,
      );

      final rocaEnum = TipoRoca.values.firstWhere(
        (e) => e.name == data['tpoRoca'],
        orElse: () => TipoRoca.basalto,
      );

      return FichaTecnica(
        id: data['id'] ?? doc.id,
        codigoPetroglifo: data['codigoPetroglifo'] ?? '',
        descripcion: data['descripcion'] ?? '',
        motivo: motivoEnum,
        tecnicaGrabado: tecnicaEnum,
        tpoRoca: rocaEnum,
      );
    } catch (e) {
      print('Error al buscar la ficha técnica del petroglifo $petroglifoId: $e');
      return null;
    }
  }
  // ==========================================
  // SECCIÓN 2: GESTIÓN DE SITIOS ARQUEOLÓGICOS
  // ==========================================
  Future<bool> registrarSitio({
    required String nombre,
    required String codigoInterno,
    required String comuna,
    required String descripcion,
    required dynamic estadoAcceso, 
    required double latitud,
    required double longitud,
  }) async {
    try {
      String nuevoId = 'sitio_${DateTime.now().millisecondsSinceEpoch}';

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

      await _dbServicio.guardarSitio(nuevoSitio.id, nuevoSitio.toFirestore());
      return true;
    } catch (e) {
      print('Error en Fachada al registrar sitio: $e');
      return false;
    }
  }

  Stream<List<Sitio>> listarSitios() {
    return _dbServicio.obtenerStreamColeccion('sitios').map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // 1. RECONVERSIÓN SEGURA: De String de Firestore a Enum de Dart
        final estadoEnum = EstadoAcceso.values.firstWhere(
          (e) => e.name == data['estadoAcceso'],
          orElse: () => EstadoAcceso.publico, // Valor por defecto si no coincide o es nulo
        );

        // 2. RETORNO CON LOS TIPOS CORRECTOS
        return Sitio(
          id: data['id'] ?? '',
          nombre: data['nombre'] ?? '',
          codigoInterno: data['codigoInterno'] ?? '',
          comuna: data['comuna'] ?? '',
          descripcion: data['descripcion'] ?? '',
          estadoAcceso: estadoEnum, // <--- Ahora sí recibe un 'EstadoAcceso' real
          latitud: (data['latitud'] as num?)?.toDouble() ?? 0.0,
          longitud: (data['longitud'] as num?)?.toDouble() ?? 0.0,
          petroglifosIds: List<String>.from(data['petroglifosIds'] ?? []), 
        );
      }).toList();
    });
  }

  //==========================================
  //SECCION 3: GESTION DE BITACORAS
  //==========================================
  Future<bool> registrarBitacora({
    required String id,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required List<String> idParticipantes,
    required String actividad,
    required String observaciones,
  }) async {
    try {
      Bitacora nuevaBitacora = Bitacora(
        id: id.trim(),
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        idParticipantes: idParticipantes.map((p) => p.trim()).toList(),
        actividad: actividad.trim(),
        observaciones: observaciones.trim(),
      );

      await _dbServicio.guardarBitacora(nuevaBitacora.id, nuevaBitacora.toFirestore());
      return true;
    } catch (e) {
      print('Error al registrar bitácora: $e');
      return false;
    }
  }

  Stream<List<Bitacora>> listarBitacoras() {
    return _dbServicio.obtenerStreamColeccion('bitacoras').map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return Bitacora(
          id: data['id'] ?? '',
          fechaInicio: DateTime.tryParse(data['fechaInicio'] ?? '') ?? DateTime.now(),
          fechaFin: DateTime.tryParse(data['fechaFin'] ?? '') ?? DateTime.now(),
          idParticipantes: List<String>.from(data['idParticipantes'] ?? []),
          actividad: data['actividad'] ?? '',
          observaciones: data['observaciones'] ?? '',
        );
      }).toList();
    });
  }

  // =========================================================================
  // FILTRO: Obtener Bitácoras por Fecha de Inicio (Menor o Igual) de forma directa
  // =========================================================================
  // En el Controlador
Future<List<Bitacora>> obtenerBitacorasPorFecha(DateTime fechaLimite) async {
  try {
    String fechaLimiteIso = fechaLimite.toIso8601String();

    
    final snapshot = await _dbServicio.obtenerDocumentosPorFiltro(
      nombreColeccion: 'bitacoras',
      campo: 'fechaInicio',
      operacion: 'lessThanOrEqualTo',
      valor: fechaLimiteIso,
    );

    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Bitacora(
        id: data['id'] ?? doc.id,
        fechaInicio: DateTime.tryParse(data['fechaInicio'] ?? '') ?? DateTime.now(),
        fechaFin: DateTime.tryParse(data['fechaFin'] ?? '') ?? DateTime.now(),
        idParticipantes: List<String>.from(data['idParticipantes'] ?? []),
        actividad: data['actividad'] ?? '',
        observaciones: data['observaciones'] ?? '',
      );
    }).toList();
  } catch (e) {
    print('Error al filtrar bitácoras por fecha en el controlador: $e');
    return [];
  }
}

  Future<Bitacora?> buscarBitacora(String idBitacora) async {
  try {
    // Buscamos el documento en la colección 'bitacoras'
    final doc = await _dbServicio.obtenerDocumentoPorId('bitacoras', idBitacora);
        

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final data = doc.data()!;

    
    final DateTime fechaInicioEnum = data['fechaInicio'] != null 
        ? DateTime.parse(data['fechaInicio']) 
        : DateTime.now();
        
    final DateTime fechaFinEnum = data['fechaFin'] != null 
        ? DateTime.parse(data['fechaFin']) 
        : DateTime.now();

    // Convertimos la lista de Firestore a una List<String> de manera segura
    final List<String> participantesList = data['idParticipantes'] != null
        ? List<String>.from(data['idParticipantes'])
        : [];

    return Bitacora(
      id: data['id'] ?? doc.id,
      fechaInicio: fechaInicioEnum,
      fechaFin: fechaFinEnum,
      idParticipantes: participantesList,
      actividad: data['actividad'] ?? 'Sin actividad especificada',
      observaciones: data['observaciones'] ?? '',
    );
  } catch (e) {
    print('Error al buscar la bitácora con ID $idBitacora: $e');
    return null;
  }
}
  //========================================
  //SECCION 4: REPOETES
  //========================================
  Future<bool> registrarReporte({
  required String id,
  required DateTime fechaGeneracion,
  required DateTime rangoFecha,
  required List<String> idBitacoras,
}) async {
  try {
    // Creamos la instancia correcta usando tu modelo estructurado
    ReporteTecnico nuevoReporte = ReporteTecnico(
      id: id.trim(),
      fechaGeneracion: fechaGeneracion,
      rangoFecha: rangoFecha,
      idBitacoras: idBitacoras.map((id) => id.trim()).toList(),
    );

    // IMPORTANTE: Asegúrate de que guardarReporte use internamente la colección 'reportes'
    await _dbServicio.guardarReporte(nuevoReporte.id, nuevoReporte.toFirestore());
    return true;
  } catch (e) {
    print('Error al registrar reporte en el controlador: $e');
    return false;
  }
}
  Stream<List<ReporteTecnico>> listarReportes() {
    return _dbServicio.obtenerStreamColeccion('reportes').map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return ReporteTecnico(
          id: data['id'] ?? '',
          fechaGeneracion: DateTime.tryParse(data['fechaGeneracion'] ?? '') ?? DateTime.now(),
          rangoFecha: DateTime.tryParse(data['rangoFecha'] ?? '') ?? DateTime.now(),
          idBitacoras: List<String>.from(data['idBitacoras'] ?? []),
        );
      }).toList();
    });
  }
}