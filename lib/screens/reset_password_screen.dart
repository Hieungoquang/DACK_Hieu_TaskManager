import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/app_popup.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? oobCode;

  const ResetPasswordScreen({super.key, this.oobCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final Color duoGreen = const Color(0xFF58CC02);
  final Color duoGreenDark = const Color(0xFF46A302);
  final Color duoBlue = const Color(0xFF1CB0F6);
  final Color duoGray = const Color(0xFFE5E5E5);
  final Color duoText = const Color(0xFF1F1F1F);
  final Color duoSecondaryText = const Color(0xFF4B4B4B);

  @override
  void initState() {
    super.initState();
    if (widget.oobCode != null) {
      _codeController.text = widget.oobCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    String rawInput = _codeController.text.trim();
    String finalCode = rawInput;

    // Tự động phân tích và trích xuất oobCode nếu người dùng dán toàn bộ đường link khôi phục
    if (rawInput.contains('oobCode=')) {
      try {
        final uri = Uri.parse(rawInput);
        finalCode = uri.queryParameters['oobCode'] ?? rawInput;
      } catch (_) {
        // Fallback to original text if URI parsing fails
      }
    }

    if (finalCode.isEmpty) {
      AppPopup.error(context, "Mã xác thực không hợp lệ. Vui lòng kiểm tra lại email.");
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    String? error = await _auth.confirmPasswordReset(
      code: finalCode,
      newPassword: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      await AppPopup.success(
        context,
        "Mật khẩu của bạn đã được đặt lại thành công. Vui lòng đăng nhập lại!",
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } else {
      AppPopup.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : duoText;
    final labelColor =
        isDark ? Colors.white.withValues(alpha: 0.7) : duoSecondaryText;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: duoBlue),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bouncing Entrance Key Animation
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: const Text("🔑", style: TextStyle(fontSize: 80)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "MẬT KHẨU MỚI",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Thiết lập mật khẩu mới cho tài khoản của bạn.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Verification Code / Link Input Field
                    _buildDuoTextField(
                      controller: _codeController,
                      hint: "MÃ MẬT KHẨU HOẶC DÁN ĐƯỜNG LINK EMAIL",
                      icon: Icons.vpn_key_rounded,
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Vui lòng dán liên kết hoặc nhập mã từ email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Password Field
                    _buildDuoTextField(
                      controller: _passwordController,
                      hint: "MẬT KHẨU MỚI",
                      icon: Icons.lock_rounded,
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Vui lòng nhập mật khẩu mới";
                        }
                        if (v.length < 8) {
                          return "Mật khẩu phải dài tối thiểu 8 ký tự";
                        }
                        if (!RegExp(r'^(?=.*[A-Z])(?=.*[0-9])').hasMatch(v)) {
                          return "Mật khẩu cần ít nhất 1 chữ hoa và 1 chữ số";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Confirm Password Field
                    _buildDuoTextField(
                      controller: _confirmController,
                      hint: "XÁC NHẬN MẬT KHẨU MỚI",
                      icon: Icons.lock_outline_rounded,
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      isPassword: true,
                      obscureText: _obscureConfirm,
                      onTogglePassword: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Vui lòng xác nhận mật khẩu mới";
                        }
                        if (v != _passwordController.text) {
                          return "Mật khẩu xác nhận không khớp";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 35),

                    // Submit Button
                    _isLoading
                      ? CircularProgressIndicator(color: duoBlue)
                      : _Duo3DButton(
                          text: "ĐỔI MẬT KHẨU",
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
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? (obscureText ?? true) : false,
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
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText! ? Icons.visibility_off : Icons.visibility,
                  color: labelColor,
                ),
                onPressed: onTogglePassword,
              )
            : null,
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
