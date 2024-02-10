// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_app/Login_page.dart';

class parent_student extends StatefulWidget {
  const parent_student({super.key});

  @override
  State<parent_student> createState() => _parent_studentState();
}

class _parent_studentState extends State<parent_student> {
  List<String> items = ['My Profile', 'Log Out'];
  String? dropvalue;

  Future<DocumentSnapshot> getUserData(String userID) async {
    final parentSnapshot =
        await FirebaseFirestore.instance.collection('parent').doc(userID).get();

    final adminSnapshot =
        await FirebaseFirestore.instance.collection('Admin').doc(userID).get();

    return adminSnapshot.exists ? adminSnapshot : parentSnapshot;
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
            Icons.escalator_warning,
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
                    MaterialPageRoute(builder: (context) => parent_student()),
                  );
                } else if (value == "Log Out") {
                  FirebaseAuth.instance.signOut().then((value) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => Login_Page()),
                      (Route<dynamic> route) => false,
                    );
                  });
                }
              });
            });
          },
        ),
        title: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            } else {
              print('Authentication state: ${authSnapshot.connectionState}');
              if (authSnapshot.hasError) {
                // Print any error that occurred
                print('Authentication error: ${authSnapshot.error}');
              }
              final currentUserID = authSnapshot.data;
              if (currentUserID == null) {
                // If user is null, they are not logged in
                print('User is not logged in');
              } else if (currentUserID is String) {
                // If user is a String, it represents the user ID
                print('User is logged in with UID: $currentUserID');
              } else {
                // If user is not null and not a String, it's a User object
                print('User is logged in: ${currentUserID.uid}');
              }

              return FutureBuilder<DocumentSnapshot>(
                future: currentUserID != null
                    ? getUserData(currentUserID.uid)
                    : null,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Loading...');
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Text('Name\nParent');
                  } else {
                    final userName = snapshot.data!['Name'];

                    return Text(
                      '$userName\nParent',
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
          },
        ),
      ),
      backgroundColor: const Color(0xFFFCF5ED),
      body: FutureBuilder<User?>(
          future: FirebaseAuth.instance.authStateChanges().first,
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child:
                      CircularProgressIndicator()); // Show a loading indicator while fetching data
            } else if (userSnapshot.hasError) {
              return Center(child: Text('Error: ${userSnapshot.error}'));
            } else if (!userSnapshot.hasData || userSnapshot.data == null) {
              return Center(child: Text('No Data Available'));
            } else {
              final currentUserID = userSnapshot.data!.uid;

              return FutureBuilder<DocumentSnapshot>(
                  future: getUserData(currentUserID),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Center(
                          child:
                              Text('No data available for the current user'));
                    } else {
                      final parentSnapshot = snapshot.data!;
                      final studentId = parentSnapshot['StudentID'];

                      return ListView(children: [
                        SizedBox(
                          height: 30,
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Name',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.3,
                                    color: Color(0xFFCE5A67),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 5),
                                if (studentId != null && studentId.isNotEmpty)
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('student')
                                        .doc(studentId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        final name = snapshot.data?['Name'] ??
                                            'No data available';
                                        return Text(
                                          name.toString(),
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.3,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                if (studentId.isEmpty)
                                  Text(
                                    'Name',
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.3,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                              ],
                            ),
                            decoration: BoxDecoration(
                                border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                              ),
                            ))),
                        SizedBox(
                          height: 30,
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PhoneNo',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.3,
                                    color: Color(0xFFCE5A67),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 5),
                                if (studentId != null && studentId.isNotEmpty)
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('student')
                                        .doc(studentId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        final phoneNo =
                                            snapshot.data?['PhoneNO'] ??
                                                'No data available';
                                        return Text(
                                          phoneNo.toString(),
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.3,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                if (studentId.isEmpty)
                                  Text(
                                    'Phone No',
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.3,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                              ],
                            ),
                            decoration: BoxDecoration(
                                border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                              ),
                            ))),
                        SizedBox(
                          height: 30,
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room No',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.3,
                                    color: Color(0xFFCE5A67),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 5),
                                if (studentId != null && studentId.isNotEmpty)
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('student')
                                        .doc(studentId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        final roomNo =
                                            snapshot.data?['RoomNo'] ??
                                                'No data available';
                                        return Text(
                                          roomNo.toString(),
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.3,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                if (studentId.isEmpty)
                                  Text(
                                    'Room No',
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.3,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                              ],
                            ),
                            decoration: BoxDecoration(
                                border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                              ),
                            ))),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mess Fee',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.3,
                                    color: Color(0xFFCE5A67),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 5),
                                if (studentId != null && studentId.isNotEmpty)
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('student')
                                        .doc(studentId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        final messBill =
                                            snapshot.data?['MessBill'] ??
                                                'No data available';
                                        return Text(
                                          messBill.toString(),
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.3,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                if (studentId.isEmpty)
                                  Text(
                                    'Mess Fee',
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.3,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                              ],
                            ),
                            decoration: BoxDecoration(
                                border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                              ),
                            ))),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rent Fee',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.3,
                                    color: Color(0xFFCE5A67),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 5),
                                if (studentId != null && studentId.isNotEmpty)
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('student')
                                        .doc(studentId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        final firstRent =
                                            snapshot.data?['FirstRent'] ??
                                                'No data available';
                                        final secondRent =
                                            snapshot.data?['SecondRent'] ??
                                                'No data available';
                                        final Rent = firstRent + secondRent;
                                        return Text(
                                          Rent.toString(),
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.3,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                if (studentId.isEmpty)
                                  Text(
                                    'Rent',
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.3,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                              ],
                            ),
                            decoration: BoxDecoration(
                                border: Border(
                              bottom: BorderSide(
                                color: Colors.black,
                              ),
                            ))),
                        SizedBox(
                          height: 30,
                        ),
                      ]);
                    }
                  });
            }
          }),
    );
  }
}
