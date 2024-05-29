import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRCodeScanView extends StatefulWidget {
  const QRCodeScanView({super.key, required this.onScanResult});
  final Function(String data) onScanResult;
  @override
  State<QRCodeScanView> createState() => _QRCodeScanViewState();
}

class _QRCodeScanViewState extends State<QRCodeScanView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? barcode;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 4,
              child: QRView(
                key: qrKey,
                onQRViewCreated: (p0) {
                  controller = p0;
                  controller?.scannedDataStream.listen((event) {
                    setState(() {
                      barcode = event;
                    });
                    widget.onScanResult(barcode?.code ?? "");
                  });
                },
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close')),
            // const SizedBox(
            //   height: 10,
            // ),
            // Text(barcode != null ? 'Result: ${barcode!.code}' : '')
          ],
        ));
  }
}
