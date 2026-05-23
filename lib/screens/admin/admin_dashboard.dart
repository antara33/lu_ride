import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String adminName = "Admin";
  String adminEmail = "";

  @override
  void initState() {
    super.initState();

    getAdminInfo();
  }

  // ---------------------------
  // GET ADMIN INFO
  // ---------------------------
  Future<void> getAdminInfo() async {

    User? user = auth.currentUser;

    if(user != null){

      final adminDoc = await firestore
          .collection("users")
          .doc(user.uid)
          .get();

      if(adminDoc.exists){

        setState(() {

          adminName =
              adminDoc.data()?["name"] ?? "Admin";

          adminEmail =
              adminDoc.data()?["email"] ?? "";
        });
      }
    }
  }

  // ---------------------------
  // REALTIME TRIPS
  // ---------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getTrips() {
    return firestore
        .collection("trips")
        .orderBy("updated_at", descending: true)
        .snapshots();
  }

  // ---------------------------
  // REALTIME DRIVERS
  // ---------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getDrivers() {
    return firestore.collection("drivers").snapshots();
  }

  // ---------------------------
  // REALTIME ROUTES
  // ---------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getRoutes() {
    return firestore.collection("routes").snapshots();
  }

  // ---------------------------
  // DRIVER ASSIGN DIALOG
  // ---------------------------
  void assignDriver(String tripId) async {

    final drivers =
    await firestore.collection("drivers").get();

    String? selectedDriver;

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          backgroundColor: Colors.white,

          title: const Text(
            "Assign Driver",
            style: TextStyle(
              color: Color(0xff2f6f79),
            ),
          ),

          content: StatefulBuilder(
            builder: (context, setState) {

              return DropdownButton<String>(
                dropdownColor: Colors.white,
                value: selectedDriver,
                isExpanded: true,

                hint: const Text(
                  "Select Driver",
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),

                items: drivers.docs
                    .map<DropdownMenuItem<String>>((e) {

                  return DropdownMenuItem<String>(
                    value: e["name"].toString(),

                    child: Text(
                      e["name"].toString(),
                      style: const TextStyle(
                        color: Color(0xff2f6f79),
                      ),
                    ),
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

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xff3d97a8),
              ),

              onPressed: () async {

                if(selectedDriver != null){

                  await firestore
                      .collection("trips")
                      .doc(tripId)
                      .update({

                    "driver_name": selectedDriver,
                    "updated_at":
                    FieldValue.serverTimestamp(),
                  });

                  if (!mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Driver Assigned Successfully",
                      ),
                    ),
                  );
                }
              },

              child: const Text(
                "Assign",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------
  // LOGOUT
  // ---------------------------
  Future<void> logout() async {

    await auth.signOut();

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xffcfe0df),

      // ---------------------------
      // BOTTOM NAVBAR
      // ---------------------------
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor:
        const Color(0xff2f6f79),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Map",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Manage",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Report",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),

      body: SafeArea(

        child:
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: getTrips(),

          builder: (context, snapshot) {

            if(snapshot.connectionState ==
                ConnectionState.waiting){

              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            // ---------------------------
            // REALTIME DATA
            // ---------------------------
            int totalBuses = docs.length;

            int activeTrips = docs
                .where((e) =>
            e["status"] == "active")
                .length;

            int delayedTrips = docs
                .where((e) =>
            e["status"] == "delayed")
                .length;

            int emergencyTrips = docs
                .where((e) =>
            e["status"] == "emergency")
                .length;

            int passengers = 0;

            for(var d in docs){

              passengers +=
              (d["passenger_count"] ?? 0) as int;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  // =========================
                  // TOP HEADER
                  // =========================
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [

                      Row(
                        children: [

                          const CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage(
                              "assets/images/busslogo.png",
                            ),
                          ),

                          const SizedBox(width: 12),

                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(
                                adminName,
                                style: const TextStyle(
                                  color:
                                  Color(0xff2f6f79),
                                  fontSize: 20,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                adminEmail,
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      PopupMenuButton(
                        color: Colors.white,

                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xff2f6f79),
                        ),

                        itemBuilder: (context) => [

                          PopupMenuItem(
                            onTap: logout,

                            child: const Text(
                              "Logout",
                              style: TextStyle(
                                color:
                                Color(0xff2f6f79),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Dashboard Overview",
                    style: TextStyle(
                      color: Color(0xff2f6f79),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // GRID CARDS
                  // =========================
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),

                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,

                    children: [

                      dashboardCard(
                        "Total Buses",
                        totalBuses.toString(),
                        Icons.directions_bus,
                        const Color(0xff3d97a8),
                        "$activeTrips Active",
                      ),

                      dashboardCard(
                        "Passengers",
                        passengers.toString(),
                        Icons.people,
                        Colors.orange,
                        "Realtime Count",
                      ),

                      dashboardCard(
                        "Delayed",
                        delayedTrips.toString(),
                        Icons.warning_amber_rounded,
                        Colors.orange,
                        "Need Attention",
                      ),

                      dashboardCard(
                        "Emergency",
                        emergencyTrips.toString(),
                        Icons.emergency,
                        Colors.red,
                        "Critical",
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // ALERT BOX
                  // =========================
                  Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(18),
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: const [

                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),

                            SizedBox(width: 10),

                            Text(
                              "System Alert",
                              style: TextStyle(
                                color:
                                Color(0xff2f6f79),
                                fontWeight:
                                FontWeight.bold,
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "$delayedTrips delayed buses currently active",

                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =========================
                  // ACTIVE BUSES
                  // =========================
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: const [

                      Text(
                        "Active Buses",
                        style: TextStyle(
                          color: Color(0xff2f6f79),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "Live",
                        style: TextStyle(
                          color: Color(0xff3d97a8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // =========================
                  // REALTIME BUS LIST
                  // =========================
                  ListView.builder(
                    itemCount: docs.length,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),

                    itemBuilder: (context, index) {

                      final data =
                      docs[index].data();

                      final status =
                          data["status"] ?? "active";

                      Color statusColor =
                      const Color(0xff22c55e);

                      if(status == "delayed"){
                        statusColor = Colors.orange;
                      }

                      if(status == "emergency"){
                        statusColor = Colors.red;
                      }

                      return Container(
                        margin:
                        const EdgeInsets.only(
                            bottom: 14),

                        padding:
                        const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(18),
                        ),

                        child: Column(
                          children: [

                            Row(
                              children: [

                                Container(
                                  padding:
                                  const EdgeInsets
                                      .all(12),

                                  decoration:
                                  BoxDecoration(

                                    color: statusColor
                                        .withValues(
                                      alpha: .15,
                                    ),

                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                        14),
                                  ),

                                  child: Icon(
                                    Icons.directions_bus,
                                    color:
                                    statusColor,
                                  ),
                                ),

                                const SizedBox(
                                    width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                    children: [

                                      Text(
                                        data["route_id"] ??
                                            "No Route",

                                        style:
                                        const TextStyle(
                                          color: Color(
                                              0xff2f6f79),
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                          fontSize:
                                          16,
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 5),

                                      Text(
                                        data["driver_name"] ??
                                            "No Driver Assigned",

                                        style:
                                        const TextStyle(
                                          color: Colors
                                              .black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),

                                  decoration:
                                  BoxDecoration(

                                    color: statusColor
                                        .withValues(
                                      alpha: .2,
                                    ),

                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                        20),
                                  ),

                                  child: Text(
                                    status
                                        .toUpperCase(),

                                    style:
                                    TextStyle(
                                      color:
                                      statusColor,
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),
                                )
                              ],
                            ),

                            const SizedBox(
                                height: 15),

                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,

                              children: [

                                Text(
                                  "Passengers: ${data["passenger_count"] ?? 0}",

                                  style:
                                  const TextStyle(
                                    color: Colors
                                        .black54,
                                  ),
                                ),

                                Text(
                                  "Speed: ${data["speed"] ?? 0} km/h",

                                  style:
                                  const TextStyle(
                                    color: Colors
                                        .black54,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 15),

                            SizedBox(
                              width:
                              double.infinity,

                              child:
                              ElevatedButton.icon(

                                style:
                                ElevatedButton
                                    .styleFrom(
                                  backgroundColor:
                                  const Color(
                                      0xff3d97a8),
                                ),

                                onPressed: () {
                                  assignDriver(
                                      docs[index]
                                          .id);
                                },

                                icon: const Icon(
                                  Icons.person_add,
                                  color:
                                  Colors.white,
                                ),

                                label: const Text(
                                  "Assign Driver",

                                  style:
                                  TextStyle(
                                    color: Colors
                                        .white,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================
  // DASHBOARD CARD
  // =========================
  Widget dashboardCard(
      String title,
      String value,
      IconData icon,
      Color color,
      String subtitle,
      ) {

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(icon, color: color),

          const Spacer(),

          Text(
            value,

            style: const TextStyle(
              color: Color(0xff2f6f79),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            title,

            style: const TextStyle(
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,

            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}