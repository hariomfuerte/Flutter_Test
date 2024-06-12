import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_new/src/component/toast.dart';
import 'package:test_new/src/screens/notification.dart';
import 'package:test_new/src/screens/task.dart';
import 'package:flutter/services.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  TaskFormScreen({this.task});

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _deadline = DateTime.now();
  bool _completionStatus = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _durationController.text = widget.task!.expectedDuration.toString();
      _deadline = widget.task!.deadline;
      _completionStatus = widget.task!.completionStatus;
    }
    NotificationService().init();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await _checkExactAlarmPermission();
    if (!status) {
      await _openExactAlarmSettings();
    }
  }

  Future<bool> _checkExactAlarmPermission() async {
    try {
      const MethodChannel platform = MethodChannel('com.example.yourapp/exact_alarm');
      final bool result = await platform.invokeMethod('checkExactAlarmPermission');
      return result;
    } catch (e) {
      debugPrint("Error checking exact alarm permission: $e");
      return false;
    }
  }

  Future<void> _openExactAlarmSettings() async {
    const MethodChannel platform = MethodChannel('com.example.yourapp/exact_alarm');
    try {
      await platform.invokeMethod('openExactAlarmSettings');
    } catch (e) {
      debugPrint("Error opening exact alarm settings: $e");
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final task = Task(
      id: widget.task?.id ?? '',
      title: _titleController.text,
      description: _descriptionController.text,
      deadline: _deadline,
      expectedDuration: int.tryParse(_durationController.text) ?? 0,
      completionStatus: _completionStatus,
    );

    if (widget.task == null) {
      DocumentReference docRef = await _firestore.collection('tasks').add(task.toMap());
      task.id = docRef.id;
    } else {
      await _firestore.collection('tasks').doc(task.id).update(task.toMap());
    }

    // Calculate the time for the alarm notification (10 minutes before the deadline)
    final tenMinutesBeforeDeadline = _deadline.subtract(Duration(minutes: 10));

    // Ensure that the calculated time is in the future
    if (tenMinutesBeforeDeadline.isAfter(DateTime.now())) {
      // Schedule the alarm notification
      await NotificationService().showNotificationAfterDelay(
        task.hashCode + 1, // Unique ID for the alarm notification
        "Task Deadline Approaching",
        "Your task '${task.title}' deadline is approaching. It ends in 10 minutes.",
        tenMinutesBeforeDeadline.difference(DateTime.now()).inSeconds,
      );
    } else {
      debugPrint("Error: Deadline is not in the future.");
    }
    ToastUtils.showToast(
      message: "Successfully",
      backgroundColor: Colors.black,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          widget.task == null ? 'Create Task' : 'Edit Task',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _durationController,
                  decoration: InputDecoration(labelText: 'Expected Duration (Min)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a duration';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                CheckboxListTile(
                  activeColor: Colors.blue,
                  title: Text('Completed'),
                  value: _completionStatus,
                  onChanged: (value) {
                    setState(() {
                      _completionStatus = value!;
                    });
                  },
                ),
                Divider(height: 5, color: Colors.grey),
                ListTile(
                  title: Text('Deadline: ${_deadline.toLocal().toString().split(' ')[0]}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _deadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != _deadline) {
                      setState(() {
                        _deadline = picked;
                      });
                    }
                  },
                ),
                Divider(height: 5, color: Colors.grey),
                SizedBox(height: 20),
                Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: Text(
                      widget.task == null ? 'Create' : 'Update',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    onPressed: _saveTask,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
