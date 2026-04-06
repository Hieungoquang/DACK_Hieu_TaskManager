import 'package:flutter/material.dart';

class TaskListScreen extends StatelessWidget {
  final List<String> tasks = List.generate(10, (i) => "Item ${i + 1}");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Danh sách công việc")),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(tasks[index]),
            subtitle: Text("Sub Item ${index + 1}"),
          );
        },
      ),
    );
  }
}