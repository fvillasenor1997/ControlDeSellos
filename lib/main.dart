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

      // Crear las fuentes
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 9);
      final PdfFont boldFont =
          PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
      final PdfFont smallFont = PdfStandardFont(PdfFontFamily.helvetica, 6);

      // Iterar sobre páginas
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final PdfGraphics graphics = page.graphics;

        _drawFooter(graphics, page.getClientSize(), font, boldFont, smallFont);
      }

      // Guardar el documento modificado
      final List<int> newPdfBytes = await document.save();
      document.dispose();

      // Guardar y abrir archivo con sufijo _SELLADO
      final directory = await getApplicationDocumentsDirectory();
      final originalName = filePath.split(Platform.pathSeparator).last;
      final newName = originalName.replaceAll('.pdf', '_SELLADO.pdf');
      final path = '${directory.path}/$newName';

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

  void _drawFooter(PdfGraphics graphics, Size pageSize, PdfFont font,
      PdfFont boldFont, PdfFont smallFont) {
    const double cmToPoints = 28.35;
    const double bottomOffset = 30 + cmToPoints; // Subir la tabla 1 cm
    const double headerRowHeight = 20;
    const double deptRowHeight = 20;
    const double selloRowHeight = 50;
    const double firmaRowHeight = 25;
    const double footerHeight =
        headerRowHeight + deptRowHeight + selloRowHeight + firmaRowHeight;
    final double footerY = pageSize.height - footerHeight - bottomOffset;

    final PdfPen pen = PdfPen(PdfColor(0, 0, 0), width: 0.5);
    final double footerWidth = pageSize.width - 40;

    // Calcular anchos de columna
    final double col1Width = footerWidth * 0.49;
    final double col2Width = footerWidth * 0.17;
    final double col3Width = footerWidth * 0.17;
    final double col4Width = footerWidth * 0.17;

    // Rectángulo
    graphics.drawRectangle(
      pen: pen,
      bounds: Rect.fromLTWH(20, footerY, footerWidth, footerHeight),
    );

    // Líneas horizontales
    double currentY = footerY;
    graphics.drawLine(pen, Offset(20, currentY + headerRowHeight),
        Offset(20 + footerWidth, currentY + headerRowHeight));
    currentY += headerRowHeight;
    graphics.drawLine(pen, Offset(20, currentY + deptRowHeight),
        Offset(20 + footerWidth, currentY + deptRowHeight));
    currentY += deptRowHeight;
    graphics.drawLine(pen, Offset(20, currentY + selloRowHeight),
        Offset(20 + footerWidth, currentY + selloRowHeight));

    // Líneas verticales
    double currentX = 20;
    currentX += col1Width;
    graphics.drawLine(pen, Offset(currentX, footerY + headerRowHeight),
        Offset(currentX, footerY + footerHeight));
    currentX += col2Width;
    graphics.drawLine(pen, Offset(currentX, footerY + headerRowHeight),
        Offset(currentX, footerY + footerHeight));
    currentX += col3Width;
    graphics.drawLine(pen, Offset(currentX, footerY + headerRowHeight),
        Offset(currentX, footerY + footerHeight));


    // Texto
    _drawCellText(graphics, 'DEPARTAMENTOS', boldFont, 20, footerWidth, footerY,
        headerRowHeight);
    
    currentX = 20;
    _drawCellText(graphics, 'METALURGIA', font, currentX, col1Width,
        footerY + headerRowHeight, deptRowHeight);
    currentX += col1Width;
    _drawCellText(graphics, 'ALMACEN', font, currentX, col2Width,
        footerY + headerRowHeight, deptRowHeight);
    currentX += col2Width;
    _drawCellText(graphics, 'CALIDAD', font, currentX, col3Width,
        footerY + headerRowHeight, deptRowHeight);
    currentX += col3Width;
    _drawCellText(graphics, 'PRODUCCION', font, currentX, col4Width,
        footerY + headerRowHeight, deptRowHeight);


    final selloY = footerY + headerRowHeight + deptRowHeight;
    currentX = 20;
    _drawCellText(
        graphics, 'SELLO', smallFont, currentX, col1Width, selloY, selloRowHeight, 
        alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);
    currentX += col1Width;
     _drawCellText(
        graphics, 'SELLO', smallFont, currentX, col2Width, selloY, selloRowHeight, 
        alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);
    currentX += col2Width;
     _drawCellText(
        graphics, 'SELLO', smallFont, currentX, col3Width, selloY, selloRowHeight, 
        alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);
    currentX += col3Width;
     _drawCellText(
        graphics, 'SELLO', smallFont, currentX, col4Width, selloY, selloRowHeight, 
        alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);

    final firmaY = selloY + selloRowHeight;
    currentX = 20;
    _drawCellText(
        graphics, 'FIRMA', smallFont, currentX, col1Width, firmaY, firmaRowHeight, 
        alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);
    currentX += col1Width;
    _drawCellText(
        graphics, 'FIRMA', smallFont, currentX, col2Width, firmaY, firmaRowHeight, 
        alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);
    currentX += col2Width;
    _drawCellText(
        graphics, 'FIRMA', smallFont, currentX, col3Width, firmaY, firmaRowHeight, 
        alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);
    currentX += col3Width;
    _drawCellText(
        graphics, 'FIRMA', smallFont, currentX, col4Width, firmaY, firmaRowHeight, 
        alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);
  }

  void _drawCellText(PdfGraphics graphics, String text, PdfFont font,
      double cellX, double cellWidth, double cellY, double cellHeight,
      {PdfTextAlignment alignment = PdfTextAlignment.center,
       PdfVerticalAlignment vAlignment = PdfVerticalAlignment.middle}) {
        
    double hPadding = 2;
    double vPadding = 2;
    
    Rect cellBounds = Rect.fromLTWH(
      cellX, 
      cellY, 
      cellWidth, 
      cellHeight
    );

    Rect paddedBounds = Rect.fromLTWH(
        cellBounds.left + hPadding,
        cellBounds.top + vPadding,
        cellBounds.width - (hPadding * 2),
        cellBounds.height - (vPadding * 2));

    graphics.drawString(text, font,
        bounds: paddedBounds,
        format: PdfStringFormat(
            alignment: alignment,
            lineAlignment: vAlignment));
  }

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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.0),
                    child: LinearProgressIndicator(),
                  ),
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
