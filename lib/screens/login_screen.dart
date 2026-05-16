import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../provider/task_provider.dart';
import '../widgets/app_popup.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  final Color duoGreen = const Color(0xFF58CC02);
  final Color duoGreenDark = const Color(0xFF46A302);
  final Color duoBlue = const Color(0xFF1CB0F6);
  final Color duoBlueDark = const Color(0xFF1899D6);
  final Color duoGray = const Color(0xFFE5E5E5);
  final Color duoText = const Color(0xFF1F1F1F);
  final Color duoSecondaryText = const Color(0xFF4B4B4B);

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    String? error = await _auth.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) context.read<TaskProvider>().loadTasks();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showSnackBar(error, Colors.redAccent);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    HapticFeedback.lightImpact();

    String? error = await _auth.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (error == null) {
      if (mounted) context.read<TaskProvider>().loadTasks();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showSnackBar(error, Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    AppPopup.show(
      context,
      title: color == Colors.redAccent ? 'Có lỗi xảy ra' : 'Thông báo',
      message: message,
      color: color,
      icon:
          color == Colors.redAccent ? Icons.error_outline : Icons.info_outline,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Owl Mascot with Animation
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(seconds: 1),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: const Text("🦉", style: TextStyle(fontSize: 100)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "ĐĂNG NHẬP",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Quản lý nhiệm vụ theo cách của bạn!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    _buildDuoTextField(
                      controller: emailController,
                      hint: "EMAIL HOẶC TÊN ĐĂNG NHẬP",
                      icon: Icons.email_rounded,
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      validator: (v) => (v == null || v.isEmpty)
                          ? "Nhập email của bạn"
                          : null,
                    ),
                    const SizedBox(height: 15),

                    // Password Field
                    _buildDuoTextField(
                      controller: passwordController,
                      hint: "MẬT KHẨU",
                      icon: Icons.lock_rounded,
                      isDark: isDark,
                      textColor: textColor,
                      labelColor: labelColor,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Nhập mật khẩu" : null,
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: Text(
                          "Quên mật khẩu?",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: duoBlue,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Login Button
                    _isLoading
                        ? CircularProgressIndicator(color: duoGreen)
                        : _Duo3DButton(
                            text: "ĐĂNG NHẬP",
                            color: duoGreen,
                            shadowColor: duoGreenDark,
                            onPressed: _handleLogin,
                          ),

                    const SizedBox(height: 25),
                    const Row(
                      children: [
                        Expanded(child: Divider(thickness: 2)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            "HOẶC",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(thickness: 2)),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Google Sign In
                    // Google Sign In
                    _isGoogleLoading
                        ? CircularProgressIndicator(color: duoBlue)
                        : InkWell(
                            onTap: _handleGoogleSignIn,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 60,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF30363D)
                                      : const Color(0xFFD0D7DE),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Image.network(
                                      'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                                      height: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.account_circle,
                                        color: textColor.withOpacity(0.5),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Flexible(
                                    child: Text(
                                      "TIẾP TỤC VỚI GOOGLE",
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "CHƯA CÓ TÀI KHOẢN?",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: labelColor,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: Text(
                            "ĐĂNG KÝ",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: duoBlue,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
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
  final Color textColor;
  final VoidCallback onPressed;
  final Widget? icon;

  const _Duo3DButton({
    required this.text,
    required this.color,
    required this.shadowColor,
    required this.onPressed,
    this.textColor = Colors.white,
    this.icon,
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
            border: widget.color == Colors.white
                ? Border.all(color: const Color(0xFFE5E5E5), width: 2)
                : null,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 12),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
