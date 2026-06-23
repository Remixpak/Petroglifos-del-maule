import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:software_petroglifos/models/archivoMultimedia.dart';
import 'package:software_petroglifos/models/imagen.dart'; 
import 'package:software_petroglifos/models/petroglifo.dart';
import 'package:software_petroglifos/models/sitio.dart';
import 'package:software_petroglifos/services/firestoreService.dart';

class ControladorGestionArqueologica {
  final FirestoreService _dbServicio = FirestoreService();
  final _uuid = const Uuid();

  // =========================================================================
  // ALGORITMO: TRANSFORMACIÓN DE RONALD (Implementado en la Capa de Negocio)
  // =========================================================================
  Future<Map<String, String>> transformacionDeRonald({
    required List<PlatformFile> fotosVisualizables, 
    required List<imagen> imagenes
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
        final List<imagen> listaImagenes = imgsData.map((img) {
          return imagen(
            id: img['id'] ?? '',
            nombreArchivo: img['nombreArchivo'] ?? '',
            tipoArchivo: img['tipoArchivo'] ?? '',
            rutaArchivo: img['rutaArchivo'] ?? '',
            url: img['base64Data'] ?? img['url'] ?? '', 
            isPrincipal: img['isPrincipal'] ?? false,
          );
        }).toList();

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
  }) async {
    try {
      // CLAVE: Solicitamos de forma asíncrona el siguiente código secuencial disponible
      String nuevoPetroglifoId = await generarSiguienteCodigoPetroglifo();

      // 1. Estructuramos las entidades de imágenes con IDs únicos estables y rutas sanitizadas
      List<imagen> listaImagenes = [];
      for (int i = 0; i < fotosCandidatas.length; i++) {
        final fileCandidate = fotosCandidatas[i];
        
        String rutaSegura = (fileCandidate.path != null && fileCandidate.path!.isNotEmpty) 
            ? fileCandidate.path! 
            : 'memoria_cache_temporal';

        listaImagenes.add(imagen(
          id: 'img_${_uuid.v4()}',
          nombreArchivo: fileCandidate.name,
          tipoArchivo: 'image/jpeg',
          rutaArchivo: rutaSegura,
          url: '', 
          isPrincipal: i == indicePrincipal,
        ));
      }

      // 2. Estructuramos los archivos multimedia adicionales sanitizados
      List<archivoMultimedia> listaMultimedia = archivosExtra.map((file) {
        String rutaSeguraMultimedia = (file.path != null && file.path!.isNotEmpty) 
            ? file.path! 
            : 'multimedia_cache_temporal';

        return archivoMultimedia(
          id: 'arc_${_uuid.v4()}',
          nombreArchivo: file.name,
          tipoArchivo: file.extension ?? 'desconocido',
          rutaArchivo: rutaSeguraMultimedia,
        );
      }).toList();

      // 3. Instanciamos el objeto de dominio Petroglifo usando el nuevo ID secuencial
      Petroglifo nuevoPetroglifo = Petroglifo(
        id: nuevoPetroglifoId, // <--- Ahora es 'MAU-XX'
        nombre: nombre.trim(),
        imagenes: listaImagenes,
        archivosMultimedia: listaMultimedia,
      );

      // 4. EJECUCIÓN DEL ALGORITMO: Transformación de Ronald
      nuevoPetroglifo.imagenesBase64 = await transformacionDeRonald(
        fotosVisualizables: fotosCandidatas, 
        imagenes: nuevoPetroglifo.imagenes
      );

      // 5. Envío puro y seguro al servicio de base de datos usando el ID 'MAU-XX' como la llave del documento
      await _dbServicio.guardarPetroglifo(nuevoPetroglifo.id, nuevoPetroglifo.toFirestore());

      // 6. Sincronización en el Sitio Arqueológico correspondiente
      sitioSeleccionado.AgregarPetroglifo(nuevoPetroglifo.id);
      await _dbServicio.actualizarPetroglifosEnSitio(sitioSeleccionado.id, sitioSeleccionado.petroglifosIds);

      return true;
    } catch (e) {
      print('Error al registrar Petroglifo en la Fachada (Algoritmo Ronald): $e');
      return false;
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
}