import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Sellos PDF',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Sellador de PDF'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _filePath;

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
      if (_filePath != null) {
        _stampPdf(_filePath!);
      }
    }
  }

  Future<void> _stampPdf(String path) async {
    final pdfDoc = pw.Document();
    final existingPdfBytes = await File(path).readAsBytes();
    // Esta es una forma de añadir el contenido del PDF existente.
    // La biblioteca `pdf` no permite editar directamente,
    // por lo que creamos un nuevo PDF con el contenido del anterior
    // y luego le añadimos el sello.
    // Para una edición más avanzada, podrías necesitar otras herramientas.

    // A modo de ejemplo, vamos a añadir un sello de "APROBADO"
    // en la primera página de un *nuevo* documento.
    // Integrar el contenido del PDF original es más complejo y
    // puede requerir bibliotecas de pago si se necesita alta fidelidad.

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        build: (pw.Context context) {
      return pw.Center(
        child: pw.Text("Aquí iría el contenido de tu PDF original"),
      );
    }));

    // Añadimos el sello
    pdf.addPage(pw.Page(
        build: (pw.Context context) {
      return pw.Center(
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: const PdfColorGreen(), width: 2),
          ),
          child: pw.Text('APROBADO', style: pw.TextStyle(fontSize: 40, color: const PdfColorGreen())),
        ),
      );
    }));


    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/pdf_sellado.pdf');
    await outputFile.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF sellado y guardado en: ${outputFile.path}')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_filePath == null)
              const Text(
                'Selecciona un archivo PDF para sellar:',
              ),
            if (_filePath != null) ...[
              Text(
                'Archivo seleccionado:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                _filePath!,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Seleccionar PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
