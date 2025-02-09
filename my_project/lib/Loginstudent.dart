import 'package:flutter/material.dart';

class LoginScreenStudents extends StatefulWidget {
  @override
  _LoginScreenStudentsState createState() => _LoginScreenStudentsState();
}

class _LoginScreenStudentsState extends State<LoginScreenStudents> {
  String username = '';
  String password = '';

  void handleLogin() {
    if (username == 'bitsathy' && password == '12345') {
      // Navigate to Student Dashboard if credentials are correct
      Navigator.pushReplacementNamed(context, '/studentDashboard');
    } else {
      // Show an error alert if the credentials are incorrect
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Failed'),
          content: Text('Invalid username or password'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Student Login',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B4F87),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      username = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      password = value;
                    });
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2B4F87),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: LoginScreenStudents(),
    routes: {
      '/studentDashboard': (context) => StudentDashboard(), // Define Student Dashboard screen
    },
  ));
}

// Placeholder for Student Dashboard screen
class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Dashboard')),
      body: Center(child: Text('Welcome to the Student Dashboard!')),
    );
  }
}
