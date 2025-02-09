import 'package:flutter/material.dart';
import 'package:my_project/students/Result.dart';
import 'package:my_project/Admin/CreateAssignment.dart';
import 'package:my_project/Admin/DetailPage.dart';
import 'package:my_project/Admin/adminDashboard.dart';
import 'package:my_project/LoginScreen.dart';
import 'package:my_project/Loginstudent.dart';
import 'package:my_project/students/Questions.dart';
import 'package:my_project/students/RankAssignmentScreen.dart'; // Add this line
// import 'package:my_project/students/AttendanceScreen.dart'; // Add this line

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      initialRoute: '/studentLogin', // Set initial route here
      routes: {
        '/admin': (context) => AdminScreen(),
        '/login': (context) => LoginScreen(),
        '/studentDashboard': (context) => StudentDashboard(),
        '/studentLogin': (context) => LoginScreenStudents(),
        '/createAssignment': (context) => CreateAssignment(),
        '/detailPage': (context) => DetailPage(assignment: {}),
        '/questions': (context) =>
            QuestionsScreen(navigateToDataEntryScreen: (data) {
              // Add your navigation logic here
            }),
        '/resultScreen': (context) => ResultScreen(score: 0, isEligible: false),
        '/ranking': (context) => RankAssignmentScreen(),
        // '/attendance': (context) => AttendanceScreen(),
      },
    );
  }
}
