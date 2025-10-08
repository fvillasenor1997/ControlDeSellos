import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:image/image.dart' as img;

import 'config_service.dart';
import 'config_model.dart';
import 'config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService().init();
  runApp(const SelladoApp());
}

class SelladoApp extends StatelessWidget {
  const SelladoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Sellos',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const SelladoHomePage(),
    );
  }
}

class SelladoHomePage extends StatefulWidget {
  const SelladoHomePage({super.key});
  @override
  State<SelladoHomePage> createState() => _SelladoHomePageState();
}

class _SelladoHomePageState extends State<SelladoHomePage> {
  bool _isProcessing = false;

  Future<void> _pickAndProcessPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      await _processFile(result.files.single.path!);
    }
  }

  Future<void> _processFile(String filePath) async {
    setState(() => _isProcessing = true);

    try {
      final config = await ConfigService().loadConfig();

      final pdfBytes = await File(filePath).readAsBytes();
      final pdf.PdfDocument document = pdf.PdfDocument(inputBytes: pdfBytes);
      final pdf.PdfFont font = pdf.PdfStandardFont(pdf.PdfFontFamily.helvetica, 9);
      final pdf.PdfFont boldFont = pdf.PdfStandardFont(
        pdf.PdfFontFamily.helvetica,
        10,
        style: pdf.PdfFontStyle.bold,
      );

      // Detectar los jobs en el PDF
      final jobRanges = await _findJobRanges(filePath);
      debugPrint("Jobs detectados: ${jobRanges.length}");

      for (final job in jobRanges) {
        final pages = job['pages'] as List<int>;
        final jobCode = job['code'] as String;
        final int lastPageIndex = pages.last - 1;

        debugPrint("Procesando Job: $jobCode (páginas ${pages.first}-${pages.last})");

        final page = document.pages[lastPageIndex];
        final pageSize = Size(page.size.width, page.size.height);

        // Detectar si el área está ocupada
        if (await _isAreaOccupied(filePath, pages.last, pageSize)) {
          final pdf.PdfPage newPage = document.pages.insert(lastPageIndex + 1, page.size);
          final newPageSize = Size(newPage.getClientSize().width, newPage.getClientSize().height);

          // Copiar encabezado
          await _copyHeaderToNewPage(filePath, pages.first, newPage, newPageSize);

          // Dibujar tabla en la nueva hoja
          _drawFooter(newPage.graphics, newPageSize, font, boldFont);
          debugPrint("Nueva hoja creada para Job $jobCode");
        } else {
          // Dibujar tabla en la última hoja del job
          _drawFooter(page.graphics, pageSize, font, boldFont);
          debugPrint("Tabla insertada en última hoja de Job $jobCode");
        }
      }

      // Guardar nuevo PDF
      final outputPath = filePath.replaceAll('.pdf', '_SELLADO.pdf');
      await File(outputPath).writeAsBytes(await document.save());
      document.dispose();

      await OpenFile.open(outputPath);
    } catch (e) {
      debugPrint('Error al procesar el PDF: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Detecta los rangos de páginas que pertenecen a cada "Job:" y extrae su código
  Future<List<Map<String, dynamic>>> _findJobRanges(String filePath) async {
    final pdfDoc = await pdfx.PdfDocument.openFile(filePath);
    final List<Map<String, dynamic>> jobRanges = [];
    List<int> currentJob = [];
    String? currentJobCode;

    for (int i = 1; i <= pdfDoc.pagesCount; i++) {
      final page = await pdfDoc.getPage(i);
      final text = await page.renderText();
      await page.close();

      // Buscar patrón "Job: M000102269-0000"
      final match = RegExp(r'Job\s*:\s*([A-Za-z0-9\-_.]+)', caseSensitive: false).firstMatch(text);
      if (match != null) {
        if (currentJob.isNotEmpty && currentJobCode != null) {
          jobRanges.add({
            'code': currentJobCode,
            'pages': List.from(currentJob),
          });
          currentJob.clear();
        }
        currentJobCode = match.group(1)?.trim();
        debugPrint("Detectado nuevo Job: $currentJobCode en página $i");
      }

      currentJob.add(i);
    }

    if (currentJob.isNotEmpty && currentJobCode != null) {
      jobRanges.add({
        'code': currentJobCode,
        'pages': List.from(currentJob),
      });
    }

    await pdfDoc.close();
    return jobRanges;
  }

  /// Dibuja la tabla en el pie de página
  void _drawFooter(pdf.PdfGraphics graphics, Size pageSize, pdf.PdfFont font, pdf.PdfFont boldFont) {
    const double tableWidth = 400;
    const double tableHeight = 50;
    final double x = (pageSize.width - tableWidth) / 2;
    final double y = pageSize.height - tableHeight - 40;

    final pdf.PdfPen pen = pdf.PdfPen(pdf.PdfColor(0, 0, 0));
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(x, y, tableWidth, tableHeight),
      pen: pen,
    );

    graphics.drawString('Sello y Firma', boldFont, bounds: Rect.fromLTWH(x + 10, y + 15, 200, 20));
  }

  /// Verifica si hay contenido en el área del pie
  Future<bool> _isAreaOccupied(String filePath, int pageNumber, Size pageSize) async {
    final pdfDoc = await pdfx.PdfDocument.openFile(filePath);
    final page = await pdfDoc.getPage(pageNumber);
    final text = await page.renderText();
    await page.close();
    await pdfDoc.close();

    final footerArea = Rect.fromLTWH(0, pageSize.height - 100, pageSize.width, 100);
    final lowerText = text.toLowerCase();

    return lowerText.contains("firma") || lowerText.contains("sello");
  }

  /// Copia el encabezado de la primera hoja del job a una nueva hoja
  Future<void> _copyHeaderToNewPage(String filePath, int headerPage, pdf.PdfPage newPage, Size pageSize) async {
    final pdfDoc = await pdfx.PdfDocument.openFile(filePath);
    final srcPage = await pdfDoc.getPage(headerPage);

    final pageImage = await srcPage.render(
      width: pageSize.width.toInt(),
      height: 150,
      format: pdfx.PdfPageImageFormat.png,
    );
    await srcPage.close();
    await pdfDoc.close();

    final headerImage = img.decodeImage(pageImage!.bytes);
    if (headerImage == null) return;

    final headerBytes = img.encodePng(headerImage);
    final pdf.PdfBitmap headerBitmap = pdf.PdfBitmap(headerBytes);

    newPage.graphics.drawImage(
      headerBitmap,
      Rect.fromLTWH(0, 72, pageSize.width, 150), // ~2.5 cm de margen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Sellos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfigScreen()),
              );
              if (updated == true) setState(() {});
            },
          ),
        ],
      ),
      body: DropTarget(
        onDragDone: (details) async {
          if (details.files.isNotEmpty) {
            final file = details.files.first;
            await _processFile(file.path);
          }
        },
        child: Center(
          child: _isProcessing
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Procesando archivo...'),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf, size: 80, color: Colors.indigo),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickAndProcessPdf,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Seleccionar archivo PDF'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'O arrastra un archivo PDF aquí',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
