import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String? error = await _auth.register(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Image.network(
                  'https://cdn-icons-png.flaticon.com/512/906/906334.png',
                  height: 80,
                  width: 80,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Tạo tài khoản",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                
                TextFormField(
                  controller: nameController,
                  decoration: _inputStyle("Họ và tên"),
                  validator: (value) => (value == null || value.isEmpty) ? "Vui lòng nhập họ tên" : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: emailController,
                  decoration: _inputStyle("Email"),
                  validator: (value) => (value == null || !value.contains("@")) ? "Email không hợp lệ" : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: phoneController,
                  decoration: _inputStyle("Số điện thoại"),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: _inputStyle("Mật khẩu"),
                  validator: (value) => (value == null || value.length < 6) ? "Mật khẩu ít nhất 6 ký tự" : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: _inputStyle("Nhập lại mật khẩu"),
                  validator: (value) {
                    if (value != passwordController.text) return "Mật khẩu không khớp";
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),
                
                isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF62D000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Đăng ký",
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                
                const SizedBox(height: 25),
                
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Đã có tài khoản? Đăng nhập",
                    style: TextStyle(
                      color: Color(0xFF62D000),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}