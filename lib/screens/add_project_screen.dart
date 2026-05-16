import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/project_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import 'project_board_screen.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // GitHub Style Colors
  static const Color ghBlue = Color(0xFF58A6FF);
  static const Color ghGreen = Color(0xFF3FB950);
  static const Color ghOrange = Color(0xFFD29922);

  void _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    final user = auth.FirebaseAuth.instance.currentUser;
    final newProject = Project(
      project_id: const Uuid().v4(),
      user_id: user?.uid ?? "guest",
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      memberIds: [],
      memberStatuses: {},
    );

    final taskProvider = context.read<TaskProvider>();
    await taskProvider.addProject(newProject);

    if (!mounted) return;

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectBoardScreen(project: newProject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;

    final bgColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
    final borderColor =
        isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWeb ? size.width * 0.25 : 20,
        vertical: isWeb ? 100 : 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _topBar(isDark, textColor, borderColor),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(isDark, 'THÔNG TIN CƠ BẢN'),
                    const SizedBox(height: 20),
                    _buildInput(
                      isDark,
                      'Tên dự án',
                      _nameController,
                      'Ví dụ: Dự án Website Alpha',
                      Icons.folder_outlined,
                      borderColor,
                      textColor,
                      required: true,
                    ),
                    const SizedBox(height: 24),
                    _buildInput(
                      isDark,
                      'Mô tả',
                      _descController,
                      'Mục tiêu của dự án này là...',
                      Icons.description_outlined,
                      borderColor,
                      textColor,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),
                    _buildCreateButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(bool isDark, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.create_new_folder_outlined, color: ghGreen, size: 30),
          const SizedBox(width: 15),
          Text(
            'DỰ ÁN MỚI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: textColor, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(bool isDark, String title) {
    final subColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: subColor,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInput(
    bool isDark,
    String label,
    TextEditingController ctrl,
    String hint,
    IconData icon,
    Color borderColor,
    Color textColor, {
    int maxLines = 1,
    bool required = false,
  }) {
    final subColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              icon: Icon(icon, color: ghBlue, size: 22),
              hintText: hint,
              hintStyle: TextStyle(
                color: subColor.withOpacity(0.5),
                fontSize: 16,
              ),
              border: InputBorder.none,
            ),
            validator: (v) => (required && (v == null || v.isEmpty))
                ? "Vui lòng nhập $label"
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _createProject,
      style: ElevatedButton.styleFrom(
        backgroundColor: ghGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: const Text(
        "TẠO DỰ ÁN",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
