import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLogin = true;
  bool loading = false;

  Future<void> _submit() async {
    setState(() => loading = true);

    try {
      if (isLogin) {
        await _authService.loginWithEmail(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      } else {
        await _authService.registerWithEmail(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "MeetEra",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            if (loading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _submit,
                child: Text(isLogin ? "Login" : "Register"),
              ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                setState(() => isLogin = !isLogin);
              },
              child: Text(
                isLogin ? "Create an account" : "Already have an account?",
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                await _authService.signInWithGoogle();
              },
              child: const Text("Continue with Google"),
            ),
          ],
        ),
      ),
    );
  }
}
