import 'package:flutter/material.dart';

// Define TitleCard widget
class TitleCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;

  TitleCard({required this.title, required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(date, style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 8),
            Text(time, style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  // This would be replaced with actual data or selections
  final String selectedJane = 'Jane Smith';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WELCOME RAMASAMY'),
        backgroundColor: Color(0xFF2b4f87), // Mild blue background
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to Attendance screen, passing selectedJane as an argument
                Navigator.pushNamed(
                  context,
                  '/attendance',
                  arguments: selectedJane,
                );
              },
              child: TitleCard(
                title: "Project Update Project Update",
                date: "2025-01-26",
                time: "2:00 PM",
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/attendance',
                  arguments: selectedJane,
                );
              },
              child: TitleCard(
                title: "Meeting Project Update Project",
                date: "2025-01-25",
                time: "10:00 AM",
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/attendance',
                  arguments: selectedJane,
                );
              },
              child: TitleCard(
                title: "Project Update Project Update",
                date: "2025-01-26",
                time: "2:00 PM",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
    routes: {
      '/attendance': (context) => AttendanceScreen(), // Replace with your AttendanceScreen widget
    },
  ));
}

// Dummy AttendanceScreen to complete the navigation example
class AttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectedJane = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Screen'),
      ),
      body: Center(
        child: Text('Selected: $selectedJane'),
      ),
    );
  }
}
