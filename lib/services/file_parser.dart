import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'dart:typed_data';
import 'package:archive/archive.dart';

class FileParser {
  static Future<String> extractTextFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    final name = fileName.toLowerCase();

    if (name.endsWith('.pdf')) {
      return _extractPdfFromBytes(bytes);
    } else if (name.endsWith('.docx')) {
      return _extractDocxFromBytes(bytes);
    } else {
      throw Exception("Format file tidak didukung (gunakan PDF atau DOCX).");
    }
  }

  static Future<String> extractText(File file) async {
    final bytes = await file.readAsBytes();
    return extractTextFromBytes(bytes, file.path);
  }

  static Future<String> _extractPdfFromBytes(Uint8List bytes) async {
    final document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text.trim();
  }

  static Future<String> _extractDocxFromBytes(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    final docFile = archive.findFile('word/document.xml');
    if (docFile == null) {
      throw Exception('Dokumen DOCX tidak valid atau rusak.');
    }

    final content = String.fromCharCodes(docFile.content);
    final xml = XmlDocument.parse(content);

    final text = xml
        .findAllElements('w:t')
        .map((node) => node.innerText)
        .join(' ');
    return text.trim();
  }
}
