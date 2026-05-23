import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});

  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final TextEditingController routeNameCtrl = TextEditingController();
  final TextEditingController pickupCtrl = TextEditingController();

  String? selectedDriver;

  /// ---------------- ADD ROUTE ----------------
  Future<void> addRoute() async {
    if (routeNameCtrl.text.isEmpty) return;

    await db.collection('routes').add({
      "name": routeNameCtrl.text,
      "pickup_points": pickupCtrl.text,
      "driver_id": selectedDriver ?? "",
      "created_at": Timestamp.now(),
    });

    clearFields();
  }

  /// ---------------- UPDATE ROUTE ----------------
  Future<void> updateRoute(String id) async {
    await db.collection('routes').doc(id).update({
      "name": routeNameCtrl.text,
      "pickup_points": pickupCtrl.text,
      "driver_id": selectedDriver ?? "",
    });

    clearFields();
  }

  /// ---------------- DELETE ROUTE ----------------
  Future<void> deleteRoute(String id) async {
    await db.collection('routes').doc(id).delete();
  }

  void clearFields() {
    routeNameCtrl.clear();
    pickupCtrl.clear();
    selectedDriver = null;
    setState(() {});
  }

  /// ---------------- OPEN EDIT DIALOG ----------------
  void openEditDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    routeNameCtrl.text = data['name'] ?? "";
    pickupCtrl.text = data['pickup_points'] ?? "";
    selectedDriver = data['driver_id'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Route"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: routeNameCtrl,
              decoration: const InputDecoration(labelText: "Route Name"),
            ),
            TextField(
              controller: pickupCtrl,
              decoration: const InputDecoration(labelText: "Pickup Points"),
            ),

            const SizedBox(height: 10),

            /// DRIVER DROPDOWN
            StreamBuilder(
              stream: db.collection('drivers').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final drivers = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: selectedDriver,
                  hint: const Text("Assign Driver"),
                  items: drivers.map((d) {
                    return DropdownMenuItem(
                      value: d.id,
                      child: Text(d['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDriver = value;
                    });
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              updateRoute(doc.id);
              Navigator.pop(context);
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  /// ---------------- MAIN UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Routes"),
      ),

      body: Column(
        children: [

          /// ---------------- ADD NEW ROUTE FORM ----------------
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: routeNameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Route Name",
                  ),
                ),
                TextField(
                  controller: pickupCtrl,
                  decoration: const InputDecoration(
                    labelText: "Pickup Points",
                  ),
                ),

                const SizedBox(height: 10),

                /// DRIVER DROPDOWN
                StreamBuilder(
                  stream: db.collection('drivers').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final drivers = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: selectedDriver,
                      hint: const Text("Assign Driver"),
                      items: drivers.map((d) {
                        return DropdownMenuItem(
                          value: d.id,
                          child: Text(d['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDriver = value;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: addRoute,
                  child: const Text("Add Route"),
                ),
              ],
            ),
          ),

          const Divider(),

          /// ---------------- ROUTE LIST ----------------
          Expanded(
            child: StreamBuilder(
              stream: db.collection('routes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final routes = snapshot.data!.docs;

                if (routes.isEmpty) {
                  return const Center(child: Text("No Routes Found"));
                }

                return ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final doc = routes[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text(data['name'] ?? ""),
                        subtitle: Text(
                          "Pickup: ${data['pickup_points'] ?? ""}\nDriver: ${data['driver_id'] ?? "Not assigned"}",
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            /// EDIT
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => openEditDialog(doc),
                            ),

                            /// DELETE
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteRoute(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}