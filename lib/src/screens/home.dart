import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_new/src/screens/login.dart';
import 'package:test_new/src/screens/notification.dart';
import 'package:test_new/src/screens/task.dart';
import 'package:test_new/src/screens/task_edit.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _selectedTasks = Set<String>();

  Future<void> _deleteSelectedTasks() async {
    for (var taskId in _selectedTasks) {
      await _firestore.collection('tasks').doc(taskId).delete();
    }
    setState(() {
      _selectedTasks.clear();
    });
  }

  Future<void> _logout(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    await auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('loggedIn', false);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Home Page',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedTasks.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteSelectedTasks,
            ),
          GestureDetector(
            onTap: () {
              _logout(context);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Icon(Icons.logout, color: Colors.white),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height*.9,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('tasks').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                        ));
                  }
                  final tasks = snapshot.data!.docs.map((doc) {
                    return Task.fromMap(
                        doc.data() as Map<String, dynamic>, doc.id);
                  }).toList();

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final isSelected = _selectedTasks.contains(task.id);
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 2, // Set the elevation for the card

                          child: InkWell(
                            onTap: () {
                                NotificationService().showNotificationAfterDelay(
                                  0, // Unique ID for the notification
                                  "Test Notification",
                                  "This is a test notification shown after 3 seconds",
                                  3, // Delay in seconds
                                );

                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        activeColor: Colors.blue,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedTasks.add(task.id);
                                            } else {
                                              _selectedTasks.remove(task.id);
                                            }
                                          });
                                        },
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text("Title: ",style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w500),),

                                              Text(
                                                task.title,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text("Description: ",style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w500),),
                                              Text(task.description),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text("Status: ",style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w500),),
                                              Text(task.completionStatus.toString()),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (isSelected) {
                                        setState(() {
                                          _selectedTasks.remove(task.id);
                                        });
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  TaskFormScreen(task: task)),
                                        );
                                      }
                                    },
                                    child: Text(
                                      "Edit",
                                      style: TextStyle(
                                          color: Colors.blue, fontSize: 16),
                                    ),
                                  )
                                ],
                              ),
                            ),
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => TaskFormScreen()),
          );
        },
      ),
    );
  }
}
