import 'dart:async';

import 'package:network_tools/network_tools.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import 'network_tools_test_util.dart';

void main() {
  final List<ActiveHost> hostsWithOpenPort = [];
  // Fetching interfaceIp and hostIp
  setUpAll(() async {
    final interfaceList =
        await NetworkInterface.list(); //will give interface list
    if (interfaceList.isNotEmpty) {
      final localInterface =
          interfaceList.elementAt(0); //fetching first interface like en0/eth0
      if (localInterface.addresses.isNotEmpty) {
        final address = localInterface.addresses
            .elementAt(0)
            .address; //gives IP address of GHA local machine.
        final interfaceIp = address.substring(0, address.lastIndexOf('.'));
        //ssh should be running at least in any host
        await for (final host
            in HostScanner.scanDevicesForSinglePort(interfaceIp, testPort)) {
          hostsWithOpenPort.add(host);
        }
      }
    }
  });

  group('Testing Port Scanner', () {
    test('Running scanPortsForSingleDevice tests', () {
      for (final activeHost in hostsWithOpenPort) {
        expectLater(
          PortScanner.scanPortsForSingleDevice(activeHost.address),
          emits(
            isA<ActiveHost>().having(
              (p0) => p0.openPorts.contains(OpenPort(testPort)),
              "Should match host having same open port",
              equals(true),
            ),
          ),
        );
      }
    });

    test('Running connectToPort tests', () {
      for (final activeHost in hostsWithOpenPort) {
        expectLater(
          PortScanner.connectToPort(
            address: activeHost.address,
            port: testPort,
            timeout: const Duration(seconds: 5),
            activeHostsController: StreamController<ActiveHost>(),
          ),
          completion(
            isA<ActiveHost>().having(
              (p0) => p0.openPorts.contains(OpenPort(testPort)),
              "Should match host having same open port",
              equals(true),
            ),
          ),
        );
      }
    });
    test('Running customDiscover tests', () {
      for (final activeHost in hostsWithOpenPort) {
        expectLater(
          PortScanner.customDiscover(activeHost.address),
          emits(isA<ActiveHost>()),
        );
      }
    });

    test('Running customDiscover tests', () {
      for (final activeHost in hostsWithOpenPort) {
        expectLater(
          PortScanner.isOpen(activeHost.address, testPort),
          completion(
            isA<ActiveHost>().having(
              (p0) => p0.openPorts.contains(OpenPort(testPort)),
              "Should match host having same open port",
              equals(true),
            ),
          ),
        );
      }
    });
  });
}
