import 'dart:io';
import 'dart:ui'; // Para usar Size, Rect, Offset
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:image/image.dart' as img;

import 'config_model.dart';
import 'config_screen.dart';
import 'config_service.dart';
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

class JobInfo {
  final String jobNumber;
  final List<int> pages;

  JobInfo(this.jobNumber, this.pages);

  int get lastPage => pages.isNotEmpty ? pages.last : 0;
}

class _PdfProcessingScreenState extends State<PdfProcessingScreen> {
  bool _isLoading = false;
  bool _isDragOver = false;
  final ConfigService _configService = ConfigService();
  late ConfigModel _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _config = await _configService.loadConfig();
    setState(() {});
  }

  Future<void> _pickAndProcessPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      await _processFile(result.files.single.path!);
    }
  }

  /// Extrae el texto de una página usando syncfusion
  Future<String?> _extractTextFromPage(String filePath, int pageNumber) async {
    try {
      final pdfBytes = await File(filePath).readAsBytes();
      final pdf.PdfDocument document = pdf.PdfDocument(inputBytes: pdfBytes);
      
      if (pageNumber > document.pages.count || pageNumber < 1) {
        document.dispose();
        return null;
      }

      final pdf.PdfTextExtractor extractor = pdf.PdfTextExtractor(document);
      final String text = extractor.extractText(startPageIndex: pageNumber - 1, endPageIndex: pageNumber - 1);
      
      document.dispose();
      return text;
    } catch (e) {
      debugPrint("Error extrayendo texto de página $pageNumber: $e");
      return null;
    }
  }

  /// Encuentra todos los jobs únicos y sus páginas
  Future<Map<String, JobInfo>> _findUniqueJobs(String filePath, int totalPages) async {
    Map<String, JobInfo> jobs = {};
    final RegExp jobPattern = RegExp(r'Job:\s*([A-Z0-9]+-[0-9]+)', caseSensitive: false);

    for (int i = 1; i <= totalPages; i++) {
      final text = await _extractTextFromPage(filePath, i);
      if (text != null && text.isNotEmpty) {
        final match = jobPattern.firstMatch(text);
        if (match != null) {
          final jobNumber = match.group(1)!.toUpperCase();
          
          if (jobs.containsKey(jobNumber)) {
            // Job ya existe, agregar página
            jobs[jobNumber]!.pages.add(i);
            debugPrint("Job $jobNumber encontrado en página $i (ya existía)");
          } else {
            // Nuevo job
            jobs[jobNumber] = JobInfo(jobNumber, [i]);
            debugPrint("Nuevo Job $jobNumber encontrado en página $i");
          }
        }
      }
    }

    // Mostrar resumen de jobs encontrados
    debugPrint("\n=== RESUMEN DE JOBS ===");
    jobs.forEach((jobNum, jobInfo) {
      debugPrint("Job: $jobNum - Páginas: ${jobInfo.pages} - Última página: ${jobInfo.lastPage}");
    });
    debugPrint("Total de jobs únicos: ${jobs.length}\n");

    return jobs;
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
      final pdf.PdfDocument document = pdf.PdfDocument(inputBytes: pdfBytes);
      final pdf.PdfFont font = pdf.PdfStandardFont(pdf.PdfFontFamily.helvetica, 9);
      final pdf.PdfFont boldFont =
          pdf.PdfStandardFont(pdf.PdfFontFamily.helvetica, 10, style: pdf.PdfFontStyle.bold);

      // Encontrar todos los jobs únicos
      final jobs = await _findUniqueJobs(filePath, document.pages.count);

      if (jobs.isEmpty) {
        debugPrint("No se encontraron jobs. Procesando la última página del documento.");
        final lastPageIndex = document.pages.count - 1;
        final page = document.pages[lastPageIndex];
        final pageSize = Size(page.size.width, page.size.height);
        
        if (await _isAreaOccupied(filePath, lastPageIndex + 1, pageSize)) {
          final pdf.PdfPage newPage = document.pages.add();
          final newPageSize = Size(newPage.getClientSize().width, newPage.getClientSize().height);
          await _copyHeaderToNewPage(filePath, lastPageIndex + 1, newPage, newPageSize);
          _drawFooter(newPage.graphics, newPageSize, font, boldFont);
        } else {
          _drawFooter(page.graphics, pageSize, font, boldFont);
        }
      } else {
        // Obtener las últimas páginas de cada job y ordenarlas de mayor a menor
        List<int> lastPagesDescending = jobs.values.map((job) => job.lastPage).toList();
        lastPagesDescending.sort((a, b) => b.compareTo(a));

        int pageOffset = 0;

        // Procesar cada última página en orden descendente
        for (final pageNum in lastPagesDescending) {
          final pageIndex = pageNum - 1 + pageOffset;
          
          if (pageIndex >= document.pages.count) continue;

          final page = document.pages[pageIndex];
          final pageSize = Size(page.size.width, page.size.height);

          // Buscar a qué job pertenece esta página
          String jobNumber = "";
          for (var entry in jobs.entries) {
            if (entry.value.lastPage == pageNum) {
              jobNumber = entry.key;
              break;
            }
          }

          debugPrint("Procesando última página del Job $jobNumber: página ${pageIndex + 1}");

          if (await _isAreaOccupied(filePath, pageNum, pageSize)) {
            debugPrint("Área ocupada, insertando nueva página para Job $jobNumber");
            final pdf.PdfPage newPage = document.pages.insert(pageIndex + 1, page.size);
            final newPageSize = Size(newPage.getClientSize().width, newPage.getClientSize().height);

            await _copyHeaderToNewPage(filePath, pageNum, newPage, newPageSize);
            _drawFooter(newPage.graphics, newPageSize, font, boldFont);

            pageOffset++;
          } else {
            debugPrint("Área libre, agregando tabla en la misma página para Job $jobNumber");
            _drawFooter(page.graphics, pageSize, font, boldFont);
          }
        }
      }

      final List<int> newPdfBytes = await document.save();
      document.dispose();

      // Crear carpeta "Jobs" dentro de Documentos
      final directory = await getApplicationDocumentsDirectory();
      final jobsFolder = Directory('${directory.path}/Jobs');
      
      // Crear la carpeta si no existe
      if (!await jobsFolder.exists()) {
        await jobsFolder.create(recursive: true);
        debugPrint("Carpeta Jobs creada en: ${jobsFolder.path}");
      }

      final originalName = filePath.split(Platform.pathSeparator).last;
      final newName = originalName.replaceAll('.pdf', '_SELLADO.pdf');
      final path = '${jobsFolder.path}/$newName';
      final file = File(path);
      await file.writeAsBytes(newPdfBytes);
      
      debugPrint("PDF guardado en: $path");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF procesado: ${jobs.length} job(s) único(s) encontrado(s)')),
        );
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

  /// Copiar encabezado desde la página original a la nueva
  Future<void> _copyHeaderToNewPage(
      String filePath, int pageNumber, pdf.PdfPage newPage, Size pageSize) async {
    try {
      final pdfDoc = await pdfx.PdfDocument.openFile(filePath);
      final page = await pdfDoc.getPage(pageNumber);

      final pageImage = await page.render(
        width: page.width,
        height: page.height,
        format: pdfx.PdfPageImageFormat.png,
      );

      await page.close();
      await pdfDoc.close();

      if (pageImage == null) return;

      final img.Image? image = img.decodeImage(pageImage.bytes);
      if (image == null) return;

      // Altura de encabezado desde configuración
      final int headerHeight = _config.copiedHeaderHeight.toInt();

      // Recortamos la parte superior de la página (encabezado)
      final img.Image headerCrop = img.copyCrop(
        image,
        x: 0,
        y: 0,
        width: image.width,
        height: headerHeight,
      );

      // Convertimos a PNG
      final headerBytes = img.encodePng(headerCrop);
      final pdf.PdfBitmap headerBitmap = pdf.PdfBitmap(headerBytes);

      newPage.graphics.drawImage(
        headerBitmap,
        Rect.fromLTWH(
          0,
          20, // margen superior
          pageSize.width,
          headerHeight.toDouble(),
        ),
      );
    } catch (e, s) {
      debugPrint("Error copiando encabezado en página $pageNumber: $e");
      debugPrint(s.toString());
    }
  }

  Rect _getFooterBounds(Size pageSize) {
    const double cmToPoints = 28.35;
    const double bottomOffset = 30 + cmToPoints;

    final headerRowHeight = _config.rowHeights['header']!;
    final deptRowHeight = _config.rowHeights['department']!;
    final selloRowHeight = _config.rowHeights['stamp']!;
    final firmaRowHeight = _config.rowHeights['signature']!;
    final dateRowHeight = _config.rowHeights['date']!;

    final double footerHeight =
        headerRowHeight + deptRowHeight + selloRowHeight + firmaRowHeight + dateRowHeight;
    final double footerY = pageSize.height - footerHeight - bottomOffset;

    return Rect.fromLTWH(0, footerY, pageSize.width, footerHeight);
  }

  Future<bool> _isAreaOccupied(String filePath, int pageNumber, Size pageSize) async {
    try {
      final pdfDoc = await pdfx.PdfDocument.openFile(filePath);
      final page = await pdfDoc.getPage(pageNumber);

      final pageImage = await page.render(
        width: page.width,
        height: page.height,
        format: pdfx.PdfPageImageFormat.png,
      );
      await page.close();
      await pdfDoc.close();

      if (pageImage == null) return false;

      final img.Image? image = img.decodeImage(pageImage.bytes);
      if (image == null) return false;

      final Rect footerBounds = _getFooterBounds(pageSize);

      int left = footerBounds.left.toInt();
      int top = footerBounds.top.toInt();
      int width = footerBounds.width.toInt();
      int height = footerBounds.height.toInt();

      if (left < 0) left = 0;
      if (top < 0) top = 0;
      if (left + width > image.width) width = image.width - left;
      if (top + height > image.height) height = image.height - top;

      int nonWhitePixelCount = 0;
      const int pixelThreshold = 50;
      const int sampleRate = 5;

      for (int y = top; y < top + height; y += sampleRate) {
        for (int x = left; x < left + width; x += sampleRate) {
          final pixel = image.getPixel(x, y);
          if ((pixel.r < 250 || pixel.g < 250 || pixel.b < 250) && pixel.a > 10) {
            nonWhitePixelCount++;
            if (nonWhitePixelCount > pixelThreshold) {
              debugPrint("Superposición detectada en página $pageNumber por análisis de píxeles.");
              return true;
            }
          }
        }
      }
    } catch (e, s) {
      debugPrint("Error durante el análisis de imagen de la página $pageNumber: $e");
      debugPrint(s.toString());
      return false;
    }

    return false;
  }

  void _drawFooter(pdf.PdfGraphics graphics, Size pageSize, pdf.PdfFont font,
      pdf.PdfFont boldFont) {
    const double cmToPoints = 28.35;
    const double bottomOffset = 30 + cmToPoints;

    final headerRowHeight = _config.rowHeights['header']!;
    final deptRowHeight = _config.rowHeights['department']!;
    final selloRowHeight = _config.rowHeights['stamp']!;
    final firmaRowHeight = _config.rowHeights['signature']!;
    final dateRowHeight = _config.rowHeights['date']!;

    final double footerHeight =
        headerRowHeight + deptRowHeight + selloRowHeight + firmaRowHeight + dateRowHeight;
    final double footerY = pageSize.height - footerHeight - bottomOffset;

    final pdf.PdfPen pen = pdf.PdfPen(pdf.PdfColor(0, 0, 0), width: 0.5);
    final double footerWidth = pageSize.width - 40;

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
    currentY += selloRowHeight;
    graphics.drawLine(pen, Offset(20, currentY + firmaRowHeight),
        Offset(20 + footerWidth, currentY + firmaRowHeight));

    double currentX = 20;
    for (int i = 0; i < _config.departments.length; i++) {
      final dept = _config.departments[i];
      final colWidth = footerWidth * (dept['width'] / 100);
      if (i < _config.departments.length - 1) {
        currentX += colWidth;
        graphics.drawLine(pen, Offset(currentX, footerY + headerRowHeight),
            Offset(currentX, footerY + footerHeight));
      }
    }

    _drawCellText(graphics, 'DEPARTAMENTOS', boldFont, 20, footerWidth, footerY,
        headerRowHeight);

    currentX = 20;
    for (final dept in _config.departments) {
      final colWidth = footerWidth * (dept['width'] / 100);
      _drawCellText(graphics, dept['name'], font, currentX, colWidth,
          footerY + headerRowHeight, deptRowHeight);
      currentX += colWidth;
    }

    final selloY = footerY + headerRowHeight + deptRowHeight;
    currentX = 20;
    for (final dept in _config.departments) {
      final colWidth = footerWidth * (dept['width'] / 100);
      final font = pdf.PdfStandardFont(pdf.PdfFontFamily.helvetica, dept['stamp_font_size']);
      _drawCellText(
          graphics, dept['stamp_text'] ?? '', font, currentX, colWidth, selloY, selloRowHeight,
          alignment: pdf.PdfTextAlignment.left, vAlignment: pdf.PdfVerticalAlignment.top);
      currentX += colWidth;
    }

    final firmaY = selloY + selloRowHeight;
    currentX = 20;
    for (final dept in _config.departments) {
      final colWidth = footerWidth * (dept['width'] / 100);
      final font = pdf.PdfStandardFont(pdf.PdfFontFamily.helvetica, dept['signature_font_size']);
      _drawCellText(
          graphics, dept['signature_text'] ?? '', font, currentX, colWidth, firmaY, firmaRowHeight,
          alignment: pdf.PdfTextAlignment.left, vAlignment: pdf.PdfVerticalAlignment.top);
      currentX += colWidth;
    }

    final dateY = firmaY + firmaRowHeight;
    currentX = 20;
    for (final dept in _config.departments) {
      final colWidth = footerWidth * (dept['width'] / 100);
      final font = pdf.PdfStandardFont(pdf.PdfFontFamily.helvetica, dept['date_font_size']);
      _drawCellText(
          graphics, dept['date_text'] ?? '', font, currentX, colWidth, dateY, dateRowHeight,
          alignment: pdf.PdfTextAlignment.left, vAlignment: pdf.PdfVerticalAlignment.top);
      currentX += colWidth;
    }
  }

  void _drawCellText(pdf.PdfGraphics graphics, String text, pdf.PdfFont font,
      double cellX, double cellWidth, double cellY, double cellHeight,
      {pdf.PdfTextAlignment alignment = pdf.PdfTextAlignment.center,
      pdf.PdfVerticalAlignment vAlignment = pdf.PdfVerticalAlignment.middle}) {
    double hPadding = 2;
    double vPadding = 2;

    final processedText = text.replaceAll('\t', '    ');

    Rect cellBounds = Rect.fromLTWH(cellX, cellY, cellWidth, cellHeight);

    Rect paddedBounds = Rect.fromLTWH(cellBounds.left + hPadding, cellBounds.top + vPadding,
        cellBounds.width - (hPadding * 2), cellBounds.height - (vPadding * 2));

    graphics.drawString(processedText, font,
        bounds: paddedBounds,
        format: pdf.PdfStringFormat(alignment: alignment, lineAlignment: vAlignment));
  }

  void _openConfigScreen() async {
    final passwordController = TextEditingController();
    final isPasswordCorrect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contraseña'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Introduce la contraseña'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final isCorrect = await _configService.checkPassword(passwordController.text);
              if (mounted) Navigator.of(context).pop(isCorrect);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (isPasswordCorrect == true) {
      final result = await Navigator.of(context).push<ConfigModel>(
        MaterialPageRoute(
          builder: (context) => ConfigScreen(initialConfig: _config),
        ),
      );

      if (result != null) {
        setState(() {
          _config = result;
        });
        await _configService.saveConfig(_config);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuración guardada')),
          );
        }
      }
    } else if (isPasswordCorrect != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña incorrecta')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Pie de Página a PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openConfigScreen,
          ),
        ],
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
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
