import 'package:danfe/danfe.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'dart:io';
import 'custom_printer.dart';

class HomeController {
  Danfe? parseXml(String xml) {
    try {
      Danfe? danfe = DanfeParser.readFromString(xml);
      return danfe;
    } catch (_) {
      return null;
    }
  }

  Future<void> printDefault(
      {Danfe? danfe,
      required PaperSize paper,
      required CapabilityProfile profile}) async {
    DanfePrinter danfePrinter = DanfePrinter(paper);
    List<int> _dados = await danfePrinter.bufferDanfe(danfe, mostrarMoeda: false);
    if (Platform.isLinux) {
      File file = File('/dev/usb/lp0');
      await file.writeAsBytes(_dados);
      
      ProcessResult result = await Process.run('lp', ['-d', '/dev/usb/lp0', file.path]);
      
      if (result.exitCode == 1) {
        print('File sent to printer successfully.');
      } else {
        print('Error sending file to printer.');
        print(result.stderr);
      }
    } else if(Platform.isWindows) {
      print('plataforma não suporta');
    } else {
      print('não suporta');
    }
  }

  printCustomLayout({Danfe? danfe, required PaperSize paper, required CapabilityProfile profile}) async {
    final CustomPrinter custom = CustomPrinter(paper);
    List<int> _dados = await custom.bufferDanfe(danfe);

    if (Platform.isLinux) {
      File file = File('/dev/usb/lp0');
      await file.writeAsBytes(_dados);
      ProcessResult result = await Process.run('lp', ['-d', '/dev/usb/lp0', file.path]);
      print(result.exitCode);
      if (result.exitCode == 1) {
        print('File sent to printer successfully.');
      } else {
        print('Error sending file to printer.');
        print(result.stderr);
      }
    } else if(Platform.isWindows) {
      print('plataforma não suporta');
    } else {
      print('não suporta');
    }
  }
}
