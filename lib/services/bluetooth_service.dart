import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BikeBluetoothService extends ChangeNotifier {
  static final BikeBluetoothService instance =
      BikeBluetoothService._internal();

  BikeBluetoothService._internal();

  BluetoothDevice? connectedDevice;
  BluetoothDevice? lastConnectedDevice;

  StreamSubscription<BluetoothConnectionState>? connectionSubscription;

  bool isConnected = false;

  String bikeName = "No Bike Connected";

  String batteryLevel = "--%";

  String firmwareVersion = "--";

  String signalStrength = "--";

  Future<void> connect(BluetoothDevice device) async {
    if (connectedDevice?.remoteId == device.remoteId) {
      return;
    }

    await connectionSubscription?.cancel();

    await device.connect();

    connectedDevice = device;
    lastConnectedDevice = device;

    bikeName = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.str;

    isConnected = true;

    connectionSubscription =
        device.connectionState.listen((state) {
      isConnected =
          state == BluetoothConnectionState.connected;

      if (state ==
          BluetoothConnectionState.disconnected) {
        connectedDevice = null;

        bikeName = "No Bike Connected";

        batteryLevel = "--%";

        firmwareVersion = "--";

        signalStrength = "--";
      }

      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> reconnect() async {

  if (lastConnectedDevice == null) {
    return;
  }

  try {

    await connect(lastConnectedDevice!);

  } catch (_) {

    // Ignore reconnect failures

  }

}
  Future<void> disconnect() async {
    await connectionSubscription?.cancel();

    await connectedDevice?.disconnect();

    connectionSubscription = null;

    connectedDevice = null;

    bikeName = "No Bike Connected";

    batteryLevel = "--%";

    firmwareVersion = "--";

    signalStrength = "--";

    isConnected = false;

    notifyListeners();
  }
}