# my_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math'; // Import this to use Random
import 'package:my_project/config.dart';

// ================================================================
// StudentDashboard Page
// ================================================================
class StudentDashboard extends StatefulWidget {
  final String? loggedInUserId;
  const StudentDashboard({Key? key, this.loggedInUserId}) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List assignments = [];
  String? userId;
  bool isLoading = false;
  String? clickedAssignmentTitle;

  @override
  void initState() {
    super.initState();
    userId = widget.loggedInUserId;
    print("Logged In User ID: $userId");
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Use the singular endpoint if it returns multiple assignments,
      // otherwise adjust accordingly.
      final response = await http.get(Uri.parse("$apiBaseUrl/api/assignment"));
      if (response.statusCode == 200) {
        List<dynamic> allAssignments = json.decode(response.body);
        // Filter assignments by checking if the logged in userId is in the assign_to list.
        setState(() {
          assignments = allAssignments.where((assignment) {
            List<String> assignedUsers = assignment['assign_to'].split(',');
            return assignedUsers.contains(userId);
          }).toList();
        });
      } else {
        print("Error: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch assignments")),
        );
      }
    } catch (e) {
      print("Error fetching assignments: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while fetching assignments")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void navigateToAssignmentDetails(String title) async {
    final String apiUrl =
        "http://192.168.205.45:5000/api/assignments?title=$title";
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> assignmentData = json.decode(response.body);
      if (assignmentData.isNotEmpty) {
        Map<String, dynamic> assignmentDetails = assignmentData[0];
        // Decode task details if exist, otherwise it will be empty.
        List<dynamic> taskDetails =
            json.decode(assignmentDetails['task_details'] ?? '[]');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AssignmentDetailsPage(assignmentTitle: title),
          ),
        );
      } else {
        showNoDetailsAlert();
      }
    } else {
      print("Failed to fetch assignment details");
    }
  }

  void showNoDetailsAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("No Details Found"),
          content: Text("The details for this assignment are not available."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Student Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : assignments.isEmpty
              ? Center(child: Text("No assignments available"))
              : ListView.builder(
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    var assignment = assignments[index];
                    return Card(
                      margin: EdgeInsets.all(10),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          assignment['title'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(
                          "Start: ${assignment['start_time']} - Stop: ${assignment['stop_time']}",
                          style:
                              TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios,
                            size: 20, color: Colors.blueAccent),
                        onTap: () {
                          print(
                              "ListTile tapped for assignment: ${assignment['title']}");
                          setState(() {
                            clickedAssignmentTitle = assignment['title'];
                          });
                          print("Assignment title clicked: $clickedAssignmentTitle");
                          navigateToAssignmentDetails(assignment['title']);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

// ================================================================
// AssignmentDetailsPage
// ================================================================
class AssignmentDetailsPage extends StatefulWidget {
  final String assignmentTitle;
  const AssignmentDetailsPage({Key? key, required this.assignmentTitle})
      : super(key: key);

  @override
  _AssignmentDetailsPageState createState() => _AssignmentDetailsPageState();
}

class _AssignmentDetailsPageState extends State<AssignmentDetailsPage> {
  Map<String, dynamic>? assignmentDetails;
  List<dynamic> taskDetails = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAssignmentDetails();
  }

  Future<void> fetchAssignmentDetails() async {
    final response =
        await http.get(Uri.parse("http://192.168.205.45:5000/api/assignments"));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      // Find assignment by title – case insensitive
      final assignment = data.firstWhere(
        (assignment) =>
            assignment['title']
                .toString()
                .toLowerCase() ==
            widget.assignmentTitle.toLowerCase(),
        orElse: () => null,
      );
      if (assignment != null) {
        setState(() {
          assignmentDetails = assignment;
          taskDetails =
              json.decode(assignmentDetails!['task_details'] ?? '[]');
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Assignment not found!")),
        );
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch assignment details!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Assignment Details")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (assignmentDetails == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Assignment Details")),
        body: Center(child: Text("No assignment found.")),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(assignmentDetails!['title']),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📌 Explanation:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(assignmentDetails!['explanation'],
                          style: TextStyle(fontSize: 16)),
                      Divider(),
                      Text("📅 Date: ${assignmentDetails!['date']}",
                          style: TextStyle(fontSize: 16)),
                      Text("⏰ Start Time: ${assignmentDetails!['start_time']}",
                          style: TextStyle(fontSize: 16)),
                      Text("🛑 Stop Time: ${assignmentDetails!['stop_time']}",
                          style: TextStyle(fontSize: 16)),
                      Text("⏳ Total Time: ${assignmentDetails!['total_time']}",
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text("📌 Tasks:",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ...taskDetails.map((task) => Card(
                    elevation: 1.5,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: Icon(Icons.task, color: Colors.blueAccent),
                      title: Text(task['task_title'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text("⏳ Duration: ${task['task_time']}",
                          style: TextStyle(fontSize: 14)),
                    ),
                  )),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TaskPage(
                            allTasks: taskDetails, currentIndex: 0)),
                  );
                },
                child: Text("Start Now"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// TaskPage: Handles each Task with a timer and dynamic question fetching
// ================================================================
class TaskPage extends StatefulWidget {
  final List<dynamic> allTasks;
  final int currentIndex;
  TaskPage({required this.allTasks, required this.currentIndex});

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late int remainingTime;
  Timer? timer;
  String displayedQuestion = "Loading question...";
  List<int> displayedQuestionIds = [];

  @override
  void initState() {
    super.initState();
    var taskDetails = widget.allTasks[widget.currentIndex];
    String taskTimeStr = taskDetails['task_time'] ?? '0 min';
    int taskTime = int.tryParse(
            RegExp(r'\d+').firstMatch(taskTimeStr)?.group(0) ?? '0') ??
        0;
    remainingTime = taskTime * 60;
    displayedQuestion = "Loading question...";
    fetchQuestion();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        moveToNextTask();
      }
    });
  }

  Future<void> fetchQuestion() async {
    final response = await http.get(Uri.parse("$apiBaseUrl/api/questions"));
    if (response.statusCode == 200) {
      List<dynamic> questions = json.decode(response.body);
      questions = questions
          .where((q) => !displayedQuestionIds.contains(q['id']))
          .toList();
      if (questions.isNotEmpty) {
        final randomIndex = Random().nextInt(questions.length);
        setState(() {
          displayedQuestion = questions[randomIndex]['question'];
          displayedQuestionIds.add(questions[randomIndex]['id']);
        });
      } else {
        setState(() {
          displayedQuestion = "No new questions available";
        });
      }
    } else {
      setState(() {
        displayedQuestion = "Failed to load question";
      });
    }
  }

  void moveToNextTask() {
    if (widget.currentIndex + 1 < widget.allTasks.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TaskPage(
            allTasks: widget.allTasks,
            currentIndex: widget.currentIndex + 1,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CompletionPage()),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var taskDetails = widget.allTasks[widget.currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(taskDetails['task_title']),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "⏳ Remaining Time: ${remainingTime ~/ 60}:${(remainingTime % 60).toString().padLeft(2, '0')}",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "📌 Task: ${taskDetails['task_title']}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 1.5,
              margin: EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  displayedQuestion,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: moveToNextTask,
              child: Text(widget.currentIndex + 1 < widget.allTasks.length
                  ? "Next Task"
                  : "Finish"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: TextStyle(fontSize: 18),
                backgroundColor: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CompletionPage: Handles submission of rankings and displays UI for selection
// ================================================================
class CompletionPage extends StatefulWidget {
  
  @override
  _CompletionPageState createState() => _CompletionPageState();
}

class _CompletionPageState extends State<CompletionPage> {
  // List to hold all assignments fetched from API.
  List<dynamic> assignmentsList = [];
  // The selected assignment (if any)
  Map<String, dynamic>? selectedAssignment;
  // Ranking data variables
  List<Map<String, dynamic>> rankingList = [];
  int numberOfRanks = 0;
  int numberOfStudents = 0;
  int numberOfTasks = 0;
  String? selectedTask;
  // Here, we store the selected assign_to id as string.
  Map<int, String?> selectedRanks = {};
  bool isSubmitting = false;
  Set<String> submittedTasks = {};

  @override
  void initState() {
    super.initState();
    // First, fetch the list of assignments so the user can select one.
    fetchAssignmentsList();
  }

  // Fetch the assignments list from the API.
  Future<void> fetchAssignmentsList() async {
    final response =
        await http.get(Uri.parse("$apiBaseUrl/api/assignments"));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        assignmentsList = data;
      });
    } else {
      print("Failed to fetch assignments list.");
    }
  }

  // When an assignment is selected, update state with its details,
  // then fetch the assign_to ids from the assignment API.
  void onAssignmentSelected(String title) {
    final assignment = assignmentsList.firstWhere(
        (assgn) =>
            assgn['title'].toString().toLowerCase() ==
            title.toLowerCase(),
        orElse: () => null);
    if (assignment != null) {
      setState(() {
        selectedAssignment = assignment;
        numberOfRanks = assignment['numberofranks'] ?? 0;
        numberOfTasks = assignment['numberoftasks'] ?? 0;
        numberOfStudents = assignment['number_of_students'] ?? 0;
        // Initialize ranking map keys.
        selectedRanks = {for (var i = 1; i <= numberOfRanks; i++) i: null};
      });
      // Instead of fetching student names from namelist, fetch from the assignment API.
      fetchAssignToIds();
    }
  }

// Removed duplicate function

  // Submit the ranking data using the selected assignment's id.
  Future<void> fetchAssignToIds() async {
  if (selectedAssignment == null) return;

  // Get the selected assignment title in lower case for a case-insensitive match.
  String clickedAssignmentTitle =
      (selectedAssignment!['title'] ?? "").toString().toLowerCase();

  // First, fetch the assignment details from the backend.
  final assignmentResponse = await http.get(
    Uri.parse("http://192.168.205.45:5000/api/assignment"),
  );
  
  if (assignmentResponse.statusCode == 200) {
    List<dynamic> assignmentsDecoded = json.decode(assignmentResponse.body);

    // Find the assignment with the matching title.
    Map<String, dynamic>? assignmentData = assignmentsDecoded.firstWhere(
      (assignment) =>
          (assignment['title'] ?? "").toString().toLowerCase() ==
          clickedAssignmentTitle,
      orElse: () => null,
    );

    if (assignmentData != null) {
      // Get the assign_to string and split it into a list.
      String assignToStr = assignmentData['assign_to'] ?? "";
      List<String> assignToIds = assignToStr
          .split(',')
          .map((e) => e.trim())
          .where((id) => id.isNotEmpty)
          .toList();

      // Fetch the namelist from the backend.
      final nameListResponse = await http.get(
        Uri.parse("http://192.168.205.45:5000/api/namelist"),
      );

      if (nameListResponse.statusCode == 200) {
        List<dynamic> nameList = json.decode(nameListResponse.body);
        // Prepare a map of id to name for easier lookup.
        Map<String, String> idNameMap = {};
        for (var entry in nameList) {
          // Convert the id into a string in case it comes as a number.
          idNameMap[entry['id'].toString()] = entry['name'];
        }

        // Create a rankingList that pairs each id with its display text.
        List<Map<String, String>> rankList = assignToIds.map((id) {
          return {
            "id": id,
            "display": idNameMap.containsKey(id)
                ? "$id - ${idNameMap[id]}"
                : id,
          };
        }).toList();

        setState(() {
          rankingList = rankList;
        });
      } else {
        print("Failed to fetch the namelist from the backend.");
      }
    } else {
      print("No assignment found on backend matching title: $clickedAssignmentTitle");
    }
  } else {
    print("Failed to fetch assignment details from the backend.");
  }
}
  void showAlreadySubmittedAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Already Submitted"),
          content:
              Text("You have already submitted the ranking for this task."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Build a card widget for each ranking dropdown.
 Widget _buildRankCard(int rankNumber) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Text(
            "Rank $rankNumber:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 20),
          Expanded(
            child: DropdownButton<String>(
              value: selectedRanks[rankNumber],
              isExpanded: true,
              hint: Text(
                "Select assign_to id",
                style: TextStyle(color: Colors.grey[600]),
              ),
              underline: SizedBox(),
              onChanged: (newValue) {
                setState(() {
                  selectedRanks[rankNumber] = newValue;
                });
              },
              items: rankingList.map((entry) {
                // Use the 'display' value if available, otherwise fallback to 'id'
                String displayText = entry['display'] ?? entry['id'];
                return DropdownMenuItem<String>(
                  value: entry['id'],
                  child: Text(displayText, style: TextStyle(fontSize: 16)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}
  // Build Task selection card.
  Widget _buildTaskSelectionCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Select Task",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedTask,
              hint: Text("Choose a task"),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  selectedTask = newValue;
                });
              },
              items: List.generate(numberOfTasks, (index) {
                return DropdownMenuItem<String>(
                  value: (index + 1).toString(),
                  child: Text("Task ${index + 1}"),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Build assignment details card after assignment selection.
  Widget _buildAssignmentDetailsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Selected Assignment:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text("${selectedAssignment!['title']}",
                style: TextStyle(fontSize: 16)),
            Divider(),
            Text("Number of Tasks: $numberOfTasks",
                style: TextStyle(fontSize: 16)),
            Text("Number of Ranks: $numberOfRanks",
                style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> submitRankings() async {
    if (selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a task")),
      );
      return;
    }

    // Check if all ranks are selected
    if (selectedRanks.values.any((rank) => rank == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select all ranks")),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/api/rank"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "assignment_id": selectedAssignment!['id'],
          "task_number": int.parse(selectedTask!),
          "rank_1": selectedRanks[1],
          "rank_2": selectedRanks[2],
          "rank_3": selectedRanks[3],
          "rank_4": selectedRanks[4],
          "rank_5": selectedRanks[5],
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rankings submitted successfully")),
        );
        setState(() {
          submittedTasks.add(selectedTask!);
          selectedTask = null;
          selectedRanks = {for (var i = 1; i <= numberOfRanks; i++) i: null};
        });
      } else {
        throw Exception('Failed to submit rankings');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit rankings: $e")),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no assignment is selected yet, show assignment selection UI.
    return Scaffold(
      appBar: AppBar(
        title: Text("Ranking Results"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: selectedAssignment == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Assignment",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: DropdownButton<String>(
                          value: null,
                          hint: Text("Choose assignment title"),
                          isExpanded: true,
                          underline: SizedBox(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              onAssignmentSelected(newValue);
                            }
                          },
                          items: assignmentsList.map((assignment) {
                            return DropdownMenuItem<String>(
                              value: assignment['title'],
                              child: Text(assignment['title'],
                                  style: TextStyle(fontSize: 16)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Once you select an assignment, its details (number of tasks, number of ranks, etc.) will be displayed below.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAssignmentDetailsCard(),
                    _buildTaskSelectionCard(),
                    SizedBox(height: 12),
                    Text(
                      "Ranking Positions",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    // Display ranking dropdown cards.
                    Expanded(
                      child: ListView.builder(
                        itemCount: numberOfRanks,
                        itemBuilder: (context, index) {
                          return _buildRankCard(index + 1);
                        },
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isSubmitting ? null : submitRankings,
                      child: isSubmitting
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text("Submit Ranking",
                              style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        backgroundColor:
                            const Color.fromARGB(255, 211, 222, 241),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ================================================================
// Dummy processAndStoreResults: update its logic as needed.
// ================================================================
Future<void> processAndStoreResults(int assignmentId, int taskNumber) async {
  final String rankApiUrl = "$apiBaseUrl/api/rank";
  final String resultApiUrl = "$apiBaseUrl/api/student_results";
  try {
    final response = await http.get(Uri.parse(rankApiUrl));
    if (response.statusCode != 200) {
      print("Failed to fetch rankings.");
      return;
    }
    List<dynamic> rankingData = json.decode(response.body);
    List<dynamic> taskRankings = rankingData.where((entry) =>
        entry['assignment_id'] == assignmentId &&
        entry['task_number'] == taskNumber).toList();
    if (taskRankings.isEmpty) {
      print("No rankings found for Assignment $assignmentId, Task $taskNumber");
      return;
    }
    Map<String, int> studentPoints = {};
    for (var ranking in taskRankings) {
      List<String> rankedStudents = [
        ranking['rank_1'],
        ranking['rank_2'],
        ranking['rank_3'],
        ranking['rank_4'],
        ranking['rank_5']
      ];
      List<int> points = [4, 3, 2, 1, 0];
      for (int i = 0; i < rankedStudents.length; i++) {
        if (rankedStudents[i] != null && rankedStudents[i].isNotEmpty) {
          studentPoints[rankedStudents[i]] =
              (studentPoints[rankedStudents[i]] ?? 0) + points[i];
        }
      }
    }
    double averagePoints =
        studentPoints.values.reduce((a, b) => a + b) / studentPoints.length;
    for (var entry in studentPoints.entries) {
      String studentName = entry.key;
      int totalPoints = entry.value;
      String resultStatus =
          totalPoints >= (0.5 * averagePoints) ? "Pass" : "Fail";
      final resultResponse = await http.post(
        Uri.parse(resultApiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "faculty_id": 17046,
          "total_points": totalPoints,
          "average_points": averagePoints,
          "result_status": resultStatus
        }),
      );
      if (resultResponse.statusCode == 200) {
        print("Result stored for $studentName: $resultStatus");
      } else {
        print("Failed to store result for $studentName");
      }
    }
  } catch (e) {
    print("Error processing results: $e");
  }
}

// ================================================================
// Main
// ================================================================
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.blue),
    home: CompletionPage(),
  ));
}