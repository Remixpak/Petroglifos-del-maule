import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:software_petroglifos/models/fichaTecnica.dart';
import 'package:uuid/uuid.dart';
import 'package:software_petroglifos/models/archivoMultimedia.dart';
import 'package:software_petroglifos/models/imagen.dart'; 
import 'package:software_petroglifos/models/petroglifo.dart';
import 'package:software_petroglifos/models/sitio.dart';
import 'package:software_petroglifos/controllers/ConexionFirestore.dart';
import 'package:software_petroglifos/models/bitacora.dart';
import 'package:software_petroglifos/models/reporteTecnico.dart';

/*
Este archivo tiene todas las funciones que se requieren para manejar 
cualquier cosa relacionada a los petroglifos, es la comunicacion con
el formulario de registro y los modelos (los que aplican en este contexto sipo)
tambien se conecta con la fachada pa guardar en la base de datos

*/
/*
Las funciones de registro, listado, actualizacion y busqueda hacen practicamente
lo mismo, asi que si no esta comentado buscar la funcion que si lo este para entender 
el funcionamiento y eso es basicamente la misma logica
*/

class ControladorGestionArqueologica {
  final ConexionFirestore _dbServicio = ConexionFirestore();
  final _uuid = const Uuid();

  /*
    esta funcion procesa las imagenes de los petroglifos seleccionados y los transforma
    a cadenas de texto en formato Base64 pa guardar en firestore (ni ahi con pagar 300k)
  */
  Future<Map<String, String>> transformacionDeRonald({
    required List<PlatformFile> fotosVisualizables, 
    required List<Imagen> imagenes
  }) async {
    Map<String, String> resultadoBase64 = {};
    
    for (int i = 0; i < fotosVisualizables.length; i++) {
      String base64String = '';
      
      if (fotosVisualizables[i].bytes != null) {
        base64String = base64Encode(fotosVisualizables[i].bytes!);
      } else if (fotosVisualizables[i].path != null && fotosVisualizables[i].path!.isNotEmpty) {
        final File archivoFisico = File(fotosVisualizables[i].path!);
        List<int> imageBytes = await archivoFisico.readAsBytes();
        base64String = base64Encode(imageBytes);
      }
      
      if (i < imagenes.length) {
        resultadoBase64[imagenes[i].id] = base64String;
      }
    }
    return resultadoBase64;
  }

  //==========================================
  //PETROGLIFOS
  //==========================================
  
  /*
    esta funci0n expone un stream(que es un flujo de datos continuos) con la lista completa de petroglifos.
    Se conecta a la fachada db y mapea cada documento recuperado a instancias
    estructuradas los Petroglifos reconstruyendo tambien sus listas internas 
    de imagenes y archivos multimedia.
  */
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

  /*
    Esta funcion calcula y genera de forma secuencial el siguiente código identificador disponible
    para un petroglifo (utilizando el prefijo geográfico 'MAU-'). Evalua los registros existentes
    para determinar el numero mas alto registrado y previene colisiones en caso de
    eliminaciones intermedias, incluyendo un mecanismo de respaldo basado en marcas de tiempo.
  */
  Future<String> generarSiguienteCodigoPetroglifo() async {
    try {
      final snapshot = await _dbServicio.obtenerColeccion('petroglifos').get();
      
      if (snapshot.docs.isEmpty) {
        return 'MAU-01';
      }

      int maxNumero = 0;

      for (var doc in snapshot.docs) {
        String idActual = doc.id;
        
        if (idActual.startsWith('MAU-')) {
          String parteNumerica = idActual.substring(4); 
          int? numero = int.tryParse(parteNumerica);
          
          if (numero != null && numero > maxNumero) {
            maxNumero = numero;
          }
        }
      }

      int siguienteNumero = maxNumero + 1;
      return 'MAU-${siguienteNumero.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error al generar código secuencial, usando respaldo por defecto: $e');
      return 'MAU-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /*
    esta funcion coordina el registro integral de un nuevo petroglifo en el sistema. Genera de
    forma ordenada el ID correlativo, compone las estructuras multimedia, procesa el algoritmo
    de conversión de imagenes a Base64, e inserta concurrentemente el petroglifo y su Ficha Técnica 
    enlazada mediante claves foraneas, actualizando finalmente las referencias en el sitio arqueologico.
  */
  Future<bool> registrarPetroglifo({
    required String nombre,
    required List<PlatformFile> fotosCandidatas, 
    required int indicePrincipal,
    required List<PlatformFile> archivosExtra,
    required Sitio sitioSeleccionado,
    required String descripcionFicha,
    required MotivoPetroglifo motivoFicha,
    required TecnicaGrabado tecnicaFicha,
    required TipoRoca rocaFicha,
  }) async {
    try {
      String nuevoPetroglifoId = await generarSiguienteCodigoPetroglifo();

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

      Petroglifo nuevoPetroglifo = Petroglifo(
        id: nuevoPetroglifoId, 
        nombre: nombre.trim(),
        imagenes: listaImagenes,
        archivosMultimedia: listaMultimedia,
      );

      nuevoPetroglifo.imagenesBase64 = await transformacionDeRonald(
        fotosVisualizables: fotosCandidatas, 
        imagenes: nuevoPetroglifo.imagenes
      );

      await _dbServicio.guardarPetroglifo(nuevoPetroglifo.id, nuevoPetroglifo.toFirestore());

      FichaTecnica nuevaFicha = FichaTecnica(
        id: 'ficha_$nuevoPetroglifoId',
        codigoPetroglifo: nuevoPetroglifoId, 
        descripcion: descripcionFicha.trim(),
        motivo: motivoFicha,
        tecnicaGrabado: tecnicaFicha,
        tpoRoca: rocaFicha,
      );

      await _dbServicio.obtenerColeccion('fichas_tecnicas')
          .doc(nuevaFicha.id)
          .set(nuevaFicha.toFirestore());

      sitioSeleccionado.AgregarPetroglifo(nuevoPetroglifo.id);
      await _dbServicio.actualizarPetroglifosEnSitio(sitioSeleccionado.id, sitioSeleccionado.petroglifosIds);

      return true;
    } catch (e) {
      print('Error crítico al registrar Petroglifo con Ficha Técnica: $e');
      return false;
    }
  }

  /*
    esta funcion busca y recupera la Ficha Tecnica asociada a un petroglifo específico. 
    Consulta el documento correspondiente en Firestore por su clave y reconstruye 
    la entidad convirtiendo de manera segura los valores primitivos de texto a los Enums fuertemente 
    tipados del lenguaje Dart.
  */
  Future<FichaTecnica?> buscarFicha(String petroglifoId) async {
    try {
      final doc = await _dbServicio.obtenerDocumentoPorId('fichas_tecnicas', 'ficha_$petroglifoId');
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;

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
  
  /*
    esta función realiza una consulta filtrada en la base de datos para obtener un listado de petroglifos 
    cuyo nombre coincida de forma exacta con el nombre que pide. Procesa los documentos resultantes y
    mapea los datos primitivos devueltos a objetos de la clase de dominio Petroglifo.
  */
  Future<List<Petroglifo>> buscarPetroglifosPorNombre(String nombre) async {
    try {
      final snapshot = await _dbServicio.obtenerDocumentosPorFiltro(
        nombreColeccion: 'petroglifos',
        campo: 'nombre',
        operacion: 'isEqualTo',
        valor: nombre.trim(),
      );

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
        final List<ArchivoMultimedia> listaArchivos = arcData.map((arc) {
          return ArchivoMultimedia(
            id: arc['id'] ?? '',
            nombreArchivo: arc['nombreArchivo'] ?? '',
            tipoArchivo: arc['tipoArchivo'] ?? '',
            rutaArchivo: arc['rutaArchivo'] ?? '',
          );
        }).toList();

        return Petroglifo(
          id: data['id'] ?? doc.id,
          nombre: data['nombre'] ?? '',
          imagenes: listaImagenes,
          archivosMultimedia: listaArchivos,
        );
      }).toList();
    } catch (e) {
      print("Error buscando petroglifos: $e");
      return [];
    }
  }
  
  //==========================================
  //SITIOS
  //==========================================
  
 
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
        
        final estadoEnum = EstadoAcceso.values.firstWhere(
          (e) => e.name == data['estadoAcceso'],
          orElse: () => EstadoAcceso.publico, 
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
          petroglifosIds: List<String>.from(data['petroglifosIds'] ?? []), 
        );
      }).toList();
    });
  }

  /*
    esta funcion actualiza la informacion de un sitio existente. 
    Toma el objeto, lo mape y ejecuta 
    una modificación genérica sobre el identificador del documento.
  */
  Future<bool> actualizarSitio({
    required Sitio sitio,
  }) async {
    try {
       await _dbServicio.actualizarDocumentoGenerico(nombreColeccion: 'sitios', id: sitio.id, datosAActualizar: sitio.toFirestore());
       return true;
    } catch (e) {
        print(e);
        return false;
    }
  }

 
  Future<List<Sitio>> buscarSitiosPorCodigoInterno(String codigo) async {
    try {
      final snapshot = await _dbServicio.obtenerDocumentosPorFiltro(
        nombreColeccion: 'sitios',
        campo: 'codigoInterno',
        operacion: 'isEqualTo',
        valor: codigo.trim(),
      );

      return snapshot.docs.map((doc) {
        final data = doc.data();

        final estadoEnum = EstadoAcceso.values.firstWhere(
          (e) => e.name == data['estadoAcceso'],
          orElse: () => EstadoAcceso.publico,
        );

        return Sitio(
          id: data['id'] ?? doc.id,
          nombre: data['nombre'] ?? '',
          codigoInterno: data['codigoInterno'] ?? '',
          comuna: data['comuna'] ?? '',
          descripcion: data['descripcion'] ?? '',
          estadoAcceso: estadoEnum,
          latitud: (data['latitud'] as num?)?.toDouble() ?? 0.0,
          longitud: (data['longitud'] as num?)?.toDouble() ?? 0.0,
          petroglifosIds: List<String>.from(data['petroglifosIds'] ?? []),
        );
      }).toList();
    } catch (e) {
      print('Error al buscar sitio por código interno: $e');
      return [];
    }
  }

  //==========================================
  //BITAORAS
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

  /*
    esta funcion recupera bitacoras cuyo inicio sea previo o igual a una fecha limite provista.
    pa poder despues usar cuando se este generando un reporte
  */
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

  /*
    esta funcion busca una bitacora de terreno mediante su ID unico
    en caso de encontrar el documento, extrae listados de participantes 
    y transforma las cadenas temporales ISO al tipo de dato nativo del sistema.
  */
  Future<Bitacora?> buscarBitacora(String idBitacora) async {
    try {
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
  
  
  Future<bool> actualizarBitacora({
    required Bitacora bitacora,
  }) async {
    try {
      await _dbServicio.actualizarDocumentoGenerico(
        nombreColeccion: 'bitacoras',
        id: bitacora.id,
        datosAActualizar: bitacora.toFirestore(),
      );
      return true;
    } catch (e) {
      print('Error al actualizar bitácora: $e');
      return false;
    }
  }
  
  //========================================
  //REPORTES
  //========================================
  
 
  Future<bool> registrarReporte({
    required String id,
    required DateTime fechaGeneracion,
    required DateTime rangoFecha,
    required List<String> idBitacoras,
  }) async {
    try {
      ReporteTecnico nuevoReporte = ReporteTecnico(
        id: id.trim(),
        fechaGeneracion: fechaGeneracion,
        rangoFecha: rangoFecha,
        idBitacoras: idBitacoras.map((id) => id.trim()).toList(),
      );

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