import 'package:flutter/foundation.dart';

class RideService extends ChangeNotifier {
  static final RideService instance = RideService._internal();

  RideService._internal();

  bool rideActive = false;

  double distance = 0;

  Duration rideDuration = Duration.zero;

  final List<String> rideHistory = [];

  void startRide() {
    rideActive = true;
    notifyListeners();
  }

  void stopRide() {
    rideActive = false;
    notifyListeners();
  }

  void addRide(String ride) {
    rideHistory.add(ride);
    notifyListeners();
  }
}