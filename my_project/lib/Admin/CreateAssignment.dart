import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'adminDashboard.dart'; // Ensure this import exists
import 'package:my_project/config.dart';

class CreateAssignment extends StatefulWidget {
  @override
  _CreateAssignmentState createState() => _CreateAssignmentState();
}

class _CreateAssignmentState extends State<CreateAssignment> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _stopTime = TimeOfDay.now();
  bool isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _stopTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _stopTime = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.isEmpty) {
      showErrorDialog("Title cannot be empty.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String formattedStartTime = "${_startTime.hour}:${_startTime.minute}:00";
    String formattedStopTime = "${_stopTime.hour}:${_stopTime.minute}:00";

    Map<String, dynamic> assignmentData = {
      "title": _titleController.text,
      "date": formattedDate,
      "startTime": formattedStartTime,
      "stopTime": formattedStopTime,
    };

    try {
      final response = await http.get(
        Uri.parse("$apiBaseUrl/api/assignments"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        List<dynamic> existingAssignments = json.decode(response.body);

        bool isDuplicate = existingAssignments.any((assignment) =>
            assignment["title"] == assignmentData["title"] &&
            assignment["date"] == assignmentData["date"]);

        if (isDuplicate) {
          showErrorDialog(
              "Duplicate entry detected! Please use a different title or date.");
          return;
        }
      }

      final postResponse = await http.post(
        Uri.parse("$apiBaseUrl/api/assignment"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(assignmentData),
      );

      if (postResponse.statusCode == 200) {
        showSuccessDialog('Assignment Created Successfully');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AdminScreen()),
          (route) => false,
        );
      } else {
        showErrorDialog("Error submitting assignment: ${postResponse.body}");
      }
    } catch (error) {
      showErrorDialog("Error: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Assignment",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2B4F87),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTitleField(),
            const SizedBox(height: 20),
            buildDatePicker(),
            const SizedBox(height: 20),
            buildTimePicker("Start Time", _startTime, true),
            const SizedBox(height: 20),
            buildTimePicker("Stop Time", _stopTime, false),
            const Spacer(),
            buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget buildTitleField() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: "Assignment Title",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: buildInfoTile(
        title: "Select Date",
        value: DateFormat.yMMMMd().format(_selectedDate),
        icon: Icons.calendar_today,
      ),
    );
  }

  Widget buildTimePicker(String label, TimeOfDay time, bool isStartTime) {
    return GestureDetector(
      onTap: () => _selectTime(context, isStartTime),
      child: buildInfoTile(
        title: label,
        value: time.format(context),
        icon: Icons.access_time,
      ),
    );
  }

  Widget buildInfoTile(
      {required String title, required String value, required IconData icon}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2B4F87)),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16)),
              ],
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B4F87),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Submit",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(fontSize: 16, color: Colors.black)),
          ),
        ),
      ],
    );
  }
}