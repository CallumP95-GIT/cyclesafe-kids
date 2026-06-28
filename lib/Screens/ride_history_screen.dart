import 'package:flutter/material.dart';
import '../services/ride_service.dart';

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
        itemCount: RideService.instance.rideHistory.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(
                "Ride ${index + 1}",
              ),
              subtitle: Text(
                RideService.instance.rideHistory[index],
              ),
            ),
          );
        },
      ),
    );
  }
}