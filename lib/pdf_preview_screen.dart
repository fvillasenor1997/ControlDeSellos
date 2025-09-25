// lib/pdf_preview_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const PdfPreviewScreen({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Previa del PDF'),
      ),
      // Usamos el widget de la librería "printing" que ya incluye
      // opciones para guardar, compartir e imprimir.
      body: PdfPreview(
        build: (format) => pdfBytes,
      ),
    );
  }
}
