import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const CycleSafeKidsApp());
}

String currentLocation = "Unknown";
String emergencyLink = "";

double riderLatitude = 53.800229;
double riderLongitude = -2.997749;
double riderSpeed = 0.0;
double riderDistance = 0.0;
double riderMaxSpeed = 0.0;
double riderAverageSpeed = 0.0;
List<String> rideHistory = [];
String riderStatus = "Stopped";
String riderRideTime = "00:00:00";
bool crashDetected = false;
int sosCountdown = 15;
bool sosTriggered = false;

Future<void> sendLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    return;
  }

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  Position position = await Geolocator.getCurrentPosition();

  riderLatitude = position.latitude;
  riderLongitude = position.longitude;

  currentLocation =
      "Lat: ${position.latitude}\nLon: ${position.longitude}";
      emergencyLink =
    "https://maps.google.com/?q=${position.latitude},${position.longitude}";
}

Future<void> shareLocation() async {
  await sendLocation();

  String message =
      "🚴 I'm cycling.\n\n"
      "My location:\n"
      "https://maps.google.com/?q=$riderLatitude,$riderLongitude";

  Share.share(message);
}

Future<void> callMum() async {
  final Uri phone = Uri(
    scheme: 'tel',
    path: '07123456789',
  );

  await launchUrl(phone);
}

Future<void> callDad() async {
  final Uri phone = Uri(
    scheme: 'tel',
    path: '07987654321',
  );

  await launchUrl(phone);
}

class CycleSafeKidsApp extends StatelessWidget {
  const CycleSafeKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CycleSafe Kids',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.green,
  scaffoldBackgroundColor: Colors.grey.shade100,

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
  ),

  cardTheme: CardThemeData(
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
),
      home: const HomeScreen(),
    );
  }
}
class RideScreen extends StatefulWidget {
  const RideScreen({super.key});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  int seconds = 0;
Timer? timer;
Timer? sosTimer;

double latitude = riderLatitude;
double longitude = riderLongitude;

double speed = 0.0;
double maxSpeed = 0.0;
double distance = 0.0;

Position? previousPosition;

StreamSubscription<Position>? positionStream;
void startSOSCountdown() {
  if (sosTimer != null) return;

  sosCountdown = 15;

  sosTimer = Timer.periodic(
    const Duration(seconds: 1),
    (timer) {
      setState(() {
        sosCountdown--;

        if (sosCountdown <= 0) {
  sosTriggered = true;

  emergencyLink =
      "https://maps.google.com/?q=$latitude,$longitude";

  timer.cancel();
}
      });
    },
  );
}

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          seconds++;
        });
      },
    );

    positionStream = Geolocator.getPositionStream().listen(
  (Position position) {
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;

      riderLatitude = latitude;
      riderLongitude = longitude;

      speed = position.speed * 3.6;
if (speed > 1) {
  riderStatus = "Riding";
} else {
  riderStatus = "Stopped";
}
if (riderStatus == "Riding" && speed < 1) {
  crashDetected = true;

  if (sosTimer == null) {
    startSOSCountdown();
  }
}

      if (speed > maxSpeed) {
        maxSpeed = speed;
      }
      riderSpeed = speed;
riderMaxSpeed = maxSpeed;
if (seconds > 0) {
  riderAverageSpeed =
      riderDistance / (seconds / 3600);
}

      if (previousPosition != null) {
        distance += Geolocator.distanceBetween(
              previousPosition!.latitude,
              previousPosition!.longitude,
              position.latitude,
              position.longitude,
            ) /
            1000;
      }
riderDistance = distance;

      previousPosition = position;
    });
  },
);
  }

  @override
  void dispose() {
    timer?.cancel();
    positionStream?.cancel();
    super.dispose();
  }

  String get formattedTime {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

riderRideTime =
    "${hours.toString().padLeft(2, '0')}:"
    "${minutes.toString().padLeft(2, '0')}:"
    "${secs.toString().padLeft(2, '0')}";

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    LatLng currentPosition = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride Mode"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
  child: Column(
    children: [
          const SizedBox(height: 20),

          Container(
  margin: const EdgeInsets.all(15),
  padding: const EdgeInsets.all(25),
  decoration: BoxDecoration(
    color: Colors.green,
    borderRadius: BorderRadius.circular(30),
  ),
  child: Column(
    children: [
      const Text(
        "RIDE TIME",
        style: TextStyle(
          color: Colors.white70,
          letterSpacing: 2,
        ),
      ),

      const SizedBox(height: 10),

      Text(
        formattedTime,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),
if (crashDetected)
  Card(
    
    color: Colors.red,
    child: ListTile(
      leading: const Icon(
        Icons.warning,
        color: Colors.white,
      ),
      title: const Text(
        "Possible Crash Detected",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        "Sending SOS in $sosCountdown seconds",
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      trailing: ElevatedButton(
        onPressed: () {
          setState(() {
            crashDetected = false;
            sosTriggered = false;
            sosCountdown = 15;

            sosTimer?.cancel();
            sosTimer = null;
          });
        },
        child: const Text("I'm OK"),
      ),
    ),
  ),
  if (sosTriggered)
   Card(
    color: Colors.orange,
    child: ListTile(
      leading: Icon(
        Icons.phone,
        color: Colors.white,
      ),
      title: Text(
        "SOS Triggered",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
  emergencyLink,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    ),
  ),
            
const SizedBox(height: 20),

Card(
  child: ListTile(
    leading: const Icon(Icons.speed),
    title: const Text("Speed"),
    subtitle: Text(
      "${speed.toStringAsFixed(1)} km/h",
    ),
  ),
),

Card(
  child: ListTile(
    leading: const Icon(Icons.straighten),
    title: const Text("Distance"),
    subtitle: Text(
      "${distance.toStringAsFixed(2)} km",
    ),
  ),
),

Card(
  child: ListTile(
    leading: const Icon(Icons.trending_up),
    title: const Text("Max Speed"),
    subtitle: Text(
      "${maxSpeed.toStringAsFixed(1)} km/h",
    ),
  ),
),

const SizedBox(height: 20),
          const SizedBox(height: 20),
Container(
  height: 400,
  margin: const EdgeInsets.all(15),
  clipBehavior: Clip.hardEdge,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(25),
    border: Border.all(
      color: Colors.blue,
      width: 3,
    ),
    boxShadow: const [
      BoxShadow(
        blurRadius: 10,
        color: Colors.black26,
      ),
    ],
  ),
  child: FlutterMap(
              options: MapOptions(
                initialCenter: currentPosition,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cyclesafe_kids',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPosition,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.directions_bike,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 10,
      backgroundColor: Colors.orange,
      minimumSize: const Size(
        double.infinity,
        80,
      ),
    ),
    onPressed: () {
      setState(() {
        crashDetected = true;
        startSOSCountdown();
      });
    },
    icon: const Icon(Icons.warning),
    label: const Text(
      "Test Crash",
      style: TextStyle(fontSize: 24),
    ),
  ),
),

const SizedBox(height: 15),

Padding(
  padding: const EdgeInsets.all(20),
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      minimumSize: const Size(
        double.infinity,
        80,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 10,
    ),
    onPressed: () {
      rideHistory.add(
        "Distance: ${distance.toStringAsFixed(2)} km\n"
        "Duration: $formattedTime\n"
        "Average Speed: ${riderAverageSpeed.toStringAsFixed(1)} km/h\n"
        "Maximum Speed: ${maxSpeed.toStringAsFixed(1)} km/h",
      );

      Navigator.pop(context);
    },
    icon: const Icon(Icons.stop),
    label: const Text(
      "Stop Ride",
      style: TextStyle(fontSize: 24),
    ),
  ),
),

        ],
      ),
    ),
  );
}
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget buildButton(
    IconData icon,
    String text,
    Color color,
    BuildContext context,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 85,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(25),
),
          backgroundColor: color,
          textStyle: const TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
),
        ),
        icon: Icon(icon, size: 32),
        label: Text(text),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CycleSafe Kids"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
          children: [
            const SizedBox(height: 20),

Icon(
  Icons.directions_bike,
  size: 90,
  color: Colors.green,
),

SizedBox(height: 10),

Text(
  "CycleSafe Kids",
  style: TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: Colors.green.shade800,
  ),
),

Text(
  "Ride Smart • Ride Safe",
  style: TextStyle(
    fontSize: 18,
    color: Colors.grey,
  ),
),

SizedBox(height: 30),
            const SizedBox(height: 20),

            // Start Ride
            buildButton(
              Icons.directions_bike,
              "Start Ride",
              Colors.green,
              context,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RideScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // My Location
buildButton(
  Icons.location_on,
  "My Location",
  Colors.blue,
  context,
  () async {
    await sendLocation();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(currentLocation),
      ),
    );
  },
),

const SizedBox(height: 15),

// Bike Connection
buildButton(
  Icons.bluetooth,
  "Bike Connection",
  const Color.fromARGB(255, 104, 163, 211),
  context,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BikeConnectionScreen(),
      ),
    );
  },
),

const SizedBox(height: 15),

// Parent Dashboard
buildButton(
              Icons.family_restroom,
              "Parent Dashboard",
              Colors.orange,
              context,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParentScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // SOS
            buildButton(
              Icons.warning,
              "SOS",
              Colors.red,
              context,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SOSScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

          buildButton(
  Icons.history,
  "Ride History",
  Colors.grey,
  context,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RideHistoryScreen(),
      ),
    );
  },
),
            
                   ],
        ),
      ),
    ),
  );
}
}

class SOSScreen extends StatelessWidget {
  const SOSScreen({super.key});

  Widget emergencyButton(
    IconData icon,
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          textStyle: const TextStyle(fontSize: 22),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 32),
        label: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "🚨 EMERGENCY 🚨",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 40),

            emergencyButton(
              Icons.phone,
              "Call Mum",
              Colors.green,
              () {
                callMum();
              },
            ),

            const SizedBox(height: 15),

            emergencyButton(
              Icons.phone,
              "Call Dad",
              Colors.blue,
              () {
                callDad();
              },
            ),

            const SizedBox(height: 15),

            emergencyButton(
              Icons.location_on,
              "Send My Location",
              Colors.orange,
              () async {
                try {
                  await shareLocation();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Unable to share location\n$e"),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 15),

            emergencyButton(
              Icons.check_circle,
              "I'm Safe",
              Colors.teal,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("I'm Safe"),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            emergencyButton(
              Icons.cancel,
              "Cancel",
              Colors.grey,
              () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    LatLng riderPosition = LatLng(
      riderLatitude,
      riderLongitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parent Dashboard"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(15),
    child: Column(
      children: [
            const SizedBox(height: 10),

            const Text(
              "🚴 Rider Status",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
const SizedBox(height: 20),

Card(
  child: ListTile(
    leading: const Icon(Icons.directions_bike),
    title: const Text("Ride Status"),
    subtitle: Text(riderStatus),
  ),
),

Card(
  child: ListTile(
    leading: const Icon(Icons.timer),
    title: const Text("Ride Duration"),
    subtitle: Text(riderRideTime),
  ),
),

Card(
  child: ListTile(
    leading: const Icon(Icons.star),
    title: const Text("Average Speed"),
    subtitle: Text(
      "${riderAverageSpeed.toStringAsFixed(1)} km/h",
    ),
  ),
),

            const SizedBox(height: 20),

            Card(
              color: Colors.green.shade100,
              child: ListTile(
                leading: const Icon(
  Icons.speed,
  size: 35,
),
                title: const Text("Current Speed"),
                subtitle: Text(
                  "${riderSpeed.toStringAsFixed(1)} km/h",
                ),
              ),
            ),

            Card(
              color: Colors.blue.shade100,
              child: ListTile(
                leading: const Icon(
  Icons.straighten,
  size: 35,
),
                title: const Text("Distance Travelled"),
                subtitle: Text(
                  "${riderDistance.toStringAsFixed(2)} km",
                ),
              ),
            ),

            Card(
              color: Colors.orange.shade100,
              child: ListTile(
                leading: const Icon(
  Icons.trending_up,
  size: 35,
),
                title: const Text("Maximum Speed"),
                subtitle: Text(
                  "${riderMaxSpeed.toStringAsFixed(1)} km/h",
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text("Current Location"),
                subtitle: Text(currentLocation),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 350,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: riderPosition,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.example.cyclesafe_kids',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: riderPosition,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.directions_bike,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
                ],
    ),
  ),
),
);
  }
}

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride History"),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: rideHistory.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(
                "Ride ${index + 1}",
              ),
              subtitle: Text(
                rideHistory[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BikeConnectionScreen extends StatefulWidget {
  const BikeConnectionScreen({super.key});

  @override
  State<BikeConnectionScreen> createState() =>
      _BikeConnectionScreenState();
}

class _BikeConnectionScreenState
    extends State<BikeConnectionScreen> {

bool isScanning = false;

String connectionStatus = "Disconnected";

String bikeName = "No Bike Connected";

String batteryLevel = "--%";

String signalStrength = "--";

String firmwareVersion = "--";

List<ScanResult> scanResults = [];

StreamSubscription<List<ScanResult>>? scanSubscription;

Future<void> startScan() async {
  print("Bluetooth Supported: ${await FlutterBluePlus.isSupported}");

  BluetoothAdapterState state =
      await FlutterBluePlus.adapterState.first;

  print("Adapter State: $state");

  if (state != BluetoothAdapterState.on) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Bluetooth is $state"),
      ),
    );
    return;
  }

  // keep the rest of your existing startScan() code below here...

  setState(() {
    isScanning = true;
    scanResults.clear();
  });

  try {
    scanSubscription =
    FlutterBluePlus.onScanResults.listen((results) {

  debugPrint("Devices found: ${results.length}");

  for (final r in results) {
    debugPrint(
      "${r.device.platformName} - ${r.device.remoteId.str}",
    );
  }

  setState(() {
    scanResults = results;
  });
});

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );
    debugPrint("Scan started");

    await Future.delayed(const Duration(seconds: 5));

    await FlutterBluePlus.stopScan();
  } catch (e, stackTrace) {
  debugPrint("Bluetooth Error: $e");
  debugPrintStack(stackTrace: stackTrace);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Bluetooth error: $e"),
    ),
  );
  } finally {
    setState(() {
      isScanning = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
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
                color: Colors.red.shade100,
                child:  ListTile(
                  leading: Icon(
                    Icons.bluetooth_disabled,
                    color: Colors.red,
                  ),
                  title: Text("Status"),
                 subtitle: Text(connectionStatus),
                ),
              ),

              const SizedBox(height: 15),

               Card(
                child: ListTile(
                  leading: Icon(Icons.memory),
                  title: Text("Device"),
                  subtitle: Text(bikeName),
                ),
              ),

              const Card(
                child: ListTile(
                  leading: Icon(Icons.battery_full),
                  title: Text("Battery"),
                  subtitle: Text("--%"),
                ),
              ),

              const Card(
                child: ListTile(
                  leading: Icon(Icons.network_cell),
                  title: Text("Signal"),
                  subtitle: Text("--"),
                ),
              ),

              const Card(
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text("Firmware"),
                  subtitle: Text("--"),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    minimumSize: const Size(double.infinity, 70),
  ),
  
  onPressed: isScanning
      ? null
      : () async {
          await startScan();
        },
  icon: const Icon(Icons.search),
  label: Text(
    isScanning ? "Scanning..." : "Scan for Bike",
    style: const TextStyle(fontSize: 22),
  ),
),
const SizedBox(height: 20),

if (scanResults.isEmpty)
  const Text(
    "No Bluetooth devices found",
    style: TextStyle(color: Colors.grey),
  ),
  
  Text(
  "Devices found: ${scanResults.length}",
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

...scanResults.map(
  (result) => Card(
    child: ListTile(
      leading: const Icon(Icons.bluetooth),

      title: Text(
        result.advertisementData.advName.isNotEmpty
            ? result.advertisementData.advName
            : "Unknown Device",
      ),

      subtitle: Text(result.device.remoteId.str),

      trailing: const Icon(Icons.chevron_right),

      onTap: () async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Connecting..."),
        duration: Duration(seconds: 1),
      ),
    );

    await FlutterBluePlus.stopScan();

    await result.device.connect(
      timeout: const Duration(seconds: 10),
    );

    setState(() {
      connectionStatus = "Connected";

      bikeName = result.advertisementData.advName.isNotEmpty
          ? result.advertisementData.advName
          : result.device.remoteId.str;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Connected to $bikeName"),
      ),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Connection failed: $e"),
      ),
    );
  }
},
    ),
  ),
),
            ],
          ),
        ),
      ),
    );
  }
}