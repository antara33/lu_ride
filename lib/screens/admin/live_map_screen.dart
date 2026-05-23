import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LiveMonitorScreen extends StatefulWidget {
  const LiveMonitorScreen({super.key});

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTripsStream() {
    return firestore.collection("trips").snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Bus Tracking"),
        backgroundColor: Colors.blueAccent,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: getTripsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          /// Default center (Sylhet University area type)
          final center = LatLng(24.9046, 91.8611);

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
            ),

            children: [
              /// 🗺️ MAP LAYER
              TileLayer(
                urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.lu_ride',
              ),

              /// 🚍 BUS MARKERS
              MarkerLayer(
                markers: docs.map((doc) {
                  double lat = (doc["current_lat"] ?? 24.9046).toDouble();
                  double lng = (doc["current_lng"] ?? 91.8611).toDouble();

                  String status = doc["status"] ?? "active";

                  Color color = Colors.green;

                  if (status == "delayed") {
                    color = Colors.orange;
                  } else if (status == "emergency") {
                    color = Colors.red;
                  }

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 50,
                    height: 50,
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: color,
                          size: 35,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            doc["route_id"],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}