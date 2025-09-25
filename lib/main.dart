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

  // --- FUNCIÓN ACTUALIZADA CON LA LIBRERÍA PDF/PRINTING ---
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
      
      // Creamos un nuevo documento PDF
      final pw.Document newPdf = pw.Document();

      // Cargamos el PDF existente para poder copiar sus páginas
      final PdfDocument existingPdf = await PdfDocument.openData(pdfBytes);
      
      // Iteramos sobre cada página del PDF original
      for (int i = 0; i < existingPdf.pageCount; i++) {
        final PdfPage page = await existingPdf.getPage(i+1);
        final pw.Image pageImage = pw.Image(page.image);

        // Agregamos una nueva página al documento que estamos creando
        newPdf.addPage(
          pw.Page(
            pageFormat: page.pageFormat,
            build: (pw.Context context) {
              // Usamos un Stack para poner el pie de página sobre la página original
              return pw.Stack(
                children: [
                  // 1. La página original como imagen de fondo
                  pageImage,
                  // 2. Nuestro pie de página posicionado en la parte inferior
                  pw.Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: _buildFooter(),
                  ),
                ],
              );
            },
          ),
        );
      }
      
      // Guardamos el nuevo PDF en memoria
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
        print('Error al procesar el PDF: $e');
        print('Stack trace: $s');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el PDF: $e')),
        );
      }
    }
  }

  // --- WIDGET AUXILIAR PARA CREAR EL PIE DE PÁGINA ---
  pw.Widget _buildFooter() {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'DEPARTAMENTOS',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
          repeat: true, // Para que el encabezado se repita en varias páginas
        ),
        pw.TableRow(
          children: [
            pw.Text('METALURGIA', textAlign: pw.TextAlign.center),
            pw.Text('ALMACEN', textAlign: pw.TextAlign.center),
            pw.Text('CALIDAD', textAlign: pw.TextAlign.center),
            pw.Text('PRODUCCION', textAlign: pw.TextAlign.center),
          ],
        ),
        pw.TableRow(
          children: List.generate(4, (_) => pw.Container(
            height: 25,
            alignment: pw.Alignment.center,
            child: pw.Text('SELLO'),
          )),
        ),
        pw.TableRow(
          children: List.generate(4, (_) => pw.Container(
            height: 15,
            alignment: pw.Alignment.center,
            child: pw.Text('FIRMA'),
          )),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    // ... El resto del widget build se mantiene igual
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
