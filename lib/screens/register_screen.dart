import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../provider/task_provider.dart';
import 'home_screen.dart';
import '../widgets/app_popup.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;

  final Color duoGreen = const Color(0xFF58CC02);
  final Color duoGreenDark = const Color(0xFF46A302);
  final Color duoBlue = const Color(0xFF1CB0F6);
  final Color duoGray = const Color(0xFFE5E5E5);
  final Color duoText = const Color(0xFF1F1F1F);
  final Color duoSecondaryText = const Color(0xFF4B4B4B);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      AppPopup.error(context, "Email không hợp lệ, không được sử dụng!");
      return;
    }

    setState(() => isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Đăng ký tài khoản
      String? error = await _auth.register(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        fullName: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );

      if (!mounted) return;

      if (error == null) {
        await AppPopup.success(
          context,
          "Chào mừng! Tài khoản của bạn đã sẵn sàng.",
        );
        // Tải lại dữ liệu cho tài khoản mới
        if (mounted) {
          context.read<TaskProvider>().loadTasks();
        }
        // Chuyển thẳng về trang chủ (hoặc màn hình chính)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        AppPopup.error(context, error);
      }
    } catch (e) {
      if (mounted) {
        AppPopup.error(context, "Lỗi hệ thống: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : duoText;
    final labelColor =
        isDark ? Colors.white.withOpacity(0.7) : duoSecondaryText;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: labelColor, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      "TẠO HỒ SƠ",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tham gia cùng chúng tôi để quản lý công việc tốt hơn!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildDuoTextField(
                      controller: nameController,
                      hint: "TÊN ĐĂNG NHẬP",
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      validator: (v) => (v == null || v.isEmpty)
                          ? "Vui lòng nhập họ tên"
                          : null,
                    ),
                    const SizedBox(height: 15),
                    _buildDuoTextField(
                      controller: emailController,
                      hint: "EMAIL",
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Vui lòng nhập email";
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return "Email không hợp lệ, không được sử dụng!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildDuoTextField(
                      controller: phoneController,
                      hint: "SỐ ĐIỆN THOẠI",
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Vui lòng nhập số điện thoại";
                        }
                        final cleanPhone = v.replaceAll(RegExp(r'\s+'), '');
                        final phoneRegex = RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$');
                        if (!phoneRegex.hasMatch(cleanPhone)) {
                          return "Số điện thoại không hợp lệ (ví dụ: 0912345678)";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildDuoTextField(
                      controller: passwordController,
                      hint: "MẬT KHẨU",
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      isPassword: true,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return "Vui lòng nhập mật khẩu";
                        if (v.length < 8)
                          return "Mật khẩu phải có ít nhất 8 ký tự";
                        if (!RegExp(r'^(?=.*[A-Z])(?=.*[0-9])').hasMatch(v)) {
                          return "Cần ít nhất 1 chữ hoa và 1 chữ số";
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 5),
                      child: Text(
                        "* Ít nhất 8 ký tự, gồm chữ hoa và số",
                        style: TextStyle(
                          color: labelColor.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildDuoTextField(
                      controller: confirmController,
                      hint: "XÁC NHẬN MẬT KHẨU",
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      isPassword: true,
                      validator: (v) => v != passwordController.text
                          ? "Mật khẩu không khớp"
                          : null,
                    ),
                    const SizedBox(height: 40),
                    isLoading
                        ? Column(
                            children: [
                              CircularProgressIndicator(
                                color: duoGreen,
                                strokeWidth: 5,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Đang tạo hồ sơ cho bạn...",
                                style: TextStyle(
                                  color: labelColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : _build3DButton(
                            text: "TẠO TÀI KHOẢN",
                            color: duoGreen,
                            shadowColor: duoGreenDark,
                            onPressed: register,
                          ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDuoTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Color textColor,
    required Color labelColor,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontWeight: FontWeight.w900, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: labelColor.withOpacity(0.4),
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF37464F) : duoGray,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: duoBlue, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
        ),
      ),
    );
  }

  Widget _build3DButton({
    required String text,
    required Color color,
    required Color shadowColor,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: shadowColor, offset: const Offset(0, 5)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
