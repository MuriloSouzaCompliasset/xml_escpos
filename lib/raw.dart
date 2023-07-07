import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class RawPrinter {
  final String printerName;
  final Arena alloc;

  RawPrinter(this.printerName, this.alloc);

  Pointer<HANDLE> _startRawPrintJob(
      {required String printerName,
      required String documentTitle,
      String dataType = 'RAW'}) {
    final pPrinterName = printerName.toNativeUtf16(allocator: alloc);
    final phPrinter = alloc<HANDLE>();

    var fSuccess = OpenPrinter(pPrinterName, phPrinter, nullptr);
    if (fSuccess == 0) {
      final error = GetLastError();
      throw Exception('OpenPrint error, status: $fSuccess, error: $error');
    }

    final pDocInfo = alloc<DOC_INFO_1>()
      ..ref.pDocName = printerName.toNativeUtf16(allocator: alloc)
      ..ref.pDatatype = dataType.toNativeUtf16(allocator: alloc)
      ..ref.pOutputFile = nullptr;

    fSuccess = StartDocPrinter(phPrinter.value, 1, pDocInfo);
    if (fSuccess == 0) {
      final error = GetLastError();
      throw Exception(
          'StartDocPrinter error, status: $fSuccess, error: $error');
    }

    return phPrinter;
  }

  bool _startRawPrintPage(Pointer<HANDLE> phPrinter) {
    return StartPagePrinter(phPrinter.value) != 0;
  }

  bool _endRawPrintPage(Pointer<HANDLE> phPrinter) {
    return EndPagePrinter(phPrinter.value) != 0;
  }

  bool _endRawPrintJob(Pointer<HANDLE> phPrinter) {
    return EndDocPrinter(phPrinter.value) > 0 &&
        ClosePrinter(phPrinter.value) != 0;
  }

  bool _printRawData(Pointer<HANDLE> phPrinter, List<int> dataToPrint) {
    final cWritten = alloc<DWORD>();
    final data = calloc<Int8>(dataToPrint.length);

    for (var i = 0; i < dataToPrint.length; i++) {
      data.elementAt(i).value = dataToPrint[i];
    }
    final result =
        WritePrinter(phPrinter.value, data, dataToPrint.length, cWritten);
    calloc.free(data);
    if (dataToPrint.length != cWritten.value) {
      final error = GetLastError();
      throw Exception('WritePrinter error, status: $result, error: $error');
    }

    return result != 0;
  }

  bool printLines(List<List<int>> data) {
    var res = false;
    if (data.isEmpty) {
      return res;
    }
    final printerHandle = _startRawPrintJob(
        printerName: printerName,
        documentTitle: 'My document',
        dataType: 'RAW');

    res = _startRawPrintPage(printerHandle);

    for (final item in data) {
      if (res) {
        res = _printRawData(printerHandle, item);
      }
    }
    _endRawPrintPage(printerHandle);
    _endRawPrintJob(printerHandle);

    return res;
  }
}
