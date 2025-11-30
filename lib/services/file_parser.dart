import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';

class FileParser {
  static Future<String> extractText(File file) async {
    final path = file.path.toLowerCase();

    if (path.endsWith('.pdf')) {
      return _extractPdf(file);
    } else if (path.endsWith('.docx')) {
      return _extractDocx(file);
    } else {
      throw Exception("Format file tidak didukung (gunakan PDF atau DOCX).");
    }
  }

  static Future<String> _extractPdf(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text.trim();
  }

  static Future<String> _extractDocx(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final docFile = archive.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => throw Exception('Dokumen rusak atau tidak valid'),
    );
    final xml = XmlDocument.parse(String.fromCharCodes(docFile.content));
    final text = xml.findAllElements('w:t').map((node) => node.text).join(' ');
    return text.trim();
  }
}
