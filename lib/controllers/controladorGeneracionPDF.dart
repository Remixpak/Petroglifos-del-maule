import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:software_petroglifos/controllers/ConexionFirestore.dart';

/*
    este archivo es el que se encarga de gestionar todo lo que tenga 
    que ver la generacion y descarga de pdfs, la idea es que cuando se 
    busque generar algun archivo se cree una instancia de este controlador
    para llamar a las funciones que contiene
  */

class ControladorGeneracionPDF {
  final ConexionFirestore _firestoreService = ConexionFirestore();

  
  /*este archivo es el que se encarga de gestionar todo lo que tenga 
    que ver la generacion y descarga de pdfs, la idea es que cuando se 
    busque generar algun archivo se cree una instancia de este controlador
    para llamar a las funciones que contiene
  */
 
  
/*
esta funcion basicamente genera un pdf con la ficha tecnica de un petroglifo
se conecta con la fachada de la base de datos para obtener la ficha y el petroglifo
crea el pdf como si se tratara de un widget
y retorna un Unit8list que es basicamente una lista de enteros del 0 al 255 que se usa pa 
manejar datos binarios y asi trabajar con las imagenes del petroglifo entre otras cosas de forma
mas eficiente
*/
Future<Uint8List> generarFichaTecnica(String idFicha) async {
  final pdf = pw.Document();
  print(idFicha);
 
  final fuenteNormal = await PdfGoogleFonts.robotoRegular();
  final fuenteNegrita = await PdfGoogleFonts.robotoBold();

  
  final docFicha = await _firestoreService.obtenerDocumentoPorId('fichas_tecnicas', idFicha);
  if (!docFicha.exists) throw Exception('Ficha técnica no encontrada');
  
  final datosFicha = docFicha.data()!;
  
  final docPetro = await _firestoreService.obtenerDocumentoPorId('petroglifos', datosFicha['codigoPetroglifo']);
  Map<String, dynamic>? datosPetro = docPetro.exists ? docPetro.data() : null;

  
  final estiloTitulo = pw.TextStyle(font: fuenteNegrita, fontSize: 22, color: PdfColors.indigo);
  final estiloSubtitulo = pw.TextStyle(font: fuenteNegrita, fontSize: 14);
  final estiloTexto = pw.TextStyle(font: fuenteNormal, fontSize: 12);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
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

  /*
  Ficha.misma logica
  */
  Future<Uint8List> generarReporteTecnico(String idReporte) async {
  final pdf = pw.Document();

  
  final fuenteNormal = await PdfGoogleFonts.robotoRegular();
  final fuenteNegrita = await PdfGoogleFonts.robotoBold();

  
  final estiloTitulo = pw.TextStyle(font: fuenteNegrita, fontSize: 22, color: PdfColors.brown);
  final estiloSubtitulo = pw.TextStyle(font: fuenteNegrita, fontSize: 14);
  final estiloTextoBold = pw.TextStyle(font: fuenteNegrita, fontSize: 12);
  final estiloTextoNormal = pw.TextStyle(font: fuenteNormal, fontSize: 12);
  final estiloParticipantes = pw.TextStyle(font: fuenteNormal, fontSize: 12, color: PdfColors.indigo700);

    final docReporte = await _firestoreService.obtenerDocumentoPorId('reportes', idReporte);
  if (!docReporte.exists) throw Exception('Reporte técnico no encontrado');
  final datosReporte = docReporte.data()!;

  List<String> idBitacoras = List<String>.from(datosReporte['idBitacoras'] ?? []);
  List<pw.Widget> widgetsBitacoras = [];

    for (String idBitacora in idBitacoras) {
    final docBitacora = await _firestoreService.obtenerDocumentoPorId('bitacoras', idBitacora);
    if (docBitacora.exists) {
      final datosBitacora = docBitacora.data()!;
      List<String> idParticipantes = List<String>.from(datosBitacora['idParticipantes'] ?? []);
      List<String> nombresParticipantes = [];

     
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

   pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      
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

  
 /*
 esta funcion descarga el pdf, recibe la cadena con la data y un nombre sugerido 
 el sharePdf lo que hace es que te manda a esta clasica pantalla de previsualizacion
 del documento, como cuando se te abre el chrome pa descargar el docuemnto y eso nomas
 */
  Future<void> descargarPDF(Future<Uint8List> dataPdfFuture, String nombreSugeridoArchivo) async {
    final Uint8List bytes = await dataPdfFuture;

    await Printing.sharePdf(
      bytes: bytes, 
      filename: '$nombreSugeridoArchivo.pdf'
    );
  }
}