import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
class PDFViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String kitapAdi; 

  const PDFViewerPage({super.key, required this.pdfUrl, required this.kitapAdi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kitapAdi), 
      ),
      body: FutureBuilder<String>(
        future: _loadPdfFromUrl(pdfUrl), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            return PDFView(
              filePath: snapshot.data, 
            );
          } else {
            return const Center(child: Text("PDF yüklenemedi."));
          }
        },
      ),
    );
  }

  Future<String> _loadPdfFromUrl(String url) async {
    try {
      print("PDF yükleniyor: $url"); 
      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      print("PDF yüklendi: ${response.data.length} byte"); 
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/temp_pdf.pdf");
      await file.writeAsBytes(response.data);
      return file.path;
    } catch (e) {
      print("Hata: $e"); 
      throw Exception("PDF yüklenemedi: $e");
    }
  }
}
