import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_app/page/student/codeQr.dart';
import 'package:my_flutter_app/page/student/paymentdetails.dart';
import 'package:my_flutter_app/page/student/student2.dart';

class Student1Page extends StatefulWidget {
  @override
  _Student1PageState createState() => _Student1PageState();
}

class _Student1PageState extends State<Student1Page> {
  List<String> items = ['My Profile', 'Log Out'];
  String? dropvalue;
  bool isAttendance = false; // Initialize to a default value

  @override
  void initState() {
    super.initState();
    initializeAttendance();
    checkAndDeleteAccount();
  }

  Future<void> initializeAttendance() async {
    try {
      String userID = FirebaseAuth.instance.currentUser!.uid;
      bool attendance = await getAttendance(userID);
      setState(() {
        isAttendance = attendance;
      });
    } catch (e) {
      print('Error initializing attendance: $e');
      // Handle the error as needed
    }
  }

  Future<bool> getAttendance(String userID) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('student')
          .doc(userID)
          .get();

      // Assuming 'Attendance' field exists and its value is a boolean
      bool attendance = snapshot['Attendance'];

      return attendance;
    } catch (e) {
      print('Error fetching attendance: $e');
      // Optionally handle the error here
      return false; // Return a default value or handle the error case appropriately
    }
  }

  Future<DocumentSnapshot> getUserData(String userID) async {
    final studentSnapshot = await FirebaseFirestore.instance
        .collection('student')
        .doc(userID)
        .get();

    final adminSnapshot =
        await FirebaseFirestore.instance.collection('Admin').doc(userID).get();

    return adminSnapshot.exists ? adminSnapshot : studentSnapshot;
  }

  Future<void> MessOut(User user) async {
    try {
      String? userID = user.uid;
      DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('student')
          .doc(userID)
          .get();

      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('Admin')
          .doc(userID)
          .get();

      // Check if the student document exists, otherwise, use admin data
      DocumentSnapshot documentSnapshot =
          studentSnapshot.exists ? studentSnapshot : adminSnapshot;

      await documentSnapshot.reference.update({'Mess': false});
    } catch (e) {
      print('Error polling mess out: $e');
    }
  }

  Future<String> getUserRole(String? userID) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('Admin').doc(userID).get();
    if (snapshot.exists) {
      return 'admin';
    } else {
      return 'student';
    }
  }

  Timer? _timer;

  Future<void> MessBill(User user) async {
    try {
      String? userID = user.uid;
      String userRole = await getUserRole(userID);
      if (userRole == 'admin') {
        await FirebaseFirestore.instance
            .collection('Admin')
            .doc(userID)
            .update({
          'Mess': true,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('student')
            .doc(userID)
            .update({
          'Mess': true,
        });
      }
      _timer = Timer.periodic(Duration(hours: 24), (timer) async {
        try {
          if (userRole == 'admin') {
            DocumentSnapshot snapshot = await FirebaseFirestore.instance
                .collection('Admin')
                .doc(userID)
                .get();
            if (snapshot.exists && snapshot['Mess'] == false) {
              _timer?.cancel(); // Cancel the timer if Mess is false
              return;
            }
            await FirebaseFirestore.instance
                .collection('Admin')
                .doc(userID)
                .update({
              'MessBill': FieldValue.increment(90),
            });
          } else {
            DocumentSnapshot snapshot = await FirebaseFirestore.instance
                .collection('student')
                .doc(userID)
                .get();
            if (snapshot.exists && snapshot['Mess'] == false) {
              _timer?.cancel(); // Cancel the timer if Mess is false
              return;
            }
            await FirebaseFirestore.instance
                .collection('student')
                .doc(userID)
                .update({
              'MessBill': FieldValue.increment(90),
            });
          }
        } catch (e) {
          print('Error updating mess bill: $e');
          // Handle the error accordingly
        }
      });
    } catch (e) {
      print('Error updating mess bill: $e');
      // Handle the error accordingly
    }
  }

  bool showButtons = false;

  Future<void> getFeeData(User user) async {
    try {
      String userID = user.uid;
      DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('student')
          .doc(userID)
          .get();

      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('Admin')
          .doc(userID)
          .get();

      // Check if the student document exists, otherwise, use admin data
      DocumentSnapshot documentSnapshot =
          studentSnapshot.exists ? studentSnapshot : adminSnapshot;
      int firstRentFee = documentSnapshot.get('FirstRent') ?? 0;
      int secondRentFee = documentSnapshot.get('SecondRent') ?? 0;
      int messFee = documentSnapshot.get('MessBill') ?? 0;

      int total = firstRentFee + secondRentFee + messFee;
      int rentFee = firstRentFee + secondRentFee;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Color(0xFFFCF5ED),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 180.0,
              height: 180.0,
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Rent: $rentFee"),
                  ),
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Mess: $messFee"),
                  ),
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Total: $total"),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the AlertDialog
                },
                child: Text(
                  'Close',
                  style: TextStyle(color: Color(0xFFCE5A67)),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error retrieving fee data: $e');
      // Handle the error accordingly
    }
  }

  // Function to check if the current date is after April 15th of the next year
  bool isAfterApril15NextYear() {
    final april15NextYear = DateTime(DateTime.now().year + 1, 4, 15);
    final now = DateTime.now();
    final date = now;
    return now.isAfter(april15NextYear);
  }

  Future<void> checkAndDeleteAccount() async {
    try {
      // Check if user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userID = currentUser.uid;

        // Get the current date
        final currentDate = DateTime.now();
        final targetDate = DateTime(currentDate.year + 1, 4, 15);
        if (currentDate.isAfter(targetDate)) {
          // Get the current user's document from Firestore
          final userDocumentSnapshot = await FirebaseFirestore.instance
              .collection('student')
              .doc(userID)
              .get();

          if (userDocumentSnapshot.exists) {
            final studentData = userDocumentSnapshot.data();

            // Check if the year is third and graduation is ug
            final year = studentData?['Year'];
            final graduation = studentData?['Graduation'];

            if (year == 'Third' && graduation == 'UG') {
              // Delete user data from Firestore
              await userDocumentSnapshot.reference.delete();
              await currentUser.delete();
            } else if (year == 'Second' && graduation == 'PG') {
              // Delete user data from Firestore
              await userDocumentSnapshot.reference.delete();
              await currentUser.delete();
            } else if (year == 'Second' && graduation == 'B.ED') {
              // Delete user data from Firestore
              await userDocumentSnapshot.reference.delete();
              await currentUser.delete();
            } else {
              switch (year) {
                case 'First':
                  await FirebaseFirestore.instance
                      .collection('student')
                      .doc(userID)
                      .update({'Year': 'Second'});
                  break;
                case 'Second':
                  await FirebaseFirestore.instance
                      .collection('student')
                      .doc(userID)
                      .update({'Year': 'Third'});
                  break;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error checking and deleting account: $e');
      // Handle the error accordingly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Color(0xFFF4BF96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.account_circle,
            color: Colors.black,
          ),
          iconSize: 50,
          onPressed: () {
            showMenu(
              context: context,
              position: RelativeRect.fromLTRB(
                  0, 100, 100, 0), // Adjust position as needed
              items: items.map((String item) {
                return PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ).then((value) {
              setState(() {
                dropvalue = value;
                if (value == 'My Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Student2Page()),
                  );
                } else if (value == 'Log Out')
                  (FirebaseAuth.instance.signOut());
              });
            });
          },
        ),
        title: FutureBuilder<User?>(
            future: FirebaseAuth.instance.authStateChanges().first,
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Text('Loading...');
              } else {
                final currentUserID = userSnapshot.data!.uid;

                return FutureBuilder<DocumentSnapshot>(
                  future: getUserData(currentUserID),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading...');
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Text('Name\nStudent');
                    } else {
                      final userName = snapshot.data!['Name'];

                      return Text(
                        '$userName\nStudent',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      );
                    }
                  },
                );
              }
            }),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 70,
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Student2Page()));
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xFFCE5A67),
                ),
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 20,
                    color: const Color.fromARGB(255, 15, 14, 14),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.0),
            GestureDetector(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(builder: (context, setState) {
                        DateTime now = DateTime.now();
                        bool isBetween10To11 = now.hour >= 10 && now.hour < 11;
                        bool isBetween11To12 = now.hour >= 11 && now.hour < 12;
                        return AlertDialog(
                          backgroundColor: Color(0xFFFCF5ED),
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                15.0), // Set your desired border radius here
                          ),
                          content: Container(
                            padding: EdgeInsets.fromLTRB(10, 20, 10, 10),
                            child: showButtons
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                          onPressed: () {
                                            if (isBetween10To11)
                                              MessBill(FirebaseAuth
                                                  .instance.currentUser!);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text('Time Up'),
                                            ));
                                            Navigator.pop(context);
                                            showButtons = false;
                                          },
                                          child: Text('Mess In',
                                              style: TextStyle(
                                                color: Color(0xFFCE5A67),
                                              )),
                                          style: TextButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)))),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      TextButton(
                                          onPressed: () {
                                            if (isBetween11To12)
                                              MessOut(FirebaseAuth
                                                  .instance.currentUser!);
                                            else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text('Time Up'),
                                              ));
                                            }
                                            Navigator.pop(context);
                                            showButtons = false;
                                          },
                                          child: Text(
                                            'Mess Out',
                                            style: TextStyle(
                                              color: Color(0xFFCE5A67),
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)))),
                                    ],
                                  )
                                : TextButton(
                                    onPressed: () {
                                      if (isAttendance)
                                        setState(() {
                                          showButtons = true;
                                        });
                                      else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content:
                                              Text('Attendance is not marked'),
                                        ));
                                      }
                                    },
                                    child: Text(
                                      'Poll Here',
                                      style: TextStyle(
                                        color: Color(0xFFCE5A67),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)))),
                          ),
                          actions: <Widget>[
                            SizedBox(
                              height: 50,
                            ),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  showButtons = false;
                                },
                                child: Text(
                                  'Close',
                                  style: TextStyle(
                                    color: Color(0xFFCE5A67),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)))),
                          ],
                        );
                      });
                    });
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xFFCE5A67),
                ),
                child: Text(
                  'Mess details',
                  style: TextStyle(
                    fontSize: 20,
                    color: const Color.fromARGB(255, 15, 14, 14),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.0),
            Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                //height:100,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xFFCE5A67),
                ),
                child: GestureDetector(
                  onTap: () {
                    getFeeData(FirebaseAuth.instance.currentUser!);
                  },
                  child: Text(
                    'Fee Details',
                    style: TextStyle(
                      fontSize: 20,
                      color: const Color.fromARGB(255, 15, 14, 14),
                    ),
                  ),
                )),
            SizedBox(height: 30.0),
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => QrCodeScannerPage()));
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                //height:100,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xFFCE5A67),
                ),
                child: Text(
                  'Attendance',
                  style: TextStyle(
                    fontSize: 20,
                    color: const Color.fromARGB(255, 15, 14, 14),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.0),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => PaymentDetails()));
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xFFCE5A67),
                ),
                child: Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: 20,
                    color: const Color.fromARGB(255, 15, 14, 14),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
