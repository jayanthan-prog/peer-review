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
        // Filter assignments based on whether the logged in user is in the assign_to list.
        setState(() {
          assignments = allAssignments.where((assignment) {
            final List<String> assignedUsers =
                (assignment['assign_to'] as String).split(',');
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
    // Before navigation we call the backend to get this assignment’s details
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
                          print(
                              "Assignment title clicked: $clickedAssignmentTitle");
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
          taskDetails = json.decode(assignmentDetails!['task_details'] ?? '[]');
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
// TaskPage: Handles each Task with a timer and dynamic question fetching.
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
    int taskTime =
        int.tryParse(RegExp(r'\d+').firstMatch(taskTimeStr)?.group(0) ?? '0') ??
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
    final response = await http.get(Uri.parse("$apiBaseUrl/api/questions"));
    if (response.statusCode == 200) {
      List<dynamic> questions = json.decode(response.body);
      if (questions.isNotEmpty) {
        questions.shuffle();
        setState(() {
          displayedQuestions =
              questions.take(5).map((q) => q['question'] as String).toList();
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
                              color: Colors.white),
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
class RankingPage extends StatefulWidget {
  final String assignmentTitle;
  final int taskNumber;
  final List<String> candidateUserIds;
  final int numberOfRank; // Example: 5 ranking options
  final String? loggedInUserId; // To identify the judge
  const RankingPage({
    Key? key,
    required this.assignmentTitle,
    required this.taskNumber,
    required this.candidateUserIds,
    required this.numberOfRank,
    required this.loggedInUserId,
  }) : super(key: key);
  @override
  _RankingPageState createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final List<String> rankingQuestions = [
    "Who is speaking best?",
    "Who presents most confidently?",
    "Who shows the best body language?",
    "Who engages the audience well?",
    "Who is most persuasive?"
  ];
  int currentQuestionIndex = 0;
  Map<int, Map<int, String?>> selectionsByQuestion = {};

  @override
  void initState() {
    super.initState();
    // Initialize selection map for the first question.
    selectionsByQuestion[currentQuestionIndex] = {};
    for (var i = 1; i <= widget.numberOfRank; i++) {
      selectionsByQuestion[currentQuestionIndex]![i] = null;
    }
  }

  Map<String, dynamic> convertSelection(Map<int, String?> selectionMap) {
    return selectionMap.map((key, value) => MapEntry("rank_$key", value));
  }

  Future<bool> submitRanking() async {
    final url = Uri.parse("$apiBaseUrl/api/submit_ranking");
    Map<String, dynamic> rankingSubmission = {
      "assignment_title": widget.assignmentTitle,
      "task_number": widget.taskNumber,
      "given_by": widget.loggedInUserId,
      "question1": convertSelection(selectionsByQuestion[0]!),
      "question2": convertSelection(selectionsByQuestion[1]!),
      "question3": convertSelection(selectionsByQuestion[2]!),
      "question4": convertSelection(selectionsByQuestion[3]!),
      "question5": convertSelection(selectionsByQuestion[4]!),
    };
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(rankingSubmission),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Ranking submission successful");
        return true;
      } else {
        print("Ranking submission failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error submitting ranking: $e");
      return false;
    }
  }

  bool validateCurrentQuestion() {
    return selectionsByQuestion[currentQuestionIndex]!
        .values
        .any((v) => v != null);
  }

  void handleNext() async {
    if (!validateCurrentQuestion()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Please select at least one candidate for this question.")));
      return;
    }
    if (currentQuestionIndex < rankingQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        if (!selectionsByQuestion.containsKey(currentQuestionIndex)) {
          selectionsByQuestion[currentQuestionIndex] = {};
          for (var i = 1; i <= widget.numberOfRank; i++) {
            selectionsByQuestion[currentQuestionIndex]![i] = null;
          }
        }
      });
    } else {
      bool success = await submitRanking();
      if (success) {
        Navigator.pop(context, {"ranking_submission": selectionsByQuestion});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed to submit ranking. Please try again.")));
      }
    }
  }

  void handlePrevious() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<int, String?> currentSelections =
        selectionsByQuestion[currentQuestionIndex]!;
    return Scaffold(
      appBar: AppBar(
        title: Text("Task ${widget.taskNumber} - Ranking"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(rankingQuestions[currentQuestionIndex],
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Column(
                children: List.generate(widget.numberOfRank, (index) {
                  int rank = index + 1;
                  List<String> options = widget.candidateUserIds.where((c) {
                    // Ensure candidate is not already selected in another rank.
                    var alreadySelected = currentSelections.entries
                        .where((e) => e.key != rank && e.value != null)
                        .map((e) => e.value)
                        .toSet();
                    return !alreadySelected.contains(c);
                  }).toList();
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
                            value: currentSelections[rank],
                            items: options
                                .map((candidate) => DropdownMenuItem<String>(
                                      value: candidate,
                                      child: Text("User $candidate"),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                currentSelections[rank] = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                      onPressed:
                          currentQuestionIndex > 0 ? handlePrevious : null,
                      child: Text("Previous", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)))),
                  ElevatedButton(
                      onPressed: handleNext,
                      child: Text(
                          currentQuestionIndex < rankingQuestions.length - 1
                              ? "Next Question"
                              : "Submit Ranking",
                          style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CompletionPage: Displays assignment details and task selection for ranking.
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
  Map<int, Map<String, dynamic>> rankingResults = {};
  List<String> candidateUserIds = [];
  bool isSubmitting = false;
  Set<String> submittedTasks = {};
  bool allRankingsCompleted = false;

  @override
  void initState() {
    super.initState();
    fetchAssignmentsList();
  }

  Future<void> fetchAssignmentsList() async {
    final response = await http.get(Uri.parse("$apiBaseUrl/api/assignments"));
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
          (assgn['title'] as String).toLowerCase() == title.toLowerCase(),
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
        (assignment) => ((assignment['title'] ?? "").toString().toLowerCase() ==
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
        print(
            "No assignment found on backend matching title: $clickedAssignmentTitle");
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => RankingPage(
          assignmentTitle: selectedAssignment!['title'],
          taskNumber: taskNumber,
          candidateUserIds: candidateUserIds,
          numberOfRank: numberOfRanks,
          loggedInUserId: widget.loggedInUserId,
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

  void checkIfAllRankingsComplete() {
    if (submittedTasks.length == numberOfTasks) {
      setState(() {
        allRankingsCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                    fontSize: 18, fontWeight: FontWeight.bold)),
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
                        "Select Ranking",
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        backgroundColor: Color.fromARGB(255, 211, 222, 241),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    allRankingsCompleted
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CalculationPage(
                                      assignmentTitle:
                                          selectedAssignment!['title']),
                                ),
                              );
                            },
                            child: Text("Calculate Final Ranking",
                                style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 20),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        : Text(
                            "Ranking Under Process...\nPlease wait until all users have ranked.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: Colors.deepOrangeAccent)),
                  ],
                ),
        ),
      ),
    );
  }
}

class CalculationPage extends StatefulWidget {
  final String assignmentTitle;
  final String? loggedInUserId; // Added to check candidate’s marks

  const CalculationPage({
    Key? key,
    required this.assignmentTitle,
    this.loggedInUserId,
  }) : super(key: key);

  @override
  CalculationPageState createState() => CalculationPageState();
}
class CalculationPageState extends State<CalculationPage> {
  List<dynamic> submissions = [];
  // Map: task_number -> Map(candidateID -> totalScore)
  Map<int, Map<String, double>> calculatedResults = {};
  bool isLoading = false;
  bool isCalculating = false;
  bool isSubmittingData = false;
  // Ranking points mapping.
  final Map<int, double> rankPoints = {
    1: 5.01,
    2: 4.00,
    3: 3.23,
    4: 2.01,
    5: 1.0987654,
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
      final response = await http.get(
          Uri.parse("$apiBaseUrl/api/submit_ranking"));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          submissions = data;
        });
      } else {
        print("Failed to fetch ranking submissions.");
      }
    } catch (e) {
      print("fetchSubmissions error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Calculate final results from ranking submissions.
  void calculateResults() {
    if (widget.assignmentTitle.isEmpty) return;
    setState(() {
      isCalculating = true;
      calculatedResults = {};
    });
    // Filter submissions matching current assignment title (case-insensitive)
    List<dynamic> filtered = submissions.where((submission) {
      return (submission["assignment_title"] as String)
              .toLowerCase() ==
          widget.assignmentTitle.toLowerCase();
    }).toList();

    // Group by task_number.
    Map<int, List<dynamic>> tasks = {};
    for (var submission in filtered) {
      int taskNumber = submission["task_number"];
      tasks.putIfAbsent(taskNumber, () => []).add(submission);
    }
    tasks.forEach((taskNumber, submissionsForTask) {
      Map<String, double> candidateScores = {};
      for (var submission in submissionsForTask) {
        for (int q = 1; q <= 5; q++) {
          String qKey = "question$q";
          if (submission[qKey] != null) {
            Map<String, dynamic> rankingMap;
            try {
              rankingMap = json.decode(submission[qKey]);
            } catch (e) {
              print(
                  "Error decoding $qKey in submission id ${submission['id']}: $e");
              continue;
            }
            rankingMap.forEach((rankKey, candidateId) {
              if (candidateId != null &&
                  candidateId.toString().isNotEmpty) {
                int rankNumber =
                    int.tryParse(rankKey.replaceAll("rank_", "")) ?? 0;
                if (rankNumber > 0 && rankPoints.containsKey(rankNumber)) {
                  candidateScores[candidateId.toString()] =
                      (candidateScores[candidateId.toString()] ?? 0) +
                          (rankPoints[rankNumber] ?? 0);
                  print(
                      "Task $taskNumber, Question $q: Awarding ${rankPoints[rankNumber]} points to candidate ${candidateId.toString()} (rank $rankNumber)");
                }
              }
            });
          }
        }
      }
      calculatedResults[taskNumber] = candidateScores;
    });
    setState(() {
      isCalculating = false;
    });
    print("Final Calculated Results: $calculatedResults");
  }

  // This function aggregates the marks for each candidate across tasks.
  Map<String, double> _aggregateCandidateScores() {
    Map<String, double> candidateTotals = {};
    calculatedResults.forEach((_, candidateScores) {
      candidateScores.forEach((candidateId, score) {
        candidateTotals[candidateId] =
            (candidateTotals[candidateId] ?? 0) + score;
      });
    });
    return candidateTotals;
  }

//   // After calculating final scores and submitting final ranking, check for pass/fail.
//  void _showPassFailAlert() {
//   Map<String, double> candidateTotals = _aggregateCandidateScores();
//   if (candidateTotals.isEmpty) return;
//   // Assume the logged in candidate's score is associated with widget.loggedInUserId.
//   double candidateScore = candidateTotals[widget.loggedInUserId] ?? 0;
//   // Use a threshold of 10 to decide pass/fail.
//   String status = candidateScore < 10 ? "Fail" : "Pass";
//   showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: Text("Final Result"),
//         content: Text("You are $status!"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("OK"),
//           ),
//         ],
//       );
//     },
//   );
// }

  /// This function now builds a payload and submits the ranking.
  void _showPassFailAlert() {
  Map<String, double> candidateTotals = _aggregateCandidateScores();
  if (candidateTotals.isEmpty) return;
  double candidateScore = candidateTotals[widget.loggedInUserId] ?? 0;
  // For instance, here we assume candidateScore < 10 is Pass and >= 10 is Fail.
  // (Modify the condition/stats per your logic.)
  String status = candidateScore < 10 ? "Pass" : "Fail";
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Final Result"),
        content: Text("You are $status!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dismiss the first alert.
              // After dismissing the final result, show a second dialog:
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Event Completed"),
                    content: Text("You have successfully completed the event."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Dismiss the completion message.
                          // Optionally, navigate to another page if required.
                        },
                        child: Text("OK"),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text("OK"),
          ),
        ],
      );
    },
  );
}

  Future<void> submitFinalRanking() async {
    if (calculatedResults.isEmpty) return;
    setState(() {
      isSubmittingData = true;
    });
    List<Map<String, dynamic>> submissionsToPost = [];
    calculatedResults.forEach((taskNumber, candidateScores) {
      // Sort candidate entries descending by marks.
      List<MapEntry<String, double>> sortedEntries = candidateScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (var i = 0; i < sortedEntries.length; i++) {
        String candidateId = sortedEntries[i].key;
        double score = sortedEntries[i].value;
        submissionsToPost.add({
          "assignment_title": widget.assignmentTitle,
          "task_number": taskNumber,
          "candidate_id": candidateId,
          "marks": score,
          "created_at": DateTime.now().toIso8601String(),
        });
      }
    });

    final url = Uri.parse("$apiBaseUrl/api/assignment_results");
    bool allSuccessful = true;
    // Loop through each record and post them one-by-one.
    for (var record in submissionsToPost) {
      print("Record to post: ${json.encode(record)}");
      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: json.encode(record),
        );
        print("Response body: ${response.body}");
        if (response.statusCode != 200 && response.statusCode != 201) {
          allSuccessful = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to submit a record. Error: ${response.statusCode}")),
          );
        }
      } catch (e) {
        print("Error submitting record: $e");
        allSuccessful = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting a record.")),
        );
      }
    }
    if (allSuccessful) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Final rankings submitted successfully.")),
      );
      _showPassFailAlert();
    }
    setState(() {
      isSubmittingData = false;
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
          Map<String, double> candidateScores = entry.value;
          List<MapEntry<String, double>> sortedResults = candidateScores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Task $taskNumber Results",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Divider(),
                  ...sortedResults.asMap().entries.map((mapEntry) {
                    int index = mapEntry.key;
                    MapEntry<String, double> result = mapEntry.value;
                    return ListTile(
                      dense: true,
                      title: Text("User ID: ${result.key}"),
                      trailing: Text("Rank: ${index + 1}",
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Text("Assignment: ${widget.assignmentTitle}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        backgroundColor: Color.fromARGB(255, 211, 222, 241),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildResultsDisplay(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed:
                          (calculatedResults.isNotEmpty && !isSubmittingData)
                              ? submitFinalRanking
                              : null,
                      child: isSubmittingData
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : Text("Submit Final Ranking", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
class FinalRankingPage extends StatefulWidget {
  final String assignmentTitle;
  final String loggedInUserId;

  const FinalRankingPage({
    Key? key,
    required this.assignmentTitle,
    required this.loggedInUserId,
  }) : super(key: key);

  @override
  _FinalRankingPageState createState() => _FinalRankingPageState();
}

class _FinalRankingPageState extends State<FinalRankingPage> {
  bool isLoading = false;
  double candidateScore = 0;
  String status = "";

  @override
  void initState() {
    super.initState();
    fetchFinalRanking();
  }

  Future<void> fetchFinalRanking() async {
    setState(() {
      isLoading = true;
    });
    try {
      final url = Uri.parse("$apiBaseUrl/api/assignment_results");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        double totalMarks = 0;
        for (var record in data) {
          if (record["assignment_title"].toString().toLowerCase() ==
                  widget.assignmentTitle.toLowerCase() &&
              record["candidate_id"].toString() == widget.loggedInUserId) {
            totalMarks += double.tryParse(record["marks"].toString()) ?? 0;
          }
        }
        setState(() {
          candidateScore = totalMarks;
          status = (candidateScore < 10) ? "Fail" : "Pass";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch final ranking details!")),
        );
      }
    } catch (e) {
      print("Error fetching final ranking: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching final ranking details.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Final Ranking Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Assignment: ${widget.assignmentTitle}",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Text("Your final score: ${candidateScore.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  Text("Status: $status",
                      style: TextStyle(
                          fontSize: 18,
                          color: status == "Pass" ? Colors.green : Colors.red)),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // This will close the current page
                    },
                    child: Text("Close Event", style: TextStyle(fontSize: 18)),
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