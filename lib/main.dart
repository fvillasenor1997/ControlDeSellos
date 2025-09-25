// lib/main.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// Importamos el paquete 'pdf' para acceder a clases como PdfColors.
import 'package:pdf/pdf.dart';
// Importamos los widgets del paquete 'pdf' con un prefijo 'pw' para crear el documento.
import 'package:pdf/widgets.dart' as pw;

// Importamos el paquete 'printing' para leer el PDF existente y para la vista previa.
import 'package:printing/printing.dart';

import 'pdf_preview_screen.dart';

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
      final pw.Document newPdf = pw.Document();
      final PdfDocument existingPdf = await PdfDocument.openData(pdfBytes);

      for (int i = 0; i < existingPdf.pageCount; i++) {
        final page = await existingPdf.getPage(i + 1);
        final pageImage = pw.Image(page.image);

        newPdf.addPage(
          pw.Page(
            pageFormat: page.pageFormat,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  pw.Center(child: pageImage),
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

  // --- WIDGET DE PIE DE PÁGINA CORREGIDO ---
  pw.Widget _buildFooter() {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      children: [
        // Fila 1: Encabezado principal que abarca 4 columnas
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: pw.Text('DEPARTAMENTOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            // Se crean celdas vacías que serán "ignoradas" por el span de la primera.
            pw.Container(),
            pw.Container(),
            pw.Container(),
          ],
        ),
        // Fila 2: Sub-encabezados
        pw.TableRow(
          children: [
            pw.Container(padding: const pw.EdgeInsets.all(2), alignment: pw.Alignment.center, child: pw.Text('METALURGIA', style: const pw.TextStyle(fontSize: 9))),
            pw.Container(padding: const pw.EdgeInsets.all(2), alignment: pw.Alignment.center, child: pw.Text('ALMACEN', style: const pw.TextStyle(fontSize: 9))),
            pw.Container(padding: const pw.EdgeInsets.all(2), alignment: pw.Alignment.center, child: pw.Text('CALIDAD', style: const pw.TextStyle(fontSize: 9))),
            pw.Container(padding: const pw.EdgeInsets.all(2), alignment: pw.Alignment.center, child: pw.Text('PRODUCCION', style: const pw.TextStyle(fontSize: 9))),
          ],
        ),
        // Fila 3: Sello
        pw.TableRow(
          children: List.generate(4, (index) => 
            pw.Container(
              height: 25,
              padding: const pw.EdgeInsets.all(2),
              alignment: pw.Alignment.center,
              child: pw.Text('SELLO', style: const pw.TextStyle(fontSize: 9))
            )
          ),
        ),
        // Fila 4: Firma
        pw.TableRow(
          children: List.generate(4, (index) => 
            pw.Container(
              height: 15,
              padding: const pw.EdgeInsets.all(2),
              alignment: pw.Alignment.center,
              child: pw.Text('FIRMA', style: const pw.TextStyle(fontSize: 9))
            )
          ),
        ),
      ],
      // Definimos que la primera celda de la primera fila ocupe 4 columnas
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
      },
      // Especificamos que la primera celda en la fila 0 debe abarcar 4 columnas.
      cellDecorations: {
        const pw.TableCellIndex(0, 0): const pw.BoxDecoration(
          color: PdfColors.grey200,
          border: pw.TableBorder(
            bottom: pw.BorderSide(width: 0.5),
            right: pw.BorderSide(width: 0.5),
            left: pw.BorderSide(width: 0.5),
            top: pw.BorderSide(width: 0.5),
          ),
        ),
      },
      cellVerticalAlignment: pw.TableCellVerticalAlignment.middle,
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
