import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:network_tools/src/models/arp_data.dart';

class ARPTable {
  static final arpLogger = Logger("arp-table-logger");
  static final arpTable = <String, ARPData>{};
  static bool resolved = false;

  static Future<ARPData?> entryFor(String address) async {
    if (resolved) return arpTable[address];
    final result = await Process.run('arp', ['-a']);
    final entries = const LineSplitter().convert(result.stdout.toString());
    RegExp? pattern;
    if (Platform.isMacOS) {
      pattern = RegExp(
        r'(?<host>[\w.?]*)\s\((?<ip>.*)\)\sat\s(?<mac>.*)\son\s(?<intf>\w+)\sifscope\s*(\w*)\s*\[(?<typ>.*)\]',
      );
    } else if (Platform.isLinux) {
      pattern = RegExp(
        r'(?<host>[\w.?]*)\s\((?<ip>.*)\)\sat\s(?<mac>.*)\s\[(?<typ>.*)\]\son\s(?<intf>\w+)',
      );
    } else {
      pattern = RegExp(r'(?<ip>.*)\s(?<mac>.*)\s(?<typ>.*)');
    }

    for (final entry in entries) {
      final match = pattern.firstMatch(entry);
      if (match != null) {
        final arpData = ARPData(
          host: match.groupNames.contains('host')
              ? match.namedGroup("host")
              : null,
          iPAddress: match.namedGroup("ip"),
          macAddress: match.namedGroup("mac"),
          interfaceName: match.groupNames.contains('intf')
              ? match.namedGroup("intf")
              : null,
          interfaceType: match.namedGroup("typ"),
        );
        final key = arpData.iPAddress;
        if (key != null) {
          arpLogger.fine("Adding entry to table -> $arpData");
          arpTable[key] = arpData;
        }
      }
    }
    resolved = true;
    return arpTable[address];
  }
}
