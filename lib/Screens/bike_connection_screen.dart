import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/bluetooth_service.dart';

class BikeConnectionScreen extends StatefulWidget {
  const BikeConnectionScreen({super.key});

  @override
  State<BikeConnectionScreen> createState() =>
      _BikeConnectionScreenState();
}

class _BikeConnectionScreenState
    extends State<BikeConnectionScreen> {

  bool isScanning = false;

  List<ScanResult> scanResults = [];

  StreamSubscription<List<ScanResult>>? scanSubscription;

  @override
void initState() {
  super.initState();

  BikeBluetoothService.instance.addListener(_bluetoothChanged);
}

void _bluetoothChanged() {
  if (mounted) {
    setState(() {});
  }
}
  @override
void dispose() {
  BikeBluetoothService.instance.removeListener(
    _bluetoothChanged,
  );

  scanSubscription?.cancel();

  super.dispose();
}

  Future<void> startScan() async {

    Map<Permission, PermissionStatus> permissions = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (permissions[Permission.bluetoothScan] !=
        PermissionStatus.granted) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bluetooth permission denied"),
        ),
      );
      return;
    }

    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    await scanSubscription?.cancel();

    scanSubscription =
        FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;

      setState(() {
        scanResults = results;
      });
    });

    try {

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(
        const Duration(seconds: 5),
      );

      await FlutterBluePlus.stopScan();

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bluetooth error: $e"),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final bluetooth = BikeBluetoothService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bike Connection"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
                            const SizedBox(height: 20),

              const Icon(
                Icons.bluetooth_connected,
                size: 100,
                color: Colors.blue,
              ),

              const SizedBox(height: 15),

              const Text(
                "ESP32 Bike Module",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Card(
                color: bluetooth.isConnected
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: ListTile(
                  leading: Icon(
                    bluetooth.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: bluetooth.isConnected
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: const Text("Status"),
                  subtitle: Text(
                    bluetooth.isConnected
                        ? "Connected"
                        : "Disconnected",
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.memory),
                  title: const Text("Device"),
                  subtitle: Text(bluetooth.bikeName),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.battery_full),
                  title: const Text("Battery"),
                  subtitle: Text(bluetooth.batteryLevel),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.network_cell),
                  title: const Text("Signal"),
                  subtitle: Text(bluetooth.signalStrength),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text("Firmware"),
                  subtitle: Text(bluetooth.firmwareVersion),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(
                    double.infinity,
                    70,
                  ),
                ),
                onPressed: isScanning
                    ? null
                    : () async {
                        await startScan();
                      },
                icon: const Icon(Icons.search),
                label: Text(
                  isScanning
                      ? "Scanning..."
                      : "Scan for Bike",
                  style: const TextStyle(
                    fontSize: 22,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (scanResults.isEmpty)
                const Text(
                  "No Bluetooth devices found",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

              ...scanResults.map(
                (result) => Card(
                                    child: ListTile(
                    leading: const Icon(Icons.bluetooth),

                    title: Text(
                      result.device.platformName.isNotEmpty
                          ? result.device.platformName
                          : "Unknown Device",
                    ),

                    subtitle: Text(
                      result.device.remoteId.str,
                    ),

                    onTap: () async {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Connecting..."),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        await FlutterBluePlus.stopScan();

                        await BikeBluetoothService.instance.connect(
                          result.device,
                        );

                        if (!mounted) return;

                        setState(() {});

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Connected to ${BikeBluetoothService.instance.bikeName}",
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Connection failed: $e",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ).toList(),
            ],
          ),
        ),
      ),
    );
  }
}