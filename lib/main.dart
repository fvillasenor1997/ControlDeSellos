// lib/main.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// Importamos el paquete 'pdf' con un prefijo 'pw' para evitar conflictos.
// Usaremos este para CREAR el nuevo documento y sus widgets.
import 'package:pdf/widgets.dart' as pw;

// Importamos el paquete 'printing' con un prefijo 'printing'.
// Usaremos este para LEER el documento existente y para la PREVISUALIZACIÓN.
import 'package:printing/printing.dart';

import 'pdf_preview_screen.dart'; // Este archivo no necesita cambios.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agregar Pie de Página a PDF',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const PdfProcessingScreen(),
    );
  }
}

class PdfProcessingScreen extends StatefulWidget {
  const PdfProcessingScreen({super.key});

  @override
  _PdfProcessingScreenState createState() => _PdfProcessingScreenState();
}

class _PdfProcessingScreenState extends State<PdfProcessingScreen> {
  bool _isLoading = false;

  Future<void> _processAndPreviewPdf() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se seleccionó ningún archivo o no se pudo leer.')),
          );
        }
        return;
      }

      final Uint8List pdfBytes = result.files.single.bytes!;

      // 1. Usamos la clase Document del paquete 'pdf' (con prefijo pw) para CREAR el nuevo PDF.
      final pw.Document newPdf = pw.Document();

      // 2. Usamos la clase PdfDocument del paquete 'printing' para LEER el PDF existente.
      final printing.PdfDocument existingPdf = await printing.Printing.rasterize(pdfBytes);

      // 3. Iteramos sobre cada página del PDF original.
      await for (var page in existingPdf.pages) {
        // Obtenemos la imagen de la página.
        final pw.Image pageImage = pw.Image(page.image);

        // Agregamos una nueva página al documento que estamos creando.
        newPdf.addPage(
          pw.Page(
            pageFormat: page.pageFormat,
            build: (pw.Context context) {
              // Usamos un Stack para poner el pie de página sobre la página original.
              return pw.Stack(
                children: [
                  // La página original como una imagen de fondo.
                  pageImage,
                  // Nuestro pie de página posicionado en la parte inferior.
                  pw.Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _buildFooter(),
                  ),
                ],
              );
            },
          ),
        );
      }

      // 4. Guardamos el nuevo PDF en memoria.
      final Uint8List newPdfBytes = await newPdf.save();

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                PdfPreviewScreen(pdfBytes: newPdfBytes),
          ),
        );
      }
    } catch (e, s) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error al procesar el PDF: $e');
        debugPrint('Stack trace: $s');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el PDF: $e')),
        );
      }
    }
  }

  // Widget auxiliar para crear la tabla del pie de página.
  pw.Widget _buildFooter() {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(color: const PdfColor.fromInt(0xff000000), width: 0.5),
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xfff2f2f2)),
      cellStyle: const pw.TextStyle(fontSize: 9),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      // Definimos el contenido de la tabla
      headers: ['DEPARTAMENTOS', '', '', ''], // Encabezado que abarca todas las columnas
      data: [
        ['METALURGIA', 'ALMACEN', 'CALIDAD', 'PRODUCCION'],
        ['SELLO', 'SELLO', 'SELLO', 'SELLO'],
        ['FIRMA', 'FIRMA', 'FIRMA', 'FIRMA'],
      ],
      // Personalización para que el encabezado "DEPARTAMENTOS" ocupe 4 columnas
      headerCellBuilder: (context, index) {
        if (index == 0) {
          return pw.Container(
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('DEPARTAMENTOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          );
        }
        return pw.Container(); // Celdas vacías para las otras columnas del encabezado
      },
      // Añadimos altura a las filas de SELLO y FIRMA
      cellBuilder: (context, index, data) {
        final height = (context.row == 2 || context.row == 3) ? 25.0 : 15.0;
        return pw.Container(
          height: height,
          alignment: pw.Alignment.center,
          child: pw.Text(data),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Pie de Página a PDF'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Procesando PDF..."),
                ],
              ),
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Presiona el botón para seleccionar un PDF, previsualizarlo con el pie de página y guardarlo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _processAndPreviewPdf,
        tooltip: 'Seleccionar PDF',
        child: const Icon(Icons.picture_as_pdf),
      ),
    );
  }
}
