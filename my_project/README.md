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
      final response = await http.get(Uri.parse("$apiBaseUrl/api/assignment"));
      if (response.statusCode == 200) {
        List<dynamic> allAssignments = json.decode(response.body);
        // Filter assignments by checking if the logged in userId is in the assign_to list.
        setState(() {
          assignments = allAssignments.where((assignment) {
            final List<String> assignedUsers = (assignment['assign_to'] as String).split(',');
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
    final uri = Uri.parse("$apiBaseUrl/api/assignments")
        .replace(queryParameters: {'title': title});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List<dynamic> assignmentData = json.decode(response.body);
      if (assignmentData.isNotEmpty) {
        Map<String, dynamic> assignmentDetails = assignmentData[0];
        List<dynamic> taskDetails =
            json.decode(assignmentDetails['task_details'] ?? '[]');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssignmentDetailsPage(
              assignmentTitle: title,
              loggedInUserId: userId,
            ),
          ),
        );
      } else {
        showNoDetailsAlert();
      }
    } else {
      print("Failed to fetch assignment details");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch assignment details!")),
      );
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
                          style: TextStyle(color: Colors.black54, fontSize: 14),
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
  final String? loggedInUserId;
  const AssignmentDetailsPage({
    Key? key,
    required this.assignmentTitle,
    this.loggedInUserId,
  }) : super(key: key);
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
    final response = await http.get(Uri.parse("$apiBaseUrl/api/assignments"));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      final assignment = data.firstWhere(
        (assignment) =>
            (assignment['title'] as String).toLowerCase() ==
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
                  // On pressing start, we navigate to the TaskPage (timer & question page)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TaskPage(
                              allTasks: taskDetails,
                              currentIndex: 0,
                              loggedInUserId: widget.loggedInUserId,
                            )),
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
  final String? loggedInUserId;
  TaskPage({
    required this.allTasks,
    required this.currentIndex,
    this.loggedInUserId,
  });
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late int remainingTime;
  Timer? timer;
  List<String> displayedQuestions = [];

  @override
  void initState() {
    super.initState();
    var taskDetails = widget.allTasks[widget.currentIndex];
    String taskTimeStr = taskDetails['task_time'] ?? '0 min';
    int taskTime = int.tryParse(
            RegExp(r'\d+').firstMatch(taskTimeStr)?.group(0) ?? '0') ??
        0;
    remainingTime = taskTime * 60;
    fetchQuestions();
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

  Future<void> fetchQuestions() async {
    final response =
        await http.get(Uri.parse("$apiBaseUrl/api/questions"));
    if (response.statusCode == 200) {
      List<dynamic> questions = json.decode(response.body);
      if (questions.isNotEmpty) {
        questions.shuffle();
        setState(() {
          displayedQuestions = questions
              .take(5)
              .map((q) => q['question'] as String)
              .toList();
        });
      } else {
        setState(() {
          displayedQuestions = ["No new questions available"];
        });
      }
    } else {
      setState(() {
        displayedQuestions = ["Failed to load questions"];
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
            loggedInUserId: widget.loggedInUserId,
          ),
        ),
      );
    } else {
      // After all tasks are done, navigate to CompletionPage.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CompletionPage(
            loggedInUserId: widget.loggedInUserId ?? "",
          ),
        ),
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
            // Display questions in numbered format without using a Card view.
            Column(
              children: List.generate(displayedQuestions.length, (index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.8),
                          Colors.lightBlueAccent.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${index + 1}. ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            displayedQuestions[index],
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
// RankingPage: Handles step‐by‐step ranking for a single task.
// ================================================================
// This updated page displays dynamic dropdowns for each rank and removes candidates already selected.
// It also computes ranking scores in decimals, applying a negative deduction for ranks beyond third if more than three rankings are provided.
class RankingPage extends StatefulWidget {
  final String assignmentTitle;
  final int taskNumber;
  final List<String> candidateUserIds;
  final int numberOfRank; // fetched from API
  const RankingPage({
    Key? key,
    required this.assignmentTitle,
    required this.taskNumber,
    required this.candidateUserIds,
    required this.numberOfRank,
  }) : super(key: key);
  @override
  _RankingPageState createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  // Store selections as a mapping from rank (1 to numberOfRank) to candidate user id.
  Map<int, String?> rankingSelections = {};

  @override
  void initState() {
    super.initState();
    // Initialize all ranking selections to null.
    for (var i = 1; i <= widget.numberOfRank; i++) {
      rankingSelections[i] = null;
    }
  }

  // For a given rank, filter out already selected candidate user IDs (except the one already selected for that rank).
  List<String> availableOptions(int rank) {
    var alreadySelected = rankingSelections.entries
        .where((entry) => entry.value != null && entry.key != rank)
        .map((entry) => entry.value)
        .toSet();
    return widget.candidateUserIds
        .where((candidate) => !alreadySelected.contains(candidate))
        .toList();
  }

  void handleSubmit() {
    // Ensure that at least one rank is selected.
    if (rankingSelections.values.every((value) => value == null)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please select at least one candidate.")));
      return;
    }

// Count the number of non-null selections.
int countSelected =
    rankingSelections.values.where((value) => value != null).length;

// Compute scores for each candidate based on the rank.  
// Formula: baseScore = (numberOfRank + 1 - rank).
// If more than 3 ranks are provided, for ranks > 3 subtract 1.
Map<String, double> rankingScore = {};

rankingSelections.forEach((rank, candidate) {
  if (candidate != null) {
    double baseScore = widget.numberOfRank + 1 - rank.toDouble();
    if (countSelected > 3 && rank > 3) {
      baseScore = baseScore - 1.0;
    }
    rankingScore[candidate] = (rankingScore[candidate] ?? 0) + baseScore;
  }
});

// Here you can submit rankingScore along with other information to your backend API if desired.
// For demonstration, we simply pop and return the computed map.
Navigator.pop(context, rankingScore);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task ${widget.taskNumber} - Ranking"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Please rank the candidates",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Build dropdowns for each rank.
            Column(
              children: List.generate(widget.numberOfRank, (index) {
                int rank = index + 1;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text("Rank $rank:", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 20),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text("Select candidate"),
                          value: rankingSelections[rank],
                          items: availableOptions(rank).map((candidate) {
                            return DropdownMenuItem<String>(
                              value: candidate,
                              child: Text("User $candidate"),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              rankingSelections[rank] = val;
                            });
                          },
                        ),
                      )
                    ],
                  ),
                );
              }),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: handleSubmit,
              child: Text("Submit Ranking", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CompletionPage: Displays assignment details, task selection for ranking, and shows ranking results.
// ================================================================
class CompletionPage extends StatefulWidget {
  final String loggedInUserId;
  const CompletionPage({Key? key, required this.loggedInUserId})
      : super(key: key);
  @override
  _CompletionPageState createState() {
    print("loggedInUserId for completion: ${loggedInUserId}");
    return _CompletionPageState();
  }
}

class _CompletionPageState extends State<CompletionPage> {
  List<dynamic> assignmentsList = [];
  Map<String, dynamic>? selectedAssignment;
  int numberOfRanks = 0;
  int numberOfTasks = 0;
  String? selectedTask;
  // For each task (by task number) we store ranking results.
  Map<int, Map<String, double>> rankingResults = {};
  // Candidate list built from assign_to after excluding the logged-in user and faculty.
  List<String> candidateUserIds = [];
  bool isSubmitting = false;
  Set<String> submittedTasks = {};
  bool allRankingsCompleted = false; // Flag to indicate if all users have submitted their rankings

  @override
  void initState() {
    super.initState();
    fetchAssignmentsList();
    // You might also poll your backend here every few seconds/minutes to check if all ranking submissions are in.
  }

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

  void onAssignmentSelected(String title) {
    final assignment = assignmentsList.firstWhere(
      (assgn) =>
          (assgn['title'] as String).toLowerCase() ==
          title.toLowerCase(),
      orElse: () => null,
    );
    if (assignment != null) {
      setState(() {
        selectedAssignment = assignment;
        numberOfRanks = assignment['numberofranks'] ?? 0;
        numberOfTasks = assignment['numberoftasks'] ?? 0;
      });
      fetchCandidateUserIds();
    }
  }

  Future<void> fetchCandidateUserIds() async {
    if (selectedAssignment == null) return;
    String clickedAssignmentTitle =
        (selectedAssignment!['title'] ?? "").toString().toLowerCase();
    final assignmentResponse =
        await http.get(Uri.parse("$apiBaseUrl/api/assignment"));
    if (assignmentResponse.statusCode == 200) {
      List<dynamic> assignmentsDecoded = json.decode(assignmentResponse.body);
      Map<String, dynamic>? assignmentData = assignmentsDecoded.firstWhere(
        (assignment) =>
            ((assignment['title'] ?? "").toString().toLowerCase() ==
                clickedAssignmentTitle),
        orElse: () => null,
      );
      if (assignmentData != null) {
        String assignToStr = assignmentData['assign_to'] ?? "";
        List<String> assignToIds = assignToStr
            .split(',')
            .map((e) => e.trim())
            .where((id) => id.isNotEmpty)
            .toList();
        if (widget.loggedInUserId != null) {
          assignToIds.removeWhere((id) => id == widget.loggedInUserId);
        }
        String facultyIdFromApi = assignmentData['facultyId'].toString();
        assignToIds.removeWhere((id) => id == facultyIdFromApi);
        setState(() {
          candidateUserIds = assignToIds;
        });
      } else {
        print("No assignment found on backend matching title: $clickedAssignmentTitle");
      }
    } else {
      print("Failed to fetch assignment details from the backend.");
    }
  }

  Widget _buildTaskSelectionCard() {
    List<String> availableTasks = [];
    for (var i = 1; i <= numberOfTasks; i++) {
      String taskId = i.toString();
      if (!submittedTasks.contains(taskId)) {
        availableTasks.add(taskId);
      }
    }
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Select Task",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent),
                textAlign: TextAlign.center),
            SizedBox(height: 10),
            availableTasks.isEmpty
                ? Text("All tasks submitted",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey))
                : DropdownButton<String>(
                    value: selectedTask,
                    hint: Text("Choose a task"),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedTask = newValue;
                      });
                    },
                    items: availableTasks.map((taskId) {
                      return DropdownMenuItem<String>(
                        value: taskId,
                        child: Text("Task $taskId"),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRankingForTask(int taskNumber) async {
    final result = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (context) => RankingPage(
          assignmentTitle: selectedAssignment!['title'],
          taskNumber: taskNumber,
          candidateUserIds: candidateUserIds,
          numberOfRank: numberOfRanks,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        rankingResults[taskNumber] = result;
        submittedTasks.add(taskNumber.toString());
        selectedTask = null;
      });
    }
  }

  Widget _buildRankingResultsDisplay() {
    if (rankingResults.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text("No ranking done yet for any task."),
      );
    }
    return Expanded(
      child: ListView(
        children: rankingResults.entries.map((entry) {
          int taskNumber = entry.key;
          Map<String, double> userScores = entry.value;
          List<MapEntry<String, double>> sortedEntries = userScores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Task $taskNumber Ranking",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Divider(),
                  ...sortedEntries.asMap().entries.map((entry) {
                    int index = entry.key;
                    var result = entry.value;
                    return ListTile(
                      dense: true,
                      title: Text("User ID: ${result.key}"),
                      trailing: Text("Rank: ${index + 1}"),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // In a real-world application, you would poll or wait for your backend to confirm
  // that every expected ranking submission is in before marking the ranking as complete.
  // For this demonstration, we assume that a button click triggers validation.
  void checkIfAllRankingsComplete() {
    // Example: if the number of submitted tasks equals the expected numberOfTasks,
    // then set a flag.
    if (submittedTasks.length == numberOfTasks) {
      setState(() {
        allRankingsCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Call the check periodically or based on your backend’s status.
    checkIfAllRankingsComplete();
    return Scaffold(
      appBar: AppBar(
        title: Text("Ranking Submission"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.symmetric(vertical: 12),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Selected Assignment:",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
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
                    ),
                    _buildTaskSelectionCard(),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: selectedTask == null
                          ? null
                          : () {
                              int taskNum = int.parse(selectedTask!);
                              _openRankingForTask(taskNum);
                            },
                      child: Text(
                        "Rank Selected Task",
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        backgroundColor:
                            Color.fromARGB(255, 211, 222, 241),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // Display a message if not all rankings have been completed.
                    allRankingsCompleted
                        ? Text("All Rankings Completed!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent))
                        : Text("Ranking Under Process...",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: Colors.deepOrangeAccent)),
                    SizedBox(height: 10),
                    _buildRankingResultsDisplay(),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setState(() {
                                isSubmitting = true;
                              });
                              final payload = {
                                "assignment_title": selectedAssignment!['title'],
                                "results": rankingResults.map((task, resultMap) {
                                  return MapEntry(task.toString(), resultMap);
                                }),
                              };
                              try {
                                final response = await http.post(
                                    Uri.parse(
                                        "$apiBaseUrl/api/store_calculation"),
                                    headers: {"Content-Type": "application/json"},
                                    body: json.encode(payload));
                                if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Ranking results stored successfully.")));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Failed to store ranking results.")));
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e")));
                              } finally {
                                setState(() {
                                  isSubmitting = false;
                                });
                              }
                            },
                      child: isSubmitting
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text("Submit All Rankings",
                              style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        backgroundColor:
                            Color.fromARGB(255, 211, 222, 241),
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
// CalculationPage: Aggregates stored submissions and displays final ranking.
// ================================================================
class CalculationPage extends StatefulWidget {
  final String assignmentTitle;
  const CalculationPage({Key? key, required this.assignmentTitle})
      : super(key: key);
  @override
  CalculationPageState createState() => CalculationPageState();
}

class CalculationPageState extends State<CalculationPage> {
  List<dynamic> submissions = [];
  Map<int, Map<String, int>> calculatedResults = {};
  bool isLoading = false;
  bool isCalculating = false;
  final Map<String, int> pointsMapping = {
    "rank_1": 5,
    "rank_2": 4,
    "rank_3": 3,
    "rank_4": 2,
    "rank_5": 1,
  };

  @override
  void initState() {
    super.initState();
    fetchSubmissions();
  }

  Future<void> fetchSubmissions() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse("$apiBaseUrl/api/assignment_submissions"));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          submissions = data;
        });
      } else {
        print("Failed to fetch assignment submissions.");
      }
    } catch (e) {
      print("fetchSubmissions error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void calculateResults() {
    if (widget.assignmentTitle.isEmpty) return;
    setState(() {
      isCalculating = true;
      calculatedResults = {};
    });
    List<dynamic> filtered = submissions.where((submission) {
      return (submission["assignment_title"] as String).toLowerCase() ==
          widget.assignmentTitle.toLowerCase();
    }).toList();
    int numberOfTasks =
        filtered.isNotEmpty ? filtered[0]["number_of_tasks"] as int : 0;
    for (var task = 1; task <= numberOfTasks; task++) {
      List<dynamic> submissionsForTask = filtered.where((submission) {
        return submission["selected_task"] == task;
      }).toList();
      Map<String, int> taskScores = {};
      for (var submission in submissionsForTask) {
        for (int rank = 1; rank <= 5; rank++) {
          String fieldName = "rank$rank";
          if (submission.containsKey(fieldName)) {
            String userId = submission[fieldName].toString();
            int points = pointsMapping[fieldName] ?? 0;
            taskScores[userId] = (taskScores[userId] ?? 0) + points;
          }
        }
      }
      calculatedResults[task] = taskScores;
    }
    setState(() {
      isCalculating = false;
    });
  }

  Widget _buildResultsDisplay() {
    if (calculatedResults.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No calculations yet. Press 'Calculate' to compute results."),
      );
    }
    return Expanded(
      child: ListView(
        children: calculatedResults.entries.map((entry) {
          int taskNumber = entry.key;
          Map<String, int> userScores = entry.value;
          List<MapEntry<String, int>> sortedResults = userScores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Task $taskNumber Results",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Divider(),
                  ...sortedResults.asMap().entries.map((entry) {
                    int index = entry.key;
                    var result = entry.value;
                    return ListTile(
                      dense: true,
                      title: Text("User ID: ${result.key}"),
                      trailing: Text("Rank: ${index + 1}"),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calculation Page"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Assignment: ${widget.assignmentTitle}",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isCalculating ? null : calculateResults,
                      child: isCalculating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : Text("Calculate", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        backgroundColor: Color.fromARGB(255, 211, 222, 241),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildResultsDisplay(),
                  ],
                ),
              ),
            ),
    );
  }
}


















igDfbidfdfafimport 'package:flutter/material.dart';
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
        showSuccessDialog('Event Created Successfully');
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
        title: const Text("Create Event",
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
            labelText: "Event Title",
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