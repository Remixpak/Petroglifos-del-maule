import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:software_petroglifos/controllers/firestoreService.dart';
import 'package:software_petroglifos/models/fichaTecnica.dart';
import 'package:software_petroglifos/models/petroglifo.dart';
import 'package:software_petroglifos/models/reporteTecnico.dart';
import 'package:software_petroglifos/models/bitacora.dart';
import 'package:software_petroglifos/models/usuario.dart';

class ControladorGeneracionPDF {
  final FirestoreService _firestoreService = FirestoreService();

  // ====================================================================
  // GENERAR FICHA TÉCNICA (Con Petroglifo e Imágenes Transformadas)
  // ====================================================================
  

Future<Uint8List> generarFichaTecnica(String idFicha) async {
  final pdf = pw.Document();
  print(idFicha);
  
  // 1. Cargar una fuente que soporte Unicode de forma nativa (Roboto por ejemplo)
  // Nota: Usa 'PdfGoogleFonts' del paquete 'printing' para descargarla al vuelo de forma limpia
  final fuenteNormal = await PdfGoogleFonts.robotoRegular();
  final fuenteNegrita = await PdfGoogleFonts.robotoBold();

  // 2. Recuperar Ficha Técnica desde Firestore
  final docFicha = await _firestoreService.obtenerDocumentoPorId('fichas_tecnicas', idFicha);
  if (!docFicha.exists) throw Exception('Ficha técnica no encontrada');
  
  final datosFicha = docFicha.data()!;
  
  final docPetro = await _firestoreService.obtenerDocumentoPorId('petroglifos', datosFicha['codigoPetroglifo']);
  Map<String, dynamic>? datosPetro = docPetro.exists ? docPetro.data() : null;

  // Aplicamos las fuentes Unicode cargadas a los estilos
  final estiloTitulo = pw.TextStyle(font: fuenteNegrita, fontSize: 22, color: PdfColors.indigo);
  final estiloSubtitulo = pw.TextStyle(font: fuenteNegrita, fontSize: 14);
  final estiloTexto = pw.TextStyle(font: fuenteNormal, fontSize: 12);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      // Aplicamos el tema global a la página para que todo texto hijo use Roboto por defecto
      theme: pw.ThemeData.withFont(base: fuenteNormal, bold: fuenteNegrita),
      build: (pw.Context context) {
        List<pw.Widget> widgetsImagenes = [];
        if (datosPetro != null && datosPetro['imagenes'] != null) {
          for (var img in datosPetro['imagenes']) {
            String base64Data = img['base64Data'] ?? '';
            if (base64Data.isNotEmpty) {
              try {
                final bytes = base64Decode(base64Data);
                widgetsImagenes.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    height: 200,
                    child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
                  ),
                );
              } catch (_) {}
            }
          }
        }

        return [
          pw.Header(level: 0, child: pw.Text("FICHA TÉCNICA DE REGISTRO ARQUEOLÓGICO", style: estiloTitulo)),
          pw.SizedBox(height: 15),
          
          pw.Text("Información de la Ficha", style: estiloSubtitulo),
          pw.Divider(),
          pw.Text("ID Registro: ${datosFicha['id']}", style: estiloTexto),
          pw.Text("Código Petroglifo: ${datosFicha['codigoPetroglifo']}", style: estiloTexto),
          pw.Text("Motivo Arqueológico: ${datosFicha['motivo']}", style: estiloTexto),
          pw.Text("Técnica de Grabado: ${datosFicha['tecnicaGrabado']}", style: estiloTexto),
          pw.Text("Tipo de Roca: ${datosFicha['tpoRoca']}", style: estiloTexto),
          pw.Text("Descripción: ${datosFicha['descripcion']}", style: estiloTexto),
          
          pw.SizedBox(height: 25),
          pw.Text("Información del Petroglifo Asociado", style: estiloSubtitulo),
          pw.Divider(),
          pw.Text("Nombre del Yacimiento / Bloque: ${datosPetro != null ? datosPetro['nombre'] : 'No asociado'}", style: estiloTexto),
          
          pw.SizedBox(height: 20),
          if (widgetsImagenes.isNotEmpty) ...[
            pw.Text("Registro Visual (Transformación de Ronald)", style: estiloSubtitulo),
            pw.Divider(),
            pw.SizedBox(height: 10),
            ...widgetsImagenes,
          ]
        ];
      },
    ),
  );

  return pdf.save();
}

  // ====================================================================
  // GENERAR REPORTE TÉCNICO (Con Bitácoras y Nombres de Participantes)
  // ====================================================================
  Future<Uint8List> generarReporteTecnico(String idReporte) async {
  final pdf = pw.Document();

  // 1. Cargar fuentes que soportan Unicode de forma nativa
  final fuenteNormal = await PdfGoogleFonts.robotoRegular();
  final fuenteNegrita = await PdfGoogleFonts.robotoBold();

  // Estilos tipográficos explícitos usando las fuentes cargadas
  final estiloTitulo = pw.TextStyle(font: fuenteNegrita, fontSize: 22, color: PdfColors.brown);
  final estiloSubtitulo = pw.TextStyle(font: fuenteNegrita, fontSize: 14);
  final estiloTextoBold = pw.TextStyle(font: fuenteNegrita, fontSize: 12);
  final estiloTextoNormal = pw.TextStyle(font: fuenteNormal, fontSize: 12);
  final estiloParticipantes = pw.TextStyle(font: fuenteNormal, fontSize: 12, color: PdfColors.indigo700);

  // 2. Recuperar Reporte
  final docReporte = await _firestoreService.obtenerDocumentoPorId('reportes', idReporte);
  if (!docReporte.exists) throw Exception('Reporte técnico no encontrado');
  final datosReporte = docReporte.data()!;

  List<String> idBitacoras = List<String>.from(datosReporte['idBitacoras'] ?? []);
  List<pw.Widget> widgetsBitacoras = [];

  // 3. Iterar sobre las bitácoras asociadas al reporte
  for (String idBitacora in idBitacoras) {
    final docBitacora = await _firestoreService.obtenerDocumentoPorId('bitacoras', idBitacora);
    if (docBitacora.exists) {
      final datosBitacora = docBitacora.data()!;
      List<String> idParticipantes = List<String>.from(datosBitacora['idParticipantes'] ?? []);
      List<String> nombresParticipantes = [];

      // Buscar solo el nombre de cada participante en la colección usuarios
      for (String idPart in idParticipantes) {
        final docUser = await _firestoreService.obtenerDocumentoPorId('usuarios', idPart);
        if (docUser.exists) {
          nombresParticipantes.add(docUser.data()!['nombre'] ?? 'Desconocido');
        }
      }

      widgetsBitacoras.add(
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Bitácora ID: ${datosBitacora['id']}", style: estiloTextoBold),
              pw.Text("Rango: ${datosBitacora['fechaInicio']} al ${datosBitacora['fechaFin']}", style: estiloTextoNormal),
              pw.Text("Actividad Desarrollada: ${datosBitacora['actividad']}", style: estiloTextoNormal),
              pw.Text("Observaciones Técnicas: ${datosBitacora['observaciones']}", style: estiloTextoNormal),
              pw.Text("Participantes en Terreno: ${nombresParticipantes.join(', ')}", style: estiloParticipantes),
            ],
          ),
        ),
      );
    }
  }

  // 4. Construcción del documento usando el tema de fuentes global
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      // Aplicamos el tema para heredar las fuentes por defecto en toda la estructura interna
      theme: pw.ThemeData.withFont(base: fuenteNormal, bold: fuenteNegrita),
      build: (pw.Context context) {
        return [
          pw.Header(level: 0, child: pw.Text("REPORTE TÉCNICO DE GESTIÓN ARQUEOLÓGICA", style: estiloTitulo)),
          pw.SizedBox(height: 10),
          pw.Text("Fecha de Generación: ${datosReporte['fechaGeneracion']}", style: estiloTextoNormal),
          pw.Text("Filtro de Rango Temporal del Reporte: ${datosReporte['rangoFecha']}", style: estiloTextoNormal),
          pw.SizedBox(height: 20),
          pw.Text("Bitácoras de Terreno Consolidadas:", style: estiloSubtitulo),
          pw.Divider(),
          ...widgetsBitacoras,
        ];
      },
    ),
  );

  return pdf.save();
}

  // ====================================================================
  // DESCARGAR Y GUARDAR EL ARCHIVO (Android & Windows)
  // ====================================================================
  /// Utiliza la API compartida de 'printing' que genera el flujo de guardado de archivos
  /// nativo de Windows (File Explorer) y la cola de descargas/impresión de Android.
  Future<void> descargarPDF(Future<Uint8List> dataPdfFuture, String nombreSugeridoArchivo) async {
    final Uint8List bytes = await dataPdfFuture;

    await Printing.sharePdf(
      bytes: bytes, 
      filename: '$nombreSugeridoArchivo.pdf'
    );
  }
}