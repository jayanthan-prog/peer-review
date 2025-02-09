import 'package:flutter/material.dart';

// Define a type for the attendance data
class AttendanceData {
  final int id;
  final String name;
  final String rollNo;
  bool selected;

  AttendanceData({
    required this.id,
    required this.name,
    required this.rollNo,
    this.selected = false,
  });
}

class AttendanceScreen extends StatefulWidget {
  final List<AttendanceData>? initialData;

  AttendanceScreen({Key? key, this.initialData}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late List<AttendanceData> attendanceData;

  @override
  void initState() {
    super.initState();
    attendanceData = widget.initialData ??
        [
          AttendanceData(id: 1, name: 'Jane Smith', rollNo: '67890'),
          AttendanceData(id: 2, name: 'John Doe', rollNo: '12345'),
          AttendanceData(id: 3, name: 'Emily Davis', rollNo: '45678', selected: true),
          AttendanceData(id: 4, name: 'Michael Brown', rollNo: '98765'),
        ];
  }

  void handleCheckboxPress(int id, bool newState) {
    setState(() {
      attendanceData = attendanceData.map((item) {
        if (item.id == id) {
          item.selected = newState;
        }
        return item;
      }).toList();
    });
  }

  void handleStartPress() {
    // Handle the Start button press action
    print('Attendance started with selected students: ${attendanceData.where((item) => item.selected)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Screen'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2B4F87)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: attendanceData.length,
                itemBuilder: (context, index) {
                  final item = attendanceData[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.selected,
                            onChanged: (newState) {
                              if (newState != null) {
                                handleCheckboxPress(item.id, newState);
                              }
                            },
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF353B48)),
                              ),
                              Text(
                                'Roll No: ${item.rollNo}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF7F8FA6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: handleStartPress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2B4F87),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                'Start',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
