import 'package:flutter/material.dart';

class TaskDetailScreen extends StatefulWidget {
  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tên công việc")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("00:00:00", style: TextStyle(fontSize: 30, color: Colors.orange)),

            Slider(
              value: progress,
              onChanged: (value) {
                setState(() {
                  progress = value;
                });
              },
            ),

            Text("${(progress * 100).toInt()}%"),
          ],
        ),
      ),
    );
  }
}