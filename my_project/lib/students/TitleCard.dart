import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TitleCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final bool button;
  final String buttonText;

  TitleCard({
    required this.title,
    required this.date,
    required this.time,
    this.button = false,
    this.buttonText = 'Start Questions',
  });

  void handleButtonPress(BuildContext context) {
    if (buttonText != 'Failed' && buttonText != 'Passed') {
      Navigator.pushNamed(context, '/question');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = buttonText == 'Failed' || buttonText == 'Passed';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItem('Title:', title),
            _buildItem('Date:', date),
            _buildItem('Time:', time),
            if (button)
              GestureDetector(
                onTap: isCompleted ? null : () => handleButtonPress(context),
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 30),
                  decoration: BoxDecoration(
                    color: _getButtonColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7F8FA6),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF353B48),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor() {
    if (buttonText == 'Passed') {
      return Colors.green; // Green color for passed
    } else if (buttonText == 'Failed') {
      return Colors.red; // Red color for failed
    } else {
      return Color(0xFF007BFF); // Default blue color
    }
  }
}
