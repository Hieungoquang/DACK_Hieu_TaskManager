import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../widgets/app_popup.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final Color duoGreen = const Color(0xFF58CC02);
  final Color duoGreenDark = const Color(0xFF46A302);
  final Color duoBlue = const Color(0xFF1CB0F6);
  final Color duoGray = const Color(0xFFE5E5E5);
  final Color duoText = const Color(0xFF1F1F1F);
  final Color duoSecondaryText = const Color(0xFF4B4B4B);

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _showErrorSnackBar(
          "Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.",
        );
        return;
      }

      // 1. Xác thực lại với timeout
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldPasswordController.text.trim(),
      );

      await user
          .reauthenticateWithCredential(credential)
          .timeout(const Duration(seconds: 15));

      // 2. Cập nhật mật khẩu mới với timeout
      await user
          .updatePassword(_newPasswordController.text.trim())
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        await AppPopup.success(context, "Đổi mật khẩu thành công!");
        Navigator.pop(context);
      }
    } on TimeoutException {
      _showErrorSnackBar("Kết nối quá hạn. Vui lòng thử lại.");
    } on FirebaseAuthException catch (e) {
      String message = "Lỗi đổi mật khẩu";
      if (e.code == 'wrong-password') {
        message = "Mật khẩu cũ không chính xác";
      } else if (e.code == 'weak-password') {
        message = "Mật khẩu mới quá yếu";
      } else if (e.code == 'requires-recent-login') {
        message = "Vui lòng đăng nhập lại trước khi thực hiện thao tác này";
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar("Lỗi: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    AppPopup.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : duoText;
    final labelColor =
        isDark ? Colors.white.withOpacity(0.7) : duoSecondaryText;
    final borderColor = isDark ? const Color(0xFF37464F) : duoGray;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "ĐỔI MẬT KHẨU",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: labelColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("MẬT KHẨU CŨ", labelColor),
                  _buildDuoPasswordInput(
                    _oldPasswordController,
                    "Nhập mật khẩu hiện tại",
                    _obscureOld,
                    () => setState(() => _obscureOld = !_obscureOld),
                    isDark,
                    textColor,
                    labelColor,
                    cardBg,
                    borderColor,
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle("MẬT KHẨU MỚI", labelColor),
                  _buildDuoPasswordInput(
                    _newPasswordController,
                    "Nhập mật khẩu mới",
                    _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew),
                    isDark,
                    textColor,
                    labelColor,
                    cardBg,
                    borderColor,
                    validator: (v) => (v == null || v.length < 6)
                        ? "Mật khẩu ít nhất 6 ký tự"
                        : null,
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle("XÁC NHẬN MẬT KHẨU MỚI", labelColor),
                  _buildDuoPasswordInput(
                    _confirmPasswordController,
                    "Nhập lại mật khẩu mới",
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                    isDark,
                    textColor,
                    labelColor,
                    cardBg,
                    borderColor,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Vui lòng xác nhận mật khẩu";
                      if (value != _newPasswordController.text)
                        return "Mật khẩu xác nhận không khớp";
                      return null;
                    },
                  ),
                  const SizedBox(height: 45),
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: duoGreen),
                        )
                      : _buildDuoButton(
                          "CẬP NHẬT MẬT KHẨU",
                          duoGreen,
                          duoGreenDark,
                          _changePassword,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDuoPasswordInput(
    TextEditingController controller,
    String hint,
    bool obscure,
    VoidCallback onToggle,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color cardBg,
    Color borderColor, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        color: textColor,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: labelColor.withOpacity(0.4),
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: cardBg,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: labelColor,
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor, width: 2),
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
      validator: validator ??
          (value) => value == null || value.isEmpty
              ? "Trường này không được để trống"
              : null,
    );
  }

  Widget _buildDuoButton(
    String text,
    Color color,
    Color shadowColor,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 60,
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
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
