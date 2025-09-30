import 'dart:io';
import 'dart:ui' show Rect; // Especificar Rect para evitar conflictos
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:pdfx/pdfx.dart' as pdfx; // Para renderizar PDF a imagen
import 'package:image/image.dart' as img; // Para procesar la imagen

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

      for (int i = document.pages.count - 1; i >= 0; i--) {
        final page = document.pages[i];
        if (await _isAreaOccupied(filePath, i + 1, page.size)) {
          final PdfPage newPage = document.pages.insert(i + 1, page.size);
          _drawFooter(newPage.graphics, newPage.getClientSize(), font, boldFont);
        } else {
          _drawFooter(page.graphics, page.getClientSize(), font, boldFont);
        }
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
  
  Rect _getFooterBounds(SizeF pageSize) {
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

  Future<bool> _isAreaOccupied(String filePath, int pageNumber, SizeF pageSize) async {
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

  void _drawFooter(PdfGraphics graphics, SizeF pageSize, PdfFont font,
      PdfFont boldFont) {
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

    final PdfPen pen = PdfPen(PdfColor(0, 0, 0), width: 0.5);
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
      final font = PdfStandardFont(PdfFontFamily.helvetica, dept['stamp_font_size']);
      _drawCellText(
          graphics, dept['stamp_text'] ?? '', font, currentX, colWidth, selloY, selloRowHeight,
          alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);
      currentX += colWidth;
    }

    final firmaY = selloY + selloRowHeight;
    currentX = 20;
    for (final dept in _config.departments) {
      final colWidth = footerWidth * (dept['width'] / 100);
      final font = PdfStandardFont(PdfFontFamily.helvetica, dept['signature_font_size']);
      _drawCellText(
          graphics, dept['signature_text'] ?? '', font, currentX, colWidth, firmaY, firmaRowHeight,
          alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);
      currentX += colWidth;
    }

    final dateY = firmaY + firmaRowHeight;
    currentX = 20;
    for (final dept in _config.departments) {
      final colWidth = footerWidth * (dept['width'] / 100);
      final font = PdfStandardFont(PdfFontFamily.helvetica, dept['date_font_size']);
      _drawCellText(
          graphics, dept['date_text'] ?? '', font, currentX, colWidth, dateY, dateRowHeight,
          alignment: PdfTextAlignment.left, vAlignment: PdfVerticalAlignment.top);
      currentX += colWidth;
    }
  }

  void _drawCellText(PdfGraphics graphics, String text, PdfFont font,
      double cellX, double cellWidth, double cellY, double cellHeight,
      {PdfTextAlignment alignment = PdfTextAlignment.center,
       PdfVerticalAlignment vAlignment = PdfVerticalAlignment.middle}) {

    double hPadding = 2;
    double vPadding = 2;

    final processedText = text.replaceAll('\t', '    ');

    Rect cellBounds = Rect.fromLTWH(cellX, cellY, cellWidth, cellHeight);

    Rect paddedBounds = Rect.fromLTWH(
        cellBounds.left + hPadding,
        cellBounds.top + vPadding,
        cellBounds.width - (hPadding * 2),
        cellBounds.height - (vPadding * 2));

    graphics.drawString(processedText, font,
        bounds: paddedBounds,
        format: PdfStringFormat(
            alignment: alignment,
            lineAlignment: vAlignment));
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
              if(mounted) Navigator.of(context).pop(isCorrect);
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
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuración guardada')),
          );
        }
      }
    } else if (isPasswordCorrect != null) {
      if(mounted) {
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
