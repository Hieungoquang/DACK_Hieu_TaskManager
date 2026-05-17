import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../provider/app_provider.dart';
import '../models/user_model.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/app_popup.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  User? _currentUser;
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  static const Color ghBlue = Color(0xFF0969DA);
  static const Color ghGreen = Color(0xFF238636);
  static const Color ghRed = Color(0xFFCF222E);

  Color _bg(bool d) => d ? const Color(0xFF0D1117) : Colors.white;
  Color _headerBg(bool d) =>
      d ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);
  Color _border(bool d) =>
      d ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
  Color _input(bool d) => d ? const Color(0xFF010409) : Colors.white;
  Color _txt(bool d) => d ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
  Color _sub(bool d) => d ? const Color(0xFF8B949E) : const Color(0xFF57606A);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      // 1. Try Hive first
      final userBox = await Hive.openBox<User>('userBox');
      _currentUser = userBox.get(firebaseUser.uid);

      // 2. Always fetch latest from Firestore to be sure
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          final updatedUser = User(
            user_id: firebaseUser.uid,
            username: data['username'] ?? "",
            email: data['email'] ?? "",
            phone_number: data['phone_number'] ?? "",
            password_hash: "",
            google_id: "",
            avatar_url: data['avatar_url'] ?? "",
            full_name: data['full_name'] ?? "",
            last_sync_at: DateTime.now(),
            created_at:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updated_at:
                (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
          await userBox.put(firebaseUser.uid, updatedUser);
          setState(() {
            _currentUser = updatedUser;
            _nameController.text = updatedUser.full_name;
            _usernameController.text = updatedUser.username;
            _phoneController.text = updatedUser.phone_number;
            _emailController.text = updatedUser.email;
          });
        }
      } catch (e) {
        debugPrint("Lỗi fetch user: $e");
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      final result = await _auth.uploadAvatar(File(pickedFile.path));
      if (result == null) {
        _loadUserInfo();
        if (mounted)
          AppPopup.success(context, "Cập nhật ảnh đại diện thành công!");
      } else {
        if (mounted) AppPopup.error(context, "Lỗi: $result");
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
      final phoneRegex = RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$');
      if (!phoneRegex.hasMatch(cleanPhone)) {
        AppPopup.error(context, "Số điện thoại không hợp lệ (ví dụ: 0912345678)");
        return;
      }
    }

    setState(() => _isLoading = true);
    final result = await _auth.updateProfile(
      fullName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      phoneNumber: phone,
      email: _emailController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (result == null) {
      setState(() => _isEditing = false);
      await _loadUserInfo();
      if (mounted) AppPopup.success(context, "Cập nhật thông tin thành công!");
    } else {
      if (mounted) AppPopup.error(context, "Lỗi: $result");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<AppProvider>(context).themeMode == ThemeMode.dark;
    bool isWeb = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _bg(isDark),
      appBar: isWeb ? null : _buildMobileAppBar(isDark),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'profile'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 60 : 20,
                vertical: 30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWeb) _buildWebHeader(isDark),
                      const SizedBox(height: 30),
                      _buildAvatarCard(isDark),
                      const SizedBox(height: 30),
                      _buildInfoSection(isDark),
                      const SizedBox(height: 30),
                      _buildAccountSettings(isDark),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildMobileAppBar(bool isDark) {
    return AppBar(
      backgroundColor: _headerBg(isDark),
      elevation: 0,
      centerTitle: true,
      title: Text(
        "Hồ sơ",
        style: TextStyle(
          color: _txt(isDark),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: ghBlue),
            onPressed: () => setState(() => _isEditing = true),
          ),
      ],
    );
  }

  Widget _buildWebHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Cài đặt hồ sơ",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _txt(isDark),
          ),
        ),
        if (!_isEditing)
          _ghButton(
            "Chỉnh sửa",
            ghBlue,
            () => setState(() => _isEditing = true),
            isDark,
          ),
      ],
    );
  }

  Widget _buildAvatarCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bg(isDark),
        border: Border.all(color: _border(isDark)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _sub(isDark).withOpacity(0.1),
                backgroundImage: (_currentUser?.avatar_url != null &&
                        _currentUser!.avatar_url.isNotEmpty)
                    ? NetworkImage(_currentUser!.avatar_url)
                    : null,
                child: (_currentUser?.avatar_url == null ||
                        _currentUser!.avatar_url.isEmpty)
                    ? Icon(Icons.person, size: 40, color: _sub(isDark))
                    : null,
              ),
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _headerBg(isDark),
                    shape: BoxShape.circle,
                    border: Border.all(color: _border(isDark)),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?.full_name ?? "Chưa đặt tên",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _txt(isDark),
                  ),
                ),
                Text(
                  "@${_currentUser?.username ?? "user"}",
                  style: TextStyle(color: _sub(isDark), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Hồ sơ công khai", isDark),
        const SizedBox(height: 12),
        _buildFieldCard(isDark, [
          _ghField("Họ và tên", _nameController, isDark, enabled: _isEditing),
          _ghField(
            "Tên đăng nhập",
            _usernameController,
            isDark,
            enabled: _isEditing,
          ),
        ]),
        const SizedBox(height: 24),
        _sectionTitle("Thông tin liên lạc", isDark),
        const SizedBox(height: 12),
        _buildFieldCard(isDark, [
          _ghField(
            "Email",
            _emailController,
            isDark,
            enabled: false,
          ), // KHÔNG CHO ĐỔI EMAIL
          _ghField(
            "Số điện thoại",
            _phoneController,
            isDark,
            enabled: _isEditing,
          ),
        ]),
        if (_isEditing) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              _ghButton(
                "Lưu thay đổi",
                ghGreen,
                _saveProfile,
                isDark,
                isPrimary: true,
              ),
              const SizedBox(width: 12),
              _ghButton(
                "Hủy",
                Colors.transparent,
                () => setState(() => _isEditing = false),
                isDark,
                textColor: _sub(isDark),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAccountSettings(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Tài khoản", isDark),
        const SizedBox(height: 12),
        _buildFieldCard(isDark, [
          ListTile(
            title: Text(
              "Đổi mật khẩu",
              style: TextStyle(color: _txt(isDark), fontSize: 14),
            ),
            trailing: Icon(Icons.chevron_right, color: _sub(isDark), size: 18),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
          ListTile(
            title: const Text(
              "Đăng xuất",
              style: TextStyle(
                color: ghRed,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _auth.logout().then(
                  (_) => Navigator.pushReplacementNamed(context, '/login'),
                ),
          ),
        ]),
      ],
    );
  }

  Widget _sectionTitle(String title, bool isDark) => Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _txt(isDark),
        ),
      );

  Widget _buildFieldCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _bg(isDark),
        border: Border.all(color: _border(isDark)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }

  Widget _ghField(
    String label,
    TextEditingController ctrl,
    bool isDark, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border(isDark))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _txt(isDark),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? _txt(isDark) : _sub(isDark),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? _input(isDark) : _headerBg(isDark),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: ghBlue, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _border(isDark)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ghButton(
    String text,
    Color color,
    VoidCallback onTap,
    bool isDark, {
    bool isPrimary = false,
    Color? textColor,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : _headerBg(isDark),
        foregroundColor: isPrimary ? Colors.white : (textColor ?? _txt(isDark)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side:
              isPrimary ? BorderSide.none : BorderSide(color: _border(isDark)),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
