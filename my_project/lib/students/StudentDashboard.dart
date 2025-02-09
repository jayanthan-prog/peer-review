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
// Use widget.loggedInUserId for the completion page
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => CompletionPage(
      loggedInUserId: widget.allTasks[0]['assign_to'].toString(),
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

class CompletionPage extends StatefulWidget {
  final String loggedInUserId;
  const CompletionPage({Key? key, required this.loggedInUserId}) : super(key: key);

  @override
  _CompletionPageState createState() {
    print("loggedInUserId for completion: ${loggedInUserId}");
    return _CompletionPageState();
  }
}

class _CompletionPageState extends State<CompletionPage> {
  List<dynamic> assignmentsList = [];
  Map<String, dynamic>? selectedAssignment;
  List<Map<String, dynamic>> rankingList = [];
  int numberOfRanks = 0;
  int numberOfStudents = 0;
  int numberOfTasks = 0;
  String? selectedTask;
  Map<int, String?> selectedRanks = {};
  bool isSubmitting = false;
  Set<String> submittedTasks = {};

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
      (assgn) => assgn['title'].toString().toLowerCase() == title.toLowerCase(),
      orElse: () => null,
    );
    if (assignment != null) {
      setState(() {
        selectedAssignment = assignment;
        numberOfRanks = assignment['numberofranks'] ?? 0;
        numberOfTasks = assignment['numberoftasks'] ?? 0;
        numberOfStudents = assignment['number_of_students'] ?? 0;
        selectedRanks = {for (var i = 1; i <= numberOfRanks; i++) i: null};
      });
      fetchAssignToIds();
    }
  }

  Future<void> fetchAssignToIds() async {
    if (selectedAssignment == null) return;
    String clickedAssignmentTitle = (selectedAssignment!['title'] ?? "").toString().toLowerCase();
    final assignmentResponse = await http.get(Uri.parse("$apiBaseUrl/api/assignment"));
    if (assignmentResponse.statusCode == 200) {
      List<dynamic> assignmentsDecoded = json.decode(assignmentResponse.body);
      Map<String, dynamic>? assignmentData = assignmentsDecoded.firstWhere(
        (assignment) => (assignment['title'] ?? "").toString().toLowerCase() == clickedAssignmentTitle,
        orElse: () => null,
      );
      if (assignmentData != null) {
        String assignToStr = assignmentData['assign_to'] ?? "";
        List<String> assignToIds = assignToStr.split(',')
            .map((e) => e.trim())
            .where((id) => id.isNotEmpty)
            .toList();
        final nameListResponse = await http.get(Uri.parse("$apiBaseUrl/api/namelist"));
        if (nameListResponse.statusCode == 200) {
          List<dynamic> nameList = json.decode(nameListResponse.body);
          Map<String, String> idNameMap = {};
          for (var entry in nameList) {
            idNameMap[entry['id'].toString()] = entry['name'];
          }
          List<Map<String, String>> rankList = assignToIds.map((id) {
            return {
              "id": id,
              "display": idNameMap.containsKey(id) ? "$id - ${idNameMap[id]}" : id,
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
          content: Text("You have already submitted the ranking for this task."),
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

  Widget _buildRankCard(int rankNumber) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Text("Rank $rankNumber:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 20),
            Expanded(
              child: DropdownButton<String>(
                value: selectedRanks[rankNumber],
                isExpanded: true,
                hint: Text("Select assign_to id", style: TextStyle(color: Colors.grey[600])),
                underline: SizedBox(),
                onChanged: (newValue) {
                  setState(() {
                    selectedRanks[rankNumber] = newValue;
                  });
                },
                items: rankingList.map((entry) {
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Select Task",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
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
            Text("${selectedAssignment!['title']}", style: TextStyle(fontSize: 16)),
            Divider(),
            Text("Number of Tasks: $numberOfTasks", style: TextStyle(fontSize: 16)),
            Text("Number of Ranks: $numberOfRanks", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<String?> _showFacultyIdDialog() async {
    TextEditingController facultyController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Faculty ID"),
          content: TextField(
            controller: facultyController,
            decoration: InputDecoration(
              hintText: "Faculty ID",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String enteredId = facultyController.text.trim();
                if (enteredId.isNotEmpty) {
                  Navigator.of(context).pop(enteredId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter a valid Faculty ID")));
                }
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> submitRankings() async {
    if (selectedTask == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please select a task")));
      return;
    }
    if (selectedRanks.values.any((rank) => rank == null)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please select all ranks")));
      return;
    }
    List<String?> selectedValues = selectedRanks.values.toList();
    if (selectedValues.toSet().length != selectedValues.length) {
      showDuplicateEntryAlert();
      return;
    }
    setState(() {
      isSubmitting = true;
    });
    // Ask for Faculty ID before posting
    String? facultyId = await _showFacultyIdDialog();
    if (facultyId == null || facultyId.isEmpty) {
      setState(() {
        isSubmitting = false;
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/api/assignment_submissions"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "assignment_id": selectedAssignment!['id'],
          "assignment_title": selectedAssignment!['title'],
          "number_of_tasks": numberOfTasks,
          "number_of_ranks": numberOfRanks,
          "selected_task": int.parse(selectedTask!),
          "assign_by": facultyId,
          "rank_1": selectedRanks[1],
          "rank_2": selectedRanks[2],
          "rank_3": selectedRanks[3],
          "rank_4": selectedRanks[4],
          "rank_5": selectedRanks[5],
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Rankings submitted successfully")));
        setState(() {
          submittedTasks.add(selectedTask!);
          selectedTask = null;
          selectedRanks = {for (var i = 1; i <= numberOfRanks; i++) i: null};
        });
        // After submission, ask if the user wants to calculate results
        _askCalculateResults();
      } else {
        throw Exception('Failed to submit rankings');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to submit rankings: $e")));
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void showDuplicateEntryAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Duplicate Entry"),
          content: Text(
              "Duplicate assign_to id entries are not allowed. Please select different ids for each rank."),
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

  // After submission, ask the user if they want to calculate the results.
  void _askCalculateResults() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Calculate Results"),
          content: Text("Do you want to calculate the final ranking results now?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Stay on page
              child: Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to the CalculationPage, passing the assignment title so that the calculation page
                // can filter records by the chosen assignment. You may pass additional parameters if you wish.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalculationPage(
                      assignmentTitle: selectedAssignment!['title'],
                    ),
                  ),
                );
              },
              child: Text("Yes"),
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
        title: Text("Ranking Submission"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: selectedAssignment == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Assignment",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Card(
                      elevation: 3,
                      shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              child:
                                  Text(assignment['title'], style: TextStyle(fontSize: 16)),
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
                    Text("Ranking Positions",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        textAlign: TextAlign.center),
                    SizedBox(height: 10),
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
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Submit Ranking", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        backgroundColor: const Color.fromARGB(255, 211, 222, 241),
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

/// CalculationPage: This page retrieves all submission records, calculates the points
/// for each task and user for the chosen assignment, and then displays the results.
class CalculationPage extends StatefulWidget {
  final String assignmentTitle;
  const CalculationPage({Key? key, required this.assignmentTitle}) : super(key: key);

  @override
  _CalculationPageState createState() => _CalculationPageState();
}

class _CalculationPageState extends State<CalculationPage> {
  List<dynamic> submissions = [];
  Map<int, Map<String, int>> calculatedResults = {};
  bool isLoading = false;
  bool isCalculating = false;

  // Define point mapping for ranks.
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
      final response =
          await http.get(Uri.parse("$apiBaseUrl/api/assignment_submissions"));
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

    // Filter submissions based on selected assignment title.
    List<dynamic> filtered = submissions.where((submission) {
      return (submission["assignment_title"] as String).toLowerCase() ==
          widget.assignmentTitle.toLowerCase();
    }).toList();

    // Assume that all submissions for the same assignment share the same number_of_tasks.
    int numberOfTasks = filtered.isNotEmpty ? filtered[0]["number_of_tasks"] as int : 0;

    // Loop for each task.
    for (var task = 1; task <= numberOfTasks; task++) {
      List<dynamic> submissionsForTask = filtered.where((submission) {
        return submission["selected_task"] == task;
      }).toList();
      Map<String, int> taskScores = {};
      // For each submission for that task, add scores based on rank fields.
      for (var submission in submissionsForTask) {
        for (int rank = 1; rank <= 5; rank++) {
          String fieldName = "rank_$rank";
          if (submission.containsKey(fieldName)) {
            String userId = submission[fieldName].toString();
            int points = pointsMapping[fieldName] ?? 0;
            taskScores[userId] = (taskScores[userId] ?? 0) + points;
          }
        }
      }
      calculatedResults[task] = taskScores;
    }

    // Optionally: Call storeResults(calculatedResults) here to persist calculated results to the backend.
    setState(() {
      isCalculating = false;
    });
  }

  // Example: Store calculated results in a backend SQL table if needed.
  Future<void> storeResults(Map<int, Map<String, int>> results) async {
    final payload = {
      "assignment_title": widget.assignmentTitle,
      "results": results,
    };
    try {
      final response = await http.post(Uri.parse("$apiBaseUrl/api/store_calculation"),
          headers: {"Content-Type": "application/json"}, body: json.encode(payload));
      if (response.statusCode == 200) {
        print("Calculation results stored successfully.");
      } else {
        print("Failed to store calculation results.");
      }
    } catch (e) {
      print("storeResults error: $e");
    }
  }

  Widget _buildResultsDisplay() {
    if (calculatedResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("No calculations yet. Press 'Calculate' to compute results."),
      );
    }
    return Expanded(
      child: ListView(
        children: calculatedResults.entries.map((entry) {
          int taskNumber = entry.key;
          Map<String, int> userScores = entry.value;
          var sortedResults = userScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Task $taskNumber Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Divider(),
                  ...sortedResults.map((result) {
                    return ListTile(
                      dense: true,
                      title: Text("User ID: ${result.key}"),
                      trailing: Text("Points: ${result.value}"),
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
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Assignment: ${widget.assignmentTitle}",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          isCalculating ? null : calculateResults,
                      child: isCalculating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white))
                          : Text("Calculate", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        backgroundColor: Color.fromARGB(255, 211, 222, 241),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

/// main() function to run the app. Adjust routes and initialPage as needed.
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CompletionPage(loggedInUserId: "12345"),
  ));
}