import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
  Future<void> _addFooterToPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se seleccionó ningún archivo.')),
      );
      return;
    }

    File file = File(result.files.single.path!);
    final Uint8List pdfBytes = await file.readAsBytes();
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
      subHeader.cells[0].value = 'ALMACEN';
      subHeader.cells[1].value = 'METALURGIA';
      subHeader.cells[2].value = 'CALIDAD';
      subHeader.cells[3].value = 'PRODUCCION';
      for (int j = 0; j < subHeader.cells.count; j++) {
        subHeader.cells[j].stringFormat = centerAlignment;
      }

      final PdfGridRow stampRow = grid.rows.add();
      stampRow.height = 40; // Altura de la fila del sello
      for (int j = 0; j < stampRow.cells.count; j++) {
        stampRow.cells[j].value = 'SELLO';
        stampRow.cells[j].stringFormat = centerAlignment;
      }

      final PdfGridRow signRow = grid.rows.add();
      signRow.cells[0].value = 'FIRMA';
      signRow.cells[1].value = 'FIRMA';
      signRow.cells[2].value = 'FIRMA';
      signRow.cells[3].value = 'FIRMA';
       for (int j = 0; j < signRow.cells.count; j++) {
        signRow.cells[j].stringFormat = centerAlignment;
      }


      grid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, pageSize.height - 100, pageSize.width, 100),
      );
    }

    final List<int> newPdfBytes = await document.save();
    document.dispose();

    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String newFileName =
        'firmado_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File newFile = File('$path/$newFileName');
    await newFile.writeAsBytes(newPdfBytes, flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF guardado en: ${newFile.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Pie de Página a PDF'),
      ),
      body: const Center(
        child: Text('Presiona el botón para seleccionar un PDF y agregar el pie de página.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFooterToPdf,
        child: const Icon(Icons.add),
      ),
    );
  }
}
