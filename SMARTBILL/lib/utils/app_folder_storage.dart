import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class AppFolderStorage {
  /// Returns the folder right next to the running app executable.
  ///
  /// In release:  <install_dir>/SmartBill.exe  → base = <install_dir>/
  /// In debug:    build/windows/.../runner/Debug/smartbill.exe → base = that folder
  ///
  /// All data folders are created as siblings of the executable,
  /// so paths are always relative to where the app lives.
  static Directory _getBaseDirectory() {
    // Parent of the running .exe — always relative to app location
    return File(Platform.resolvedExecutable).parent;
  }

  /// Ensures that the specified sub-folder exists under the base directory.
  static Future<Directory> _getOrCreateFolder(String folderName) async {
    final baseDir = _getBaseDirectory();
    final dir = Directory(p.join(baseDir.path, folderName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // ── Public helpers ──────────────────────────────────────────────────────

  /// Saves an Invoice PDF → <AppDir>/Invoices/
  static Future<File> saveInvoicePdf(Uint8List pdfBytes, String invoiceNo) async {
    final folder = await _getOrCreateFolder('Invoices');
    final ts    = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final clean = invoiceNo.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file  = File(p.join(folder.path, 'Invoice_${clean}_$ts.pdf'));
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  /// Saves a Report PDF → <AppDir>/Reports/
  static Future<File> saveReportPdf(Uint8List pdfBytes, String reportTitle) async {
    final folder = await _getOrCreateFolder('Reports');
    final ts    = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final clean = reportTitle.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file  = File(p.join(folder.path, '${clean}_$ts.pdf'));
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  /// Saves a Report Excel file → <AppDir>/Reports/
  static Future<File> saveReportExcel(List<int> excelBytes, String reportTitle) async {
    final folder = await _getOrCreateFolder('Reports');
    final ts    = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final clean = reportTitle.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file  = File(p.join(folder.path, '${clean}_$ts.xlsx'));
    await file.writeAsBytes(excelBytes);
    return file;
  }

  /// Saves a Graph/Chart PNG → <AppDir>/Reports/Graphs/
  static Future<File> saveGraphPng(Uint8List pngBytes, String graphName) async {
    final folder = await _getOrCreateFolder(p.join('Reports', 'Graphs'));
    final ts    = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final clean = graphName.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file  = File(p.join(folder.path, '${clean}_$ts.png'));
    await file.writeAsBytes(pngBytes);
    return file;
  }

  /// Saves a Product Management PDF → <AppDir>/Reports/Product Management/
  static Future<File> saveProductManagementPdf(Uint8List pdfBytes, String title) async {
    final folder = await _getOrCreateFolder(p.join('Reports', 'Product Management'));
    final ts    = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final clean = title.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file  = File(p.join(folder.path, '${clean}_$ts.pdf'));
    await file.writeAsBytes(pdfBytes);
    return file;
  }
}
