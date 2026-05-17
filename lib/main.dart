import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:task_manager/screens/home_screen.dart';
import 'package:task_manager/screens/login_screen.dart';
import 'package:task_manager/services/notification_service.dart';
import 'firebase_options.dart';

import 'models/task_model.dart';
import 'models/user_model.dart';
import 'models/subtask_model.dart';
import 'models/time_logs_model.dart';
import 'models/task_schedule_model.dart';
import 'models/notification_model.dart' as model;
import 'models/user_availability_model.dart';
import 'models/project_model.dart';
import 'models/task_category_model.dart';

import 'provider/task_provider.dart';
import 'provider/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // Khởi tạo Thông báo (Chỉ chạy trên Mobile)
  if (!kIsWeb) {
    await NotificationService.init();
  }

  // Khởi tạo Hive
  await Hive.initFlutter();

  // Đăng ký adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UserAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SubtaskAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ProjectAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(TimelogsAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(TaskScheduleAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(model.NotificationAdapter());
  if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(UserAvailabilityAdapter());
  if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(TaskCategoryAdapter());

  await Hive.openBox<Task>('tasksBox');
  await Hive.openBox<Time_logs>('timeLogsBox');
  await Hive.openBox<Subtask>('subtasksBox');
  await Hive.openBox<model.Notification>('notificationsBox');
  await Hive.openBox<Project>('projectsBox');
  await Hive.openBox<TaskCategory>('categoriesBox');
  await Hive.openBox<TaskSchedule>('taskSchedulesBox');
  await Hive.openBox<UserAvailability>('availabilityBox');
  await Hive.openBox('settingsBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()..loadTasks()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TaskFlow',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF6F8FA),
              fontFamily: GoogleFonts.nunito().fontFamily,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFF6F8FA),
                surfaceTintColor: Color(0xFFF6F8FA),
                elevation: 0,
                iconTheme: IconThemeData(color: Color(0xFF24292F)),
                titleTextStyle: TextStyle(
                    color: Color(0xFF24292F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              textTheme: const TextTheme(
                displayLarge: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF24292F)),
                displayMedium: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF24292F)),
                displaySmall: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF24292F)),
                headlineMedium: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF24292F)),
                titleLarge: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF24292F)),
                bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF24292F)),
                bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF24292F)),
                labelLarge: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF24292F)),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF0D1117),
              fontFamily: GoogleFonts.nunito().fontFamily,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF0D1117),
                surfaceTintColor: Color(0xFF0D1117),
                elevation: 0,
                iconTheme: IconThemeData(color: Color(0xFFC9D1D9)),
                titleTextStyle: TextStyle(
                    color: Color(0xFFC9D1D9),
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              textTheme: const TextTheme(
                displayLarge: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC9D1D9)),
                displayMedium: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC9D1D9)),
                displaySmall: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC9D1D9)),
                headlineMedium: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC9D1D9)),
                titleLarge: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC9D1D9)),
                bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFC9D1D9)),
                bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFC9D1D9)),
                labelLarge: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC9D1D9)),
              ),
            ),
            themeMode: appProvider.themeMode,
            locale: appProvider.locale,
            home: StreamBuilder<firebase_auth.User?>(
              stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }
                return snapshot.hasData
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
