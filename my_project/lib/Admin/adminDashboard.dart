import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detailPage.dart';
import 'createAssignment.dart';
import 'package:my_project/config.dart';
import 'package:my_project/LoginScreen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> assignments = [];
  List<dynamic> filteredAssignments = [];
  bool loading = true;
  String? error;
  // new state to show the view board button
  bool showViewBoardButton = false;

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    try {
      final response =
          await http.get(Uri.parse('$apiBaseUrl/api/assignment'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Reverse the list so that newest assignments appear first.
        final reversedData = List.from(data.reversed);
        setState(() {
          assignments = reversedData;
          filteredAssignments = reversedData;
          loading = false;
        });
      } else {
        throw Exception('Failed to load assignments');
      }
    } catch (err) {
      setState(() {
        error = err.toString();
        loading = false;
      });
    }
  }

  Future<void> _refreshAssignments() async {
    setState(() {
      loading = true;
    });
    await fetchAssignments();
  }

  void _filterAssignments(String query) {
    setState(() {
      filteredAssignments = assignments
          .where((assignment) => assignment['title']
              .toString()
              .toLowerCase()
              .startsWith(query.toLowerCase()))
          .toList();
    });
  }

  // Updated Logout function: using pushReplacement with MaterialPageRoute.
  void _logout() {
    // Clear user data/tokens here if needed.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2B4F87),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error: $error',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          onChanged: _filterAssignments,
                          decoration: InputDecoration(
                            hintText: 'Search ...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF2B4F87),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF2B4F87)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refreshAssignments,
                            child: filteredAssignments.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No assignments found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filteredAssignments.length,
                                    itemBuilder: (context, index) {
                                      final assignment =
                                          filteredAssignments[index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailPage(
                                                      assignment: assignment),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration:
                                                    const BoxDecoration(
                                                  color: Color(0xFF2B4F87),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.assignment,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      assignment['title'] ??
                                                          'No Title',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF2B4F87),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${assignment['date']} | ${assignment['start_time']} - ${assignment['stop_time']}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
      // Floating Action Button with a long-press to show the View Board button.
      floatingActionButton: GestureDetector(
        onLongPress: () {
          setState(() {
            showViewBoardButton = true;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showViewBoardButton)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton(
                  heroTag: "viewBoard",
                  backgroundColor: const Color.fromARGB(255, 60, 94, 148),
                  child: const Icon(
                    Icons.view_list,
                    size: 30,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      showViewBoardButton = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ViewBoardPage()),
                    );
                  },
                ),
              ),
            FloatingActionButton(
              heroTag: "createAssignment",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateAssignment()),
                );
              },
              backgroundColor: const Color.fromARGB(255, 60, 94, 148),
              child: const Icon(
                Icons.add,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------
// ViewBoardPage Widget – Excel-like View
// --------------------
class ViewBoardPage extends StatefulWidget {
  const ViewBoardPage({Key? key}) : super(key: key);

  @override
  _ViewBoardPageState createState() => _ViewBoardPageState();
}

class _ViewBoardPageState extends State<ViewBoardPage> {
  bool isLoading = true;
  String? error;
  List<dynamic> boardAssignments = [];

  @override
  void initState() {
    super.initState();
    fetchBoardAssignments();
  }

  Future<void> fetchBoardAssignments() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/assignments'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          boardAssignments = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load board assignments');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Helper method to parse task_details string into a neat format.
  String parseTaskDetails(String taskDetailsStr) {
    try {
      final List<dynamic> taskDetails = json.decode(taskDetailsStr);
      return taskDetails
          .map((td) => "${td['task_title']} (${td['task_time']})")
          .join(", ");
    } catch (e) {
      return taskDetailsStr;
    }
  }

  // A helper widget to display a section (icon, title, value)
  Widget buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("View Board"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: boardAssignments.length,
                  itemBuilder: (context, index) {
                    final assignment = boardAssignments[index];
                    final String taskDetails = assignment['task_details'] is String
                        ? parseTaskDetails(assignment['task_details'])
                        : assignment['task_details'].toString();
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.blue[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ID and Title
                              Text(
                                "ID: ${assignment['id']}   |   Title: ${assignment['title']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Explanation Section
                              Row(
                                children: const [
                                  Icon(Icons.description, color: Colors.blueAccent),
                                  SizedBox(width: 8),
                                  Text(
                                    "Explanation:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                assignment['explanation'] ?? 'No Explanation',
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              // Date, Start Time, Stop Time, Total Time
                              buildDetailRow(Icons.calendar_today, "Date", assignment['date'] ?? ''),
                              buildDetailRow(Icons.access_time, "Start Time", assignment['start_time'] ?? ''),
                              buildDetailRow(Icons.access_time, "Stop Time", assignment['stop_time'] ?? ''),
                              buildDetailRow(Icons.hourglass_bottom, "Total Time", assignment['total_time'] ?? ''),
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              // Additional Details
                              buildDetailRow(Icons.group, "Students", assignment['number_of_students'].toString()),
                              buildDetailRow(Icons.task, "Tasks", assignment['numberoftasks'].toString()),
                              buildDetailRow(Icons.list, "Task Details", taskDetails),
                              buildDetailRow(Icons.star, "Ranks", assignment['numberofranks'].toString()),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}