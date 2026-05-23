import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// 🔥 STREAM: TRIPS COLLECTION
  Stream<QuerySnapshot> getTripsStream() {
    return firestore.collection("trips").snapshots();
  }

  /// 🧮 TOTAL PASSENGERS
  int calculateTotalPassengers(List<QueryDocumentSnapshot> docs) {
    int total = 0;
    for (var doc in docs) {
      total += (doc["passenger_count"] ?? 0) as int;
    }
    return total;
  }

  /// 🚌 ACTIVE TRIPS
  int countActiveTrips(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) => doc["status"] == "active").length;
  }

  /// 🟡 DELAYED TRIPS
  int countDelayedTrips(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) => doc["status"] == "delayed").length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Real-Time Analytics"),
        backgroundColor: Colors.blueAccent,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: getTripsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No data found"));
          }

          final docs = snapshot.data!.docs;

          final totalPassengers = calculateTotalPassengers(docs);
          final activeTrips = countActiveTrips(docs);
          final delayedTrips = countDelayedTrips(docs);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// 📊 TOP CARDS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCard("Passengers", totalPassengers.toString(), Colors.green),
                      _buildCard("Active Trips", activeTrips.toString(), Colors.blue),
                      _buildCard("Delayed", delayedTrips.toString(), Colors.red),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// 📈 PIE CHART
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: activeTrips.toDouble(),
                            title: "Active",
                            color: Colors.blue,
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: delayedTrips.toDouble(),
                            title: "Delayed",
                            color: Colors.red,
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: (docs.length - activeTrips - delayedTrips).toDouble(),
                            title: "Other",
                            color: Colors.grey,
                            radius: 60,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 📊 LIVE LIST
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Live Trip Status",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index];

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.directions_bus,
                            color: data["status"] == "delayed"
                                ? Colors.red
                                : Colors.green,
                          ),
                          title: Text("Route: ${data["route_id"]}"),
                          subtitle: Text(
                            "Passengers: ${data["passenger_count"]} | Speed: ${data["speed"] ?? 0}",
                          ),
                          trailing: Text(
                            data["status"].toString().toUpperCase(),
                            style: TextStyle(
                              color: data["status"] == "delayed"
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 📦 CARD WIDGET
  Widget _buildCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}