import 'package:flutter/material.dart'; 
import 'dart:convert'; 
import 'package:http/http.dart'as http;
 import 'dart:async'; 
 import 'package:my_project/config.dart'; 
 import 'dart:math'; // Import this to use Random

class StudentDashboard extends StatefulWidget { 
  final String? loggedInUserId; // Define the named parameter 
  // Constructor to accept the loggedInUserId 
  const StudentDashboard({Key? key, this.loggedInUserId}) : super(key: key); 
  @override 
  // ignore: library_private_types_in_public_api 
  _StudentDashboardState createState() => _StudentDashboardState(); 
} 
class _StudentDashboardState extends State<StudentDashboard> { 
  List assignments = []; 
  String? userId;
  bool isLoading = false;
  @override 
 void initState() { 
    super.initState(); 
    userId = widget.loggedInUserId; // Store the logged-in user ID 
    print("Logged In User ID: $userId"); // Debug print to check the value 
    fetchAssignments(); 
  } 
Future<void> fetchAssignments() async {
  setState(() {
    isLoading = true; // Show loading indicator
  });

  try {
    final response = await http.get(Uri.parse("$apiBaseUrl/api/assignment"));
    if (response.statusCode == 200) {
      List<dynamic> allAssignments = json.decode(response.body);
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
      isLoading = false; // Hide loading indicator
    });
  }
}
void navigateToAssignmentDetails(String title) async { 
  final String apiUrl = "http://192.168.205.45:5000/api/assignments?title=$title"; 
  final response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode == 200) { 
    List<dynamic> assignmentData = json.decode(response.body); 
    if (assignmentData.isNotEmpty) { 
      Map<String, dynamic> assignmentDetails = assignmentData[0]; 
      List<dynamic> taskDetails = json.decode(assignmentDetails['task_details'] ?? '[]'); 
      // Pass the task details to AssignmentDetailsPage 
     Navigator.push( 
  context, 
  MaterialPageRoute( 
    builder: (context) => AssignmentDetailsPage(assignmentTitle: title), 
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
        title: Text("Student Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),), 
        backgroundColor: Colors.blueAccent, 
      ), 
      body: assignments.isEmpty 
          ? Center(child: CircularProgressIndicator()) 
          : ListView.builder( 
              itemCount: assignments.length, 
              itemBuilder: (context, index) { 
                var assignment = assignments[index]; 
                return Card( 
                  margin: EdgeInsets.all(10), 
                  elevation: 1.5, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                  child: ListTile( 
                    contentPadding: EdgeInsets.all(16), 
                    title: Text( 
                      assignment['title'], 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), 
                    ), 
                    subtitle: Text( 
                      "Start: ${assignment['start_time']} - Stop: ${assignment['stop_time']}", 
                      style: TextStyle(color: Colors.black54, fontSize: 14), 
                    ), 
                    trailing: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.blueAccent), 
                    onTap: () => navigateToAssignmentDetails(assignment['title']), 
                  ), 
                ); 
              }, 
            ), 
    ); 
  } 
} 
class AssignmentDetailsPage extends StatefulWidget { 
  final String assignmentTitle; 
  const AssignmentDetailsPage({Key? key, required this.assignmentTitle}) : super(key: key); 
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
    final response = await http.get(Uri.parse("http://192.168.205.45:5000/api/assignments"));
    if (response.statusCode == 200) { 
      List<dynamic> data = json.decode(response.body); 
      // Find assignment by title 
      final assignment = data.firstWhere( 
        (assignment) => assignment['title'].toLowerCase() == widget.assignmentTitle.toLowerCase(), 
        orElse: () => null, 
      ); 
      if (assignment != null) { 
        setState(() { 
          assignmentDetails = assignment; 
          // Decode task_details string 
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                child: Padding( 
                  padding: EdgeInsets.all(16), 
                  child: Column( 
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [ 
                      Text("📌 Explanation:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
                      Text(assignmentDetails!['explanation'], style: TextStyle(fontSize: 16)), 
                      Divider(), 
                      Text("📅 Date: ${assignmentDetails!['date']}", style: TextStyle(fontSize: 16)), 
                      Text("⏰ Start Time: ${assignmentDetails!['start_time']}", style: TextStyle(fontSize: 16)), 
                      Text("🛑 Stop Time: ${assignmentDetails!['stop_time']}", style: TextStyle(fontSize: 16)), 
                      Text("⏳ Total Time: ${assignmentDetails!['total_time']}", style: TextStyle(fontSize: 16)), 
                    ], 
                  ), 
                ), 
              ), 
              SizedBox(height: 10), 
              Text("📌 Tasks:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
              ...taskDetails.map((task) => Card( 
                elevation: 1.5, 
                margin: EdgeInsets.symmetric(vertical: 5), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
                child: ListTile( 
                  leading: Icon(Icons.task, color: Colors.blueAccent), 
                  title: Text(task['task_title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                  subtitle: Text("⏳ Duration: ${task['task_time']}", style: TextStyle(fontSize: 14)), 
                ), 
              )), 
              SizedBox(height: 40), 
              ElevatedButton( 
                onPressed: () { 
                  Navigator.push( 
                    context, 
                    MaterialPageRoute( 
                      builder: (context) => TaskPage(allTasks: taskDetails, currentIndex: 0), 
                    ), 
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
  @override 
void initState() { 
  super.initState(); 
  var taskDetails = widget.allTasks[widget.currentIndex]; 
  // Handle null values safely 
  String taskTimeStr = taskDetails['task_time'] ?? '0 min'; 
  int taskTime = int.tryParse(RegExp(r'\d+').firstMatch(taskTimeStr)?.group(0) ?? '0') ?? 0; 
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
 
  List<int> displayedQuestionIds = []; // List to keep track of displayed question IDs

Future<void> fetchQuestion() async { 
    final response = await http.get(Uri.parse("$apiBaseUrl/api/questions"));
    
    if (response.statusCode == 200) { 
        List<dynamic> questions = json.decode(response.body); 
        
        // Filter out already displayed questions
        questions = questions.where((q) => !displayedQuestionIds.contains(q['id'])).toList();
        
        if (questions.isNotEmpty) { 
            // Randomly select a question from the remaining questions
            final randomIndex = Random().nextInt(questions.length);
            setState(() { 
                displayedQuestion = questions[randomIndex]['question']; 
                displayedQuestionIds.add(questions[randomIndex]['id']); // Add the displayed question ID to the list
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent), 
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
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
              child: Text(widget.currentIndex + 1 < widget.allTasks.length ? "Next Task" : "Finish"), 
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
  @override 
  _CompletionPageState createState() => _CompletionPageState(); 
} 
class _CompletionPageState extends State<CompletionPage> { 
  List<Map<String, dynamic>> rankingList = []; 
  int numberOfRanks = 0; 
  int numberOfStudents = 0; 
  int numberOfTasks = 0; 
  String? selectedTask; 
  bool isSubmitting = false; 
  Set<String> submittedTasks = {}; // Track submitted tasks 
  TextEditingController facultyIdController = TextEditingController(); 
  bool isFacultyValid = false; // Track faculty ID validation 
  @override 
  void initState() { 
    super.initState(); 
    fetchAssignmentDetails(); 
  } 
  Future<void> fetchAssignmentDetails() async { 
    final response = await http.get(Uri.parse("$apiBaseUrl/api/assignments"));
    if (response.statusCode == 200) { 
      List<dynamic> data = json.decode(response.body); 
      if (data.isNotEmpty) { 
        setState(() { 
          numberOfRanks = data[0]['numberofranks'] ?? 0; 
          numberOfStudents = data[0]['number_of_students'] ?? 0; 
          numberOfTasks = data[0]['numberoftasks'] ?? 0; 
        }); 
        fetchStudentNames(); 
      } 
    } 
  } 
  Future<void> fetchStudentNames() async { 
    final response = await http.get(Uri.parse("$apiBaseUrl/api/namelist"));
    if (response.statusCode == 200) { 
      List<dynamic> studentsData = json.decode(response.body); 
      List<Map<String, dynamic>> tempList = []; 
      for (int i = 0; i < numberOfStudents && i < studentsData.length; i++) { 
        tempList.add({"name": studentsData[i]['name'] ?? "Unknown Student"}); 
      } 
      setState(() { 
        rankingList = tempList; 
      }); 
    } 
  } 
  Future<void> validateFacultyId() async { 
    final String facultyId = facultyIdController.text.trim(); 
    if (facultyId.isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter Faculty ID"))); 
      return; 
    } 
    final response = await http.get(Uri.parse("$apiBaseUrl/api/student"));
    if (response.statusCode == 200) { 
      List<dynamic> facultyList = json.decode(response.body); 
      bool isValid = facultyList.any((faculty) => faculty['facultyId'].toString() == facultyId); 
      if (isValid) { 
        setState(() { 
          isFacultyValid = true; 
        }); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Faculty ID validated successfully!"))); 
      } else { 
        setState(() { 
          isFacultyValid = false; 
        }); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid Faculty ID!"))); 
      } 
    } 
  } 
 Future<void> submitRankings() async { 
  if (!isFacultyValid) { 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please validate Faculty ID first!"))); 
    return; 
  } 
  if (selectedTask == null) { 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a task!"))); 
    return; 
  } 
  if (submittedTasks.contains(selectedTask)) { 
    showAlreadySubmittedAlert(); 
    return; 
  } 
  setState(() { 
    isSubmitting = true; 
  }); 
  final url = "$apiBaseUrl/api/rank"; 
  final response = await http.post(
    Uri.parse(url), 
    headers: {"Content-Type": "application/json"}, 
    body: json.encode({ 
      "assignment_id": 1, 
      "faculty_id": int.parse(facultyIdController.text), 
      "task_number": selectedTask, 
      "rank_1": rankingList.isNotEmpty ? rankingList[0]['name'] : "", 
      "rank_2": rankingList.length > 1 ? rankingList[1]['name'] : "", 
      "rank_3": rankingList.length > 2 ? rankingList[2]['name'] : "", 
      "rank_4": rankingList.length > 3 ? rankingList[3]['name'] : "", 
      "rank_5": rankingList.length > 4 ? rankingList[4]['name'] : "", 
    }), 
  ); 
  setState(() { 
    isSubmitting = false; 
  }); 
  if (response.statusCode == 201) { 
    submittedTasks.add(selectedTask!); 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ranking submitted successfully!"))); 
    // Call processAndStoreResults after successful submission 
    processAndStoreResults(101, 1); 
    // fetchResults(); // Fetch results after processing 
  } else { 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to submit ranking."))); 
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
  void navigateToResultPage() { 
    Navigator.push( 
      context, 
      MaterialPageRoute( 
        builder: (context) => ResultPage(), 
      ), 
    ); 
  } 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar(title: Text("Ranking Results"), backgroundColor: Colors.blueAccent), 
      body: Padding( 
        padding: EdgeInsets.all(16.0), 
        child: Column( 
          children: [ 
            TextField( 
              controller: facultyIdController, 
              decoration: InputDecoration( 
                labelText: "Enter Faculty ID", 
                border: OutlineInputBorder(), 
              ), 
              keyboardType: TextInputType.number, 
            ), 
            SizedBox(height: 10), 
            ElevatedButton( 
              onPressed: validateFacultyId, 
              child: Text("Validate  ID"), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), 
            ), 
            SizedBox(height: 20), 
            Text("Select Task", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
            DropdownButton<String>( 
              value: selectedTask, 
              hint: Text("Choose a task"), 
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
            SizedBox(height: 20), 
            Expanded( 
              child: rankingList.isEmpty 
                  ? Center(child: CircularProgressIndicator()) 
                  : ReorderableListView( 
                      onReorder: (oldIndex, newIndex) { 
                        setState(() { 
                          if (newIndex > oldIndex) newIndex -= 1; 
                          final item = rankingList.removeAt(oldIndex); 
                          rankingList.insert(newIndex, item); 
                        }); 
                      }, 
                      children: rankingList.map((entry) => ListTile( 
                        key: ValueKey(entry['name']), 
                        title: Text(entry['name']), 
                        trailing: Icon(Icons.drag_handle), 
                      )).toList(), 
                    ), 
            ), 
            SizedBox(height: 20), 
            ElevatedButton( 
  onPressed: isSubmitting 
      ? null 
      : () async { 
          setState(() { 
            isSubmitting = true; 
          }); 
          await submitRankings(); // Ensure rankings are submitted 
          setState(() { 
            isSubmitting = false; 
          }); 
          // Show the message after submitting 
          showDialog( 
            context: context, 
            builder: (context) { 
              return AlertDialog( 
                title: Text("Ranking Submitted"), 
                content: Text("You have passed!"), // Change this text as needed 
                actions: [ 
                  TextButton( 
                    onPressed: () => Navigator.pop(context), 
                    child: Text("OK"), 
                  ), 
                ], 
              ); 
            }, 
          ); 
        }, 
  child: isSubmitting 
      ? CircularProgressIndicator(color: Colors.white) 
      : Text("Submit Ranking"), 
  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), 
), 
          ], 
        ), 
      ), 
    ); 
  } 
} 
class ResultPage extends StatelessWidget { 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar(title: Text("Result"), backgroundColor: Colors.blueAccent), 
      body: Center( 
        child: Column( 
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [ 
            Text("Your Result:", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), 
            SizedBox(height: 20), 
            Text("✅ Passed!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)), 
          ], 
        ), 
      ), 
    ); 
  } 
} 
void main() { 
  runApp(MaterialApp( 
    debugShowCheckedModeBanner: false, 
    theme: ThemeData(primarySwatch: Colors.blue), 
    home: StudentDashboard(), 
  )); 
} 
Future<void> processAndStoreResults(int assignmentId, int taskNumber) async { 
  final String rankApiUrl = "$apiBaseUrl/api/rank"; 
  final String resultApiUrl = "$apiBaseUrl/api/student_results"; 
  try { 
    // Fetch all rankings for the given assignment and task 
    final response = await http.get(Uri.parse(rankApiUrl));
    if (response.statusCode != 200) { 
      print("Failed to fetch rankings."); 
      return; 
    } 
    List<dynamic> rankingData = json.decode(response.body); 
    // Filter rankings based on assignment ID and task number 
    List<dynamic> taskRankings = rankingData.where((entry) =>  
      entry['assignment_id'] == assignmentId && entry['task_number'] == taskNumber 
    ).toList(); 
    if (taskRankings.isEmpty) { 
      print("No rankings found for Assignment $assignmentId, Task $taskNumber"); 
      return; 
    } 
    // Map to store total points per student 
    Map<String, int> studentPoints = {}; 
    // Calculate points based on ranks given 
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
          studentPoints[rankedStudents[i]] = (studentPoints[rankedStudents[i]] ?? 0) + points[i]; 
        } 
      } 
    } 
    // Calculate average points 
    double averagePoints = studentPoints.values.reduce((a, b) => a + b) / studentPoints.length; 
    // Submit results for each student 
    for (var entry in studentPoints.entries) { 
      String studentName = entry.key; 
      int totalPoints = entry.value; 
      String resultStatus = totalPoints >= (0.5 * averagePoints) ? "Pass" : "Fail"; 
      final resultResponse = await http.post(
        Uri.parse(resultApiUrl), 
        headers: {"Content-Type": "application/json"}, 
        body: json.encode({ 
          "faculty_id": 17046,  // Change to dynamic if needed 
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
 