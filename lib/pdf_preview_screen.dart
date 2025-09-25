import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const PdfPreviewScreen({super.key, required this.pdfBytes});

  Future<void> _savePdf(BuildContext context) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;
      final String newFileName =
          'firmado_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File newFile = File('$path/$newFileName');
      await newFile.writeAsBytes(pdfBytes, flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF guardado en: ${newFile.path}')),
        );
        // Regresa a la pantalla principal después de guardar
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Previa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _savePdf(context),
            tooltip: 'Guardar PDF',
          )
        ],
      ),
      body: SfPdfViewer.memory(
        pdfBytes,
      ),
    );
  }
}
