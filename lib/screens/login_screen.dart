import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  void login() async {
    print("🔥 CLICK LOGIN");

    if (!_formKey.currentState!.validate()) {
      print("❌ FORM INVALID");
      return;
    }

    setState(() => isLoading = true);

    String? error = await _auth.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (error == null) {
      print("✅ LOGIN SUCCESS");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      print("❌ ERROR: $error");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 👈 fix bàn phím che UI

      body: SafeArea(
        child: SingleChildScrollView(
          // 👈 FIX KHÔNG CLICK
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 80),

                  Text(
                    "Đăng nhập",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 30),

                  // EMAIL
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Không được để trống email";
                      }
                      if (!value.contains("@")) {
                        return "Email không hợp lệ";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 15),

                  // PASSWORD
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Không được để trống mật khẩu";
                      }
                      if (value.length < 6) {
                        return "Mật khẩu phải >= 6 ký tự";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 25),

                  // BUTTON LOGIN
                  isLoading
                      ? CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: login,
                            child: Text("Đăng nhập"),
                          ),
                        ),

                  SizedBox(height: 10),

                  // REGISTER
                  TextButton(
                    onPressed: () {
                      print("👉 CLICK REGISTER");

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegisterScreen()),
                      );
                    },
                    child: Text("Chưa có tài khoản? Đăng ký"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
