import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';

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
  bool _isDragOver = false;

  Future<void> _pickAndProcessPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      await _processFile(result.files.single.path!);
    }
  }

  Future<void> _processFile(String filePath) async {
    if (!filePath.toLowerCase().endsWith('.pdf')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, utiliza solo archivos PDF.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pdfBytes = await File(filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 9);
      final PdfFont boldFont =
          PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
      final PdfFont smallFont = PdfStandardFont(PdfFontFamily.helvetica, 6);

      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final PdfGraphics graphics = page.graphics;
        _drawFooter(graphics, page.getClientSize(), font, boldFont, smallFont);
      }

      final List<int> newPdfBytes = await document.save();
      document.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final originalName = filePath.split(Platform.pathSeparator).last;
      final newName = originalName.replaceAll('.pdf', '_SELLADO.pdf');
      final path = '${directory.path}/$newName';
      final file = File(path);
      await file.writeAsBytes(newPdfBytes);

      if (mounted) {
        OpenFile.open(path);
      }
    } catch (e, s) {
      debugPrint('Error al procesar el PDF: $e');
      debugPrint('Stack trace: $s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _drawFooter(PdfGraphics graphics, Size pageSize, PdfFont font,
      PdfFont boldFont, PdfFont smallFont) {
    const double cmToPoints = 28.35;
    const double bottomOffset = 30 + cmToPoints;
    const double headerRowHeight = 20;
    const double deptRowHeight = 20;
    const double selloRowHeight = 50;
    const double firmaRowHeight = 25;
    const double footerHeight =
        headerRowHeight + deptRowHeight + selloRowHeight + firmaRowHeight;
    final double footerY = pageSize.height - footerHeight - bottomOffset;

    final PdfPen pen = PdfPen(PdfColor(0, 0, 0), width: 0.5);
    final double footerWidth = pageSize.width - 40;

    final double col1Width = footerWidth * 0.49;
    final double col2Width = footerWidth * 0.17;
    final double col3Width = footerWidth * 0.17;
    final double col4Width = footerWidth * 0.17;

    graphics.drawRectangle(
      pen: pen,
      bounds: Rect.fromLTWH(20, footerY, footerWidth, footerHeight),
    );

    double currentY = footerY;
    graphics.drawLine(pen, Offset(20, currentY + headerRowHeight),
        Offset(20 + footerWidth, currentY + headerRowHeight));
    currentY += headerRowHeight;
    graphics.drawLine(pen, Offset(20, currentY + deptRowHeight),
        Offset(20 + footerWidth, currentY + deptRowHeight));
    currentY += deptRowHeight;
    graphics.drawLine(pen, Offset(20, currentY + selloRowHeight),
        Offset(20 + footerWidth, currentY + selloRowHeight));

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
    
    Rect cellBounds = Rect.fromLTWH(cellX, cellY, cellWidth, cellHeight);

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
      body: DropTarget(
        onDragDone: (details) {
          if (details.files.isNotEmpty) {
            _processFile(details.files.first.path);
          }
        },
        onDragEntered: (details) => setState(() => _isDragOver = true),
        onDragExited: (details) => setState(() => _isDragOver = false),
        child: Container(
          color: _isDragOver ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
          child: _isLoading
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
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                         Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.grey),
                         SizedBox(height: 16),
                         Text(
                          'Arrastra y suelta un archivo PDF aquí o presiona el botón para seleccionarlo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _pickAndProcessPdf,
        label: const Text('Seleccionar PDF'),
        icon: const Icon(Icons.picture_as_pdf),
      ),
    );
  }
}
