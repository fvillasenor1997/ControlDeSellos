// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
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
  bool _isLoading = false;

  Future<void> _processAndSavePdf() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      
      final filePath = result.files.single.path!;
      final pdfBytes = await File(filePath).readAsBytes();

      // Cargar el documento PDF existente
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      // Crear la fuente para el texto del pie de página
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 9);
      final PdfFont boldFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

      // Iterar sobre cada página y agregar el pie de página
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final PdfGraphics graphics = page.graphics;

        // Dibujar el pie de página
        _drawFooter(graphics, page.getClientSize(), font, boldFont);
      }

      // Guardar el documento modificado
      final List<int> newPdfBytes = await document.save();
      document.dispose();

      // Guardar y abrir el archivo para previsualizar
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/controldesellos_modificado.pdf';
      final file = File(path);
      await file.writeAsBytes(newPdfBytes);

      if (mounted) {
        setState(() => _isLoading = false);
        OpenFile.open(path);
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
  
  void _drawFooter(PdfGraphics graphics, Size pageSize, PdfFont font, PdfFont boldFont) {
    // --- AJUSTES DE DISEÑO ---
    const double bottomOffset = 30; // Sube todo el cuadro
    const double headerRowHeight = 20;
    const double deptRowHeight = 20;
    const double selloRowHeight = 50; // Doble de alto
    const double firmaRowHeight = 25;
    const double footerHeight = headerRowHeight + deptRowHeight + selloRowHeight + firmaRowHeight;
    const double footerY = pageSize.height - footerHeight - bottomOffset;
    // --- FIN DE AJUSTES ---

    final PdfPen pen = PdfPen(PdfColor(0, 0, 0), width: 0.5);
    final double footerWidth = pageSize.width - 40;
    
    // Dibuja el rectángulo contenedor
    graphics.drawRectangle(
      pen: pen,
      bounds: Rect.fromLTWH(20, footerY, footerWidth, footerHeight),
    );
    
    // Líneas horizontales
    double currentY = footerY;
    graphics.drawLine(pen, Offset(20, currentY + headerRowHeight), Offset(20 + footerWidth, currentY + headerRowHeight));
    currentY += headerRowHeight;
    graphics.drawLine(pen, Offset(20, currentY + deptRowHeight), Offset(20 + footerWidth, currentY + deptRowHeight));
    currentY += deptRowHeight;
    graphics.drawLine(pen, Offset(20, currentY + selloRowHeight), Offset(20 + footerWidth, currentY + selloRowHeight));
    
    // Líneas verticales
    final double colWidth = footerWidth / 4;
    for (int i = 1; i < 4; i++) {
      graphics.drawLine(
        pen,
        Offset(20 + (colWidth * i), footerY + headerRowHeight),
        Offset(20 + (colWidth * i), footerY + footerHeight),
      );
    }
    
    // --- DIBUJAR TEXTO ---
    // Fila del Título
    _drawCellText(graphics, 'DEPARTAMENTOS', boldFont, 0, colWidth * 4, footerY, headerRowHeight);

    // Fila de Nombres de Departamentos
    _drawCellText(graphics, 'METALURGIA', font, 0, colWidth, footerY + headerRowHeight, deptRowHeight);
    _drawCellText(graphics, 'ALMACEN', font, 1, colWidth, footerY + headerRowHeight, deptRowHeight);
    _drawCellText(graphics, 'CALIDAD', font, 2, colWidth, footerY + headerRowHeight, deptRowHeight);
    _drawCellText(graphics, 'PRODUCCION', font, 3, colWidth, footerY + headerRowHeight, deptRowHeight);

    // Fila de Sello
    final selloY = footerY + headerRowHeight + deptRowHeight;
    _drawCellText(graphics, 'SELLO', font, 0, colWidth, selloY, selloRowHeight);
    _drawCellText(graphics, 'SELLO', font, 1, colWidth, selloY, selloRowHeight);
    _drawCellText(graphics, 'SELLO', font, 2, colWidth, selloY, selloRowHeight);
    _drawCellText(graphics, 'SELLO', font, 3, colWidth, selloY, selloRowHeight);
    
    // Fila de Firma
    final firmaY = selloY + selloRowHeight;
    _drawCellText(graphics, 'FIRMA', font, 0, colWidth, firmaY, firmaRowHeight);
    _drawCellText(graphics, 'FIRMA', font, 1, colWidth, firmaY, firmaRowHeight);
    _drawCellText(graphics, 'FIRMA', font, 2, colWidth, firmaY, firmaRowHeight);
    _drawCellText(graphics, 'FIRMA', font, 3, colWidth, firmaY, firmaRowHeight);
  }

  void _drawCellText(PdfGraphics graphics, String text, PdfFont font, int colIndex, double cellWidth, double cellY, double cellHeight) {
     graphics.drawString(
      text, font,
      bounds: Rect.fromLTWH(20 + (colWidth * colIndex), cellY, cellWidth, cellHeight),
      format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle)
    );
  }

  // Variable auxiliar para el ancho de columna
  double get colWidth => (595.27 - 40) / 4; // Ancho A4 - márgenes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Pie de Página a PDF'),
      ),
body: _isLoading
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
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
              'Presiona el botón para seleccionar un PDF, agregarle el pie de página y guardarlo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _processAndSavePdf,
        tooltip: 'Seleccionar PDF',
        child: const Icon(Icons.picture_as_pdf),
      ),
    );
  }
}
