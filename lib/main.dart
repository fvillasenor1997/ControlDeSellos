import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Necesario para Uint8List
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'stamp_model.dart';
import 'stamp_designer_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Sellos',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const StampManagementScreen(),
    );
  }
}

class StampManagementScreen extends StatefulWidget {
  const StampManagementScreen({super.key});

  @override
  _StampManagementScreenState createState() => _StampManagementScreenState();
}

class _StampManagementScreenState extends State<StampManagementScreen> {
  List<Stamp> _stamps = [];

  @override
  void initState() {
    super.initState();
    _loadStamps();
  }

  Future<void> _loadStamps() async {
    final prefs = await SharedPreferences.getInstance();
    final stampsString = prefs.getStringList('stamps') ?? [];
    setState(() {
      _stamps = stampsString.map((s) => Stamp.fromJson(json.decode(s))).toList();
    });
  }

  Future<void> _saveStamps() async {
    final prefs = await SharedPreferences.getInstance();
    final stampsString = _stamps.map((s) => json.encode(s.toJson())).toList();
    await prefs.setStringList('stamps', stampsString);
  }

  void _addOrEditStamp({Stamp? stamp, int? index}) async {
    final result = await Navigator.push<Stamp>(
      context,
      MaterialPageRoute(builder: (context) => StampDesignerScreen(stamp: stamp)),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _stamps[index] = result;
        } else {
          _stamps.add(result);
        }
      });
      _saveStamps();
    }
  }
  
  void _deleteStamp(int index) {
      setState(() {
          _stamps.removeAt(index);
      });
      _saveStamps();
  }

  Future<void> _applyStampToPdf(Stamp stamp) async {
    // 1. Seleccionar el archivo PDF
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

    // 2. Cargar el documento PDF
    File file = File(result.files.single.path!);
    final Uint8List pdfBytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

    // 3. Preparar el estilo del sello y la tabla
    final PdfColor stampColor = PdfColor(
      Color(stamp.colorValue).red,
      Color(stamp.colorValue).green,
      Color(stamp.colorValue).blue,
    );

    // 4. Recorrer cada página y agregar la tabla
    for (int i = 0; i < document.pages.count; i++) {
      final PdfPage page = document.pages[i];
      final Size pageSize = page.getClientSize();

      // Crear la tabla que se dibujará en la parte inferior
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 4); // 4 columnas para los departamentos

      // Agregar la cabecera principal
      final PdfGridRow header = grid.headers.add(1)[0];
      header.cells[0].value = 'DEPARTAMENTOS';
      header.cells[0].columnSpan = 4; // Unir las 4 celdas
      header.cells[0].style.textAlign = PdfTextAlignment.center;
      header.style.font = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

      // Agregar las cabeceras de cada departamento
      final PdfGridRow subHeader = grid.rows.add();
      subHeader.cells[0].value = 'ALMACEN';
      subHeader.cells[1].value = 'METALURGIA';
      subHeader.cells[2].value = 'CALIDAD';
      subHeader.cells[3].value = 'PRODUCCION';
      subHeader.cells[0].style.textAlign = PdfTextAlignment.center;
      subHeader.cells[1].style.textAlign = PdfTextAlignment.center;
      subHeader.cells[2].style.textAlign = PdfTextAlignment.center;
      subHeader.cells[3].style.textAlign = PdfTextAlignment.center;


      // Agregar la fila "SELLO"
      final PdfGridRow stampRow = grid.rows.add();
      stampRow.height = 40; // Altura para el sello
      for (int j = 0; j < stampRow.cells.count; j++) {
          final PdfGridCell cell = stampRow.cells[j];
          cell.stringFormat = PdfStringFormat(
              alignment: PdfTextAlignment.center,
              lineAlignment: PdfVerticalAlignment.middle,
          );
          // Dibujar el sello aquí
          final PdfTemplate stampTemplate = PdfTemplate(cell.style.cellPadding.right, 40);

          // Dibujar borde del sello
          stampTemplate.graphics.drawRectangle(
              pen: PdfPen(stampColor, width: 2),
              bounds: Rect.fromLTWH(0, 0, cell.style.cellPadding.right, 35)
          );
          // Dibujar texto del sello
          stampTemplate.graphics.drawString(
              stamp.text,
              PdfStandardFont(
                  PdfFontFamily.helvetica,
                  stamp.fontSize / 2, // Ajustar tamaño de fuente para el PDF
                  style: stamp.isBold ? PdfFontStyle.bold : PdfFontStyle.regular
              ),
              brush: PdfSolidBrush(stampColor),
              bounds: Rect.fromLTWH(0, 0, cell.style.cellPadding.right, 35),
              format: PdfStringFormat(
                  alignment: PdfTextAlignment.center,
                  lineAlignment: PdfVerticalAlignment.middle
              )
          );
          cell.value = stampTemplate;
      }


      // Agregar la fila "FIRMA"
      final PdfGridRow signRow = grid.rows.add();
      signRow.cells[0].value = 'FIRMA:';
      signRow.cells[1].value = 'FIRMA:';
      signRow.cells[2].value = 'FIRMA:';
      signRow.cells[3].value = 'FIRMA:';

      // Dibujar la tabla en la página
      grid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, pageSize.height - 100, pageSize.width, 100),
      );
    }

    // 5. Guardar el nuevo PDF
    final List<int> newPdfBytes = await document.save();
    document.dispose();

    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String newFileName = 'sellado_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File newFile = File('$path/$newFileName');
    await newFile.writeAsBytes(newPdfBytes, flush: true);

    // 6. Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF guardado en: ${newFile.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Sellos'),
      ),
      body: _stamps.isEmpty
          ? const Center(child: Text('No tienes sellos. ¡Crea uno nuevo!'))
          : ListView.builder(
              itemCount: _stamps.length,
              itemBuilder: (context, index) {
                final stamp = _stamps[index];
                return ListTile(
                  leading: Icon(
                    stamp.shape == 'circle' ? Icons.circle_outlined : Icons.crop_square,
                    color: Color(stamp.colorValue),
                  ),
                  title: Text(stamp.text),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _addOrEditStamp(stamp: stamp, index: index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteStamp(index),
                      ),
                    ],
                  ),
                  onTap: () => _applyStampToPdf(stamp),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditStamp(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
