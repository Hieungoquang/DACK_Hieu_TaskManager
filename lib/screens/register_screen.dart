import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  final emailController = TextEditingController();
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

    setState(() => isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng ký thành công")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đăng ký")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Nhập email";
                  return null;
                },
              ),

              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Mật khẩu"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Nhập mật khẩu";
                  if (value.length < 6) return ">= 6 ký tự";
                  return null;
                },
              ),

              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Nhập lại mật khẩu"),
                validator: (value) {
                  if (value != passwordController.text) {
                    return "Không khớp";
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: register,
                      child: Text("Đăng ký"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}