import 'package:danfe/danfe.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'dart:io';
import 'custom_printer.dart';
import 'raw.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class HomeController {
  Danfe? parseXml(String xml) {
    try {
      Danfe? danfe = DanfeParser.readFromString(xml);
      return danfe;
    } catch (_) {
      return null;
    }
  }

  printCustomLayout(
      {Danfe? danfe,
      required PaperSize paper,
      required CapabilityProfile profile}) async {
    final CustomPrinter custom = CustomPrinter(paper);
    List<int> _dados = await custom.bufferDanfe(danfe);

    if (Platform.isLinux) {
      File file = File('/dev/usb/lp0');
      await file.writeAsBytes(_dados);
      ProcessResult result =
          await Process.run('lp', ['-d', '/dev/usb/lp0', file.path]);
      print(result.exitCode);
      if (result.exitCode == 1) {
        print('File sent to printer successfully.');
      } else {
        print('Error sending file to printer.');
        print(result.stderr);
      }
    } else if (Platform.isWindows) {
      const openCashDrawer = '\x1b\x70\x00';

      using((Arena alloc) {
        final printer = RawPrinter('EPSON TM-T20 Receipt', alloc);
        final data = <String>[
          ..._dados.map((byte) => String.fromCharCode(byte)),
        ];
        if (printer.printLines(data)) {
          print('Success!');
        }
      });
    } else {
      print('não suporta');
    }
  }
}
