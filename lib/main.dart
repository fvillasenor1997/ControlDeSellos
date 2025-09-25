// lib/main.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
      final result = await FilePicker.platform.pickFiles(
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

      final pdfBytes = result.files.single.bytes!;
      final newPdf = pw.Document();
      final existingPdf = await Printing.convertUserInput(
        format: PdfPageFormat.a4,
        bytes: pdfBytes,
      );

      final pdfDocument = PdfDocument.openData(existingPdf);

      for (var i = 1; i <= pdfDocument.pageCount; i++) {
        final page = await pdfDocument.getPage(i);
        final pageImage = pw.Image(pw.MemoryImage(page.image.bytes));

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

      final newPdfBytes = await newPdf.save();

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

  pw.Widget _buildFooter() {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: pw.Text('DEPARTAMENTOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Container(padding: const pw.EdgeInsets.all(2), alignment: pw.Alignment.center, child: pw.Text('METALURGIA', style: const pw.TextStyle(fontSize: 9))),
            pw.Container(padding: const pw.EdgeInsets.all(2), alignment: pw.Alignment.center, child: pw.Text('ALMACEN', style: const pw.TextStyle(fontSize: 9))),
            pw.Container(padding: const pw.EdgeInsets.all(2), alignment: pw.Alignment.center, child: pw.Text('CALIDAD', style: const pw.TextStyle(fontSize: 9))),
            pw.Container(padding: const pw.EdgeInsets.all(2), alignment: pw.Alignment.center, child: pw.Text('PRODUCCION', style: const pw.TextStyle(fontSize: 9))),
          ],
        ),
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
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
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
