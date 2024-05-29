import 'dart:async';
import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:mdl_scan/qrcode_scan_view.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String? status;

  StreamSubscription<List<ScanResult>>? subscription;

  bool isScanning = false;
  bool isConnecting = false;
  String? qrCodeData;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Scan QR Code'),
              ),
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/scan');
                    },
                    child: const Text('Scan QR Code'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (isScanning) ...[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(
                          width: 8,
                        ),
                        Text('Scanning for bluetooth devices...'),
                      ],
                    )
                  ] else if (isConnecting) ...[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(
                          width: 8,
                        ),
                        Text('Connecting ...'),
                      ],
                    )
                  ] else ...[
                    Container()
                  ],
                  if (qrCodeData != null) ...[
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('QR Code Data: $qrCodeData'),
                    ),
                  ]
                ],
              ),
            ),
        '/scan': (context) => QRCodeScanView(
              onScanResult: (data) {
                print(data);
                String base64String = data.split(':')[1];
                var decodedBytes = base64Url.decode(base64String);
                var jsonObject = cborDecode(decodedBytes).toJson();
                print(jsonObject); // Output: Hello world!

                setState(() {
                  qrCodeData = base64String;
                });
                if (Navigator.canPop(context)) Navigator.pop(context);
                if (isScanning == false) _connectToBLEDevice(qrCodeData!);
              },
            ),
      },
    );
  }

  void _connectToBLEDevice(String uuid) async {
    setState(() {
      isScanning = true;
    });
    FlutterBlue flutterBlue = FlutterBlue.instance;
    await flutterBlue.startScan(
        scanMode: ScanMode.opportunistic,
        withServices: [Guid('0000ffe0-0000-1000-8000-00805f9b34fb')]);
    // Start scanning.

    // Listen to scan results.
    subscription?.cancel();
    subscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        // Compare obtained device's id with given uuid.

        setState(() {
          isScanning = false;
          isConnecting = true;
        });
        print("Device found. Trying to connect...");

        // Connect to device.
        result.device.connect(autoConnect: false).then((_) {
          setState(() {
            isConnecting = false;
            isScanning = false;
          });
          flutterBlue.stopScan();

          print("Connected to the device");
          result.device.discoverServices().then((services) {
            for (var service in services) {
              print("Service: ${service.uuid}");
              for (var characteristic in service.characteristics) {
                print("Characteristic: ${characteristic.uuid}");

                characteristic.read().then((value) {
                  print("Value: $value");
                  if (value.isNotEmpty) {
                    CborValue cborValue = cborDecode(value);
                    cborValue.toJson();
                    print("Decoded value: ${cborValue.toJson()}");
                  }
                });
              }
            }
          });
          subscription?.cancel();
        });
      }
    });

    // Stop scanning after a certain time period.
    Future.delayed(const Duration(seconds: 5))
        .then((_) => flutterBlue.stopScan());
  }
}
