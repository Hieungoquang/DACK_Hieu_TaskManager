import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:task_manager/screens/home_screen.dart';
import 'package:task_manager/screens/login_screen.dart';

import 'models/task_model.dart';
import 'models/user_model.dart';
import 'models/subtask_model.dart';
import 'models/time_logs_model.dart';
import 'models/task_schedule_model.dart';
import 'models/notification_model.dart';
import 'models/user_availability_model.dart';

import 'provider/task_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();

  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(SubtaskAdapter());
  Hive.registerAdapter(TimelogsAdapter());
  Hive.registerAdapter(TaskScheduleAdapter());
  Hive.registerAdapter(NotificationAdapter());
  Hive.registerAdapter(UserAvailabilityAdapter());

  await Hive.openBox<Task>('tasksBox');
  await Hive.openBox<Time_logs>('timeLogsBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskProvider()..loadTasks(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Task Manager',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),

        home: LoginScreen(),
      ),
    );
  }
}