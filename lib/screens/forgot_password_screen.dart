import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/app_popup.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  final emailController = TextEditingController();
  bool _isLoading = false;

  final Color duoGreen = const Color(0xFF58CC02);
  final Color duoGreenDark = const Color(0xFF46A302);
  final Color duoBlue = const Color(0xFF1CB0F6);
  final Color duoGray = const Color(0xFFE5E5E5);
  final Color duoText = const Color(0xFF1F1F1F);
  final Color duoSecondaryText = const Color(0xFF4B4B4B);

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    String? error = await _auth.forgotPassword(emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      _showSnackBar("Email khôi phục mật khẩu đã được gửi!", duoGreen);
      Navigator.pop(context);
    } else {
      _showSnackBar(error, Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    AppPopup.show(
      context,
      title: color == Colors.redAccent ? 'Có lỗi xảy ra' : 'Thành công',
      message: message,
      color: color,
      icon: color == Colors.redAccent
          ? Icons.error_outline
          : Icons.check_circle_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : duoText;
    final labelColor =
        isDark ? Colors.white.withValues(alpha: 0.7) : duoSecondaryText;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: duoBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text("🔑", style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 20),
                    Text(
                      "QUÊN MẬT KHẨU",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Nhập email của bạn để nhận liên kết khôi phục mật khẩu.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildDuoTextField(
                      controller: emailController,
                      hint: "EMAIL CỦA BẠN",
                      icon: Icons.email_rounded,
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Vui lòng nhập email";
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return "Email không hợp lệ (ví dụ: name@example.com)";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? CircularProgressIndicator(color: duoBlue)
                        : _Duo3DButton(
                            text: "GỬI YÊU CẦU",
                            color: duoBlue,
                            shadowColor: const Color(0xFF1899D6),
                            onPressed: _handleResetPassword,
                          ),
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
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required Color labelColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        color: textColor,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: labelColor.withValues(alpha: 0.4),
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: duoBlue, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF37464F) : duoGray,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: duoBlue, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
        ),
      ),
    );
  }
}

class _Duo3DButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color shadowColor;
  final VoidCallback onPressed;

  const _Duo3DButton({
    required this.text,
    required this.color,
    required this.shadowColor,
    required this.onPressed,
  });

  @override
  State<_Duo3DButton> createState() => _Duo3DButtonState();
}

class _Duo3DButtonState extends State<_Duo3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: EdgeInsets.only(top: _isPressed ? 5 : 0),
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: widget.shadowColor,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
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
