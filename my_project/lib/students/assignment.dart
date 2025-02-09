class Assignment {
  final int id;
  final String title;
  final String date;
  final String startTime;
  final String stopTime;
  final String explanation;
  final int numberOfTasks;
  final int numberOfStudents;
  final String taskDetails;
  final String totalTime;
  final int numberOfRanks;

  Assignment({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.stopTime,
    required this.explanation,
    required this.numberOfTasks,
    required this.numberOfStudents,
    required this.taskDetails,
    required this.totalTime,
    required this.numberOfRanks,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      title: json['title'],
      date: json['date'],
      startTime: json['start_time'],
      stopTime: json['stop_time'],
      explanation: json['explanation'],
      numberOfTasks: json['numberoftasks'],
      numberOfStudents: json['number_of_students'],
      taskDetails: json['task_details'],
      totalTime: json['total_time'],
      numberOfRanks: json['numberofranks'],
    );
  }
}
