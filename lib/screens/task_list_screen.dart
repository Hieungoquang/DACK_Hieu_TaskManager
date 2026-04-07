import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/task_provider.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách công việc"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Thêm logic tạo task mẫu để test
              context.read<TaskProvider>().addLog("test_task_id");
            },
          )
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.tasks.isEmpty) {
            return const Center(child: Text("Chưa có công việc nào"));
          }
          return ListView.builder(
            itemCount: taskProvider.tasks.length,
            itemBuilder: (context, index) {
              final task = taskProvider.tasks[index];
              return ListTile(
                title: Text(task.title),
                subtitle: Text(task.description),
                trailing: Checkbox(
                  value: task.progress == 100,
                  onChanged: (val) {
                    taskProvider.updateProgress(task, val == true ? 100 : 0);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}