import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'pdf_preview_screen.dart'; // Asegúrate de que este archivo existe

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
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final PdfStringFormat centerAlignment = PdfStringFormat(
          alignment: PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle);

      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final Size pageSize = page.getClientSize();
        final PdfGrid grid = PdfGrid();
        grid.columns.add(count: 4);

        final PdfGridRow header = grid.headers.add(1)[0];
        header.cells[0].value = 'DEPARTAMENTOS';
        header.cells[0].columnSpan = 4;
        header.cells[0].stringFormat = centerAlignment;
        header.style.font =
            PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

        final PdfGridRow subHeader = grid.rows.add();
        // --- CAMBIO DE ORDEN AQUÍ ---
        subHeader.cells[0].value = 'METALURGIA';
        subHeader.cells[1].value = 'ALMACEN';
        subHeader.cells[2].value = 'CALIDAD';
        subHeader.cells[3].value = 'PRODUCCION';
        // --- FIN DEL CAMBIO ---
        for (int j = 0; j < subHeader.cells.count; j++) {
          subHeader.cells[j].stringFormat = centerAlignment;
        }

        final PdfGridRow stampRow = grid.rows.add();
        stampRow.height = 40;
        for (int j = 0; j < stampRow.cells.count; j++) {
          stampRow.cells[j].value = 'SELLO';
          stampRow.cells[j].stringFormat = centerAlignment;
        }

        final PdfGridRow signRow = grid.rows.add();
        for (int j = 0; j < signRow.cells.count; j++) {
            signRow.cells[j].value = 'FIRMA';
            signRow.cells[j].stringFormat = centerAlignment;
        }

        grid.draw(
          page: page,
          bounds: Rect.fromLTWH(0, pageSize.height - 100, pageSize.width, 100),
        );
      }

      final List<int> newPdfBytes = await document.save();
      document.dispose();
      
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                PdfPreviewScreen(pdfBytes: Uint8List.fromList(newPdfBytes)),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el PDF: $e')),
        );
      }
    }
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

