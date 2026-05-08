import 'package:flutter/material.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Device Scanner'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Scan Screen Placeholder',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
