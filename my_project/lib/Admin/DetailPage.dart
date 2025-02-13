import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_project/config.dart';
import 'package:intl/intl.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> assignment;
  const DetailPage({super.key, required this.assignment});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  TextEditingController explanationController = TextEditingController();
  int numberOfStudents = 0;
  int numberOfTasks = 0;
  int numberOfRanks = 0;
  List<String> taskTitles = [];
  List<String> taskTimes = [];
  bool isLoading = false;

  void addTask() {
    setState(() {
      taskTitles.add('');
      taskTimes.add('');
      numberOfTasks++;
    });
  }

  void removeTask(int index) {
    setState(() {
      taskTitles.removeAt(index);
      taskTimes.removeAt(index);
      numberOfTasks--;
    });
  }

  int calculateTotalTime() {
    // Updated time map: the values represent minutes.
    Map<String, int> timeInMinutes = {
      '5 min': 5,
      '10 min': 10,
      '15 min': 15,
      '20 min': 20,
      '25 min': 25,
      '30 min': 30,
      '35 min': 35,
      '40 min': 40,
      '45 min': 45,
      '50 min': 50
    };
    int totalMinutes = 0;
    for (var time in taskTimes) {
      if (timeInMinutes.containsKey(time)) {
        totalMinutes += timeInMinutes[time]!;
      }
    }
    return totalMinutes;
  }

Future<void> saveAssignment() async {
  if (explanationController.text.isEmpty ||
      numberOfStudents == 0 ||
      numberOfTasks == 0 ||
      taskTitles.contains('')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill in all fields properly!')),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  // Prepare assignment data without UTC conversion
  // Format the date to remove the UTC format
  String originalDate = widget.assignment["date"]; // e.g., "2025-02-12T18:30:00.000Z"
  DateTime parsedDate = DateTime.parse(originalDate); // Parse to DateTime
  String formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate); // Format to desired string

  final assignmentData = {
    "title": widget.assignment["title"],
    "date": formattedDate, // Use the formatted date
    "start_time": widget.assignment["start_time"], // Use the start time as is
    "stop_time": widget.assignment["stop_time"], // Use the stop time as is
    "explanation": explanationController.text,
    "number_of_students": numberOfStudents,
    "numberoftasks": numberOfTasks,
    "numberofranks": numberOfRanks,
    "task_details": List.generate(
      taskTitles.length,
      (index) => {
        "task_title": taskTitles[index],
        "task_time": taskTimes[index],
      },
    ),
    "total_time": calculateTotalTime(),
  };

  // Debug: Print assignment data before sending
  print("Posting Assignment Data: ${jsonEncode(assignmentData)}");

  try {
    final response = await http.post(
      Uri.parse("$apiBaseUrl/api/assignments"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(assignmentData), // Send the assignment data
    );

    // Debug: Print response status and body
    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Assignment saved successfully!")),
      );
      Navigator.pop(context);
    } else {
      throw Exception("Failed to save assignment");
    }
  } catch (error) {
    // Debug: Print the error
    print("Error occurred: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to save assignment!")),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}
  void showNumberSelectionModal(Function(int) onSelect, String title,
      {int? maxCount}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        height: 300,
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            Expanded(
              child: ListView.builder(
                itemCount: maxCount ?? 50,
                itemBuilder: (context, index) => ListTile(
                  title: Text('${index + 1}'),
                  onTap: () {
                    onSelect(index + 1);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showTaskTimeModal(int index) {
    List<String> timeOptions = [
      '5 min',
      '10 min',
      '15 min',
      '20 min',
      '25 min',
      '30 min',
      '35 min',
      '40 min',
      '45 min',
      '50 min'
    ];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        height: 300,
        child: Column(
          children: [
            Text("Select Task Time",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            Expanded(
              child: ListView.builder(
                itemCount: timeOptions.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(timeOptions[i]),
                  onTap: () {
                    setState(() {
                      taskTimes[index] = timeOptions[i];
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Event Detail"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card for Date and Time
            Card(
              elevation: 1,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Event: ${widget.assignment["title"]}",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Date: ${widget.assignment["date"]}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    Text(
                      "Time: ${widget.assignment["start_time"]} - ${widget.assignment["stop_time"]}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Explanation Field wrapped in a Card View
            Card(
              elevation: 1,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: explanationController,
                  decoration: InputDecoration(
                    labelText: "Enter Explanation",
                    labelStyle:
                        TextStyle(color: Colors.blueAccent, fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Rounded Corners
                      borderSide:
                          BorderSide(color: Colors.blueGrey[300]!, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Rounded Corners
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                  maxLines: 3,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Card for Number of Students Button
            Card(
              elevation: 1,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text("Number of Students: $numberOfStudents"),
                trailing: Icon(Icons.arrow_forward),
                onTap: () => showNumberSelectionModal(
                  (value) {
                    setState(() {
                      numberOfStudents = value;
                      // Reset numberOfRanks if it exceeds the number of students
                      if (numberOfRanks > numberOfStudents) {
                        numberOfRanks = numberOfStudents;
                      }
                    });
                  },
                  "Select Number of Students",
                ),
              ),
            ),
            SizedBox(height: 10),
            // Card for Number of Ranks Button
            Card(
              elevation: 5,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text("Number of Ranks: $numberOfRanks"),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Only allow selection if numberOfStudents is greater than 0
                  if (numberOfStudents > 0) {
                    showNumberSelectionModal(
                      (value) => setState(() => numberOfRanks = value),
                      "Select Number of Ranks",
                      maxCount: numberOfStudents,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Please select number of students first")),
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 10),
            // Card for Number of Tasks Button
            Card(
              elevation: 1,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text("Number of Tasks: $numberOfTasks"),
                trailing: Icon(Icons.arrow_forward),
                onTap: () => showNumberSelectionModal((value) {
                  setState(() {
                    numberOfTasks = value;
                    taskTitles = List.filled(value, "");
                    taskTimes = List.filled(value, "");
                  });
                }, "Select Number of Tasks"),
              ),
            ),
            if (numberOfTasks > 0)
              Column(
                children: List.generate(numberOfTasks, (index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: "Task ${index + 1} Title",
                              labelStyle: TextStyle(color: Colors.blueAccent),
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.blueAccent, width: 2),
                              ),
                            ),
                            onChanged: (text) =>
                                setState(() => taskTitles[index] = text),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => showTaskTimeModal(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                            ),
                            child: Text(
                                "Task Time: ${taskTimes[index].isEmpty ? "Select" : taskTimes[index]}"),
                          ),
                          SizedBox(height: 5),
                          TextButton(
                            onPressed: () => removeTask(index),
                            child: Text("Remove Task",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            if (numberOfTasks > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "Total Time: ${calculateTotalTime()} minutes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : saveAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 12),
                textStyle: TextStyle(fontSize: 18),
                minimumSize: Size(double.infinity, 48),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Save Event"),
            ),
          ],
        ),
      ),
    );
  }
}