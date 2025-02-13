import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_project/Admin/adminDashboard.dart';
import 'package:my_project/students/studentDashboard.dart';
import 'package:my_project/config.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController facultyIdController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  
  // Temporary storage for login ID
  String? loggedInUserId;
  
  @override
  void initState() {
    super.initState();
    // Pre-fill for testing purposes
     
  }
  
  // Handle login process

  Future<void> handleLogin() async {
    String email = emailController.text.trim();
    String facultyId = facultyIdController.text.trim();
    if (email.isEmpty || facultyId.isEmpty) {
      showErrorDialog('Please enter both Email and Faculty ID');
      return;
    }
    int? facultyIdInt = int.tryParse(facultyId);
    if (facultyIdInt == null) {
      showErrorDialog('Faculty ID must be a valid number');
      return;
    }
    setState(() => loading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/api/faculty')),
        http.get(Uri.parse('$apiBaseUrl/api/student')),
      ]);
      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final List facultyData = json.decode(responses[0].body);
        final List studentData = json.decode(responses[1].body);
        bool isFaculty = facultyData.any((faculty) =>
            faculty['emailId'] == email &&
            faculty['facultyId'].toString() == facultyId);
        bool isStudent = studentData.any((student) =>
            student['emailId'] == email &&
            student['facultyId'].toString() == facultyId);
        setState(() => loading = false);
        if (isFaculty || isStudent) {
          // Store the logged-in user ID temporarily
          loggedInUserId = facultyId;
          print('Logged in user id: $loggedInUserId');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => isFaculty
                  ? AdminScreen()
                  : StudentDashboard(loggedInUserId: loggedInUserId),
            ),
          );
        } else {
          showErrorDialog('Invalid credentials');
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      setState(() => loading = true);
      showErrorDialog(
          'Network error. Please check your connection. ${e.toString()}');
    }
  }
  
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Failed', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.blue[700])),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_rounded, size: 100, color: Colors.blue[700]),
              SizedBox(height: 20),
              // "Welcome Back!" text for a friendly greeting
              Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: emailController,
                      icon: Icons.email,
                      hint: "Email",
                    ),
                    SizedBox(height: 15),
                    _buildTextField(
                      controller: facultyIdController,
                      icon: Icons.lock,
                      hint: " ID",
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: EdgeInsets.symmetric(vertical: 15),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 10,
                      ),
                      child: Text(
                        "SIGN IN",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (loading) ...[
                      SizedBox(height: 20),
                      CircularProgressIndicator(),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: _inputBoxDecoration(),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: (hint == "Faculty ID") ? TextInputType.number : TextInputType.emailAddress,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue[700]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }
  
  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
      ],
    );
  }
}