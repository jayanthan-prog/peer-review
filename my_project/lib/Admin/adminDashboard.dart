import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detailPage.dart';
import 'createAssignment.dart';
import 'package:my_project/config.dart';

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

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/assignment'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          assignments = data;
          filteredAssignments = data;
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

  // void _logout() {
  //   // Clear any session data or tokens if necessary
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const LoginScreen(),  // Navigate to LoginScreen
  //     ),
  //   );
  // }

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
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     onPressed: _logout, // Trigger logout action
        //   ),
        // ],
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
                            hintText: 'Search assignments...',
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF2B4F87)),
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
                                              builder: (context) => DetailPage(
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
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF2B4F87),
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
                                                        color: Colors.grey[600],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateAssignment(),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 60, 94, 148),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
