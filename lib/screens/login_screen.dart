import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';

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

  bool _validateForm() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      UiHelpers.showPremiumSnackBar(context, message: "Please enter your email address.");
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      UiHelpers.showPremiumSnackBar(context, message: "Please enter a valid email address.");
      return false;
    }

    if (password.isEmpty) {
      UiHelpers.showPremiumSnackBar(context, message: "Please enter your password.");
      return false;
    }

    if (password.length < 6) {
      UiHelpers.showPremiumSnackBar(context, message: "Your password must be at least 6 characters.");
      return false;
    }

    return true;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    setState(() => loading = true);

    try {
      if (isLogin) {
        final credential = await _authService.loginWithEmail(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        final user = credential.user;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          if (mounted) {
            UiHelpers.showPremiumSnackBar(
              context,
              message: "Your email address is not verified yet. Please check your inbox (Verification link has been resent).",
              isError: true,
            );
          }
          await _authService.signOut();
        }
      } else {
        await _authService.registerWithEmail(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.sendEmailVerification();
          if (mounted) {
            UiHelpers.showPremiumSnackBar(
              context,
              message: "Your account was created successfully! Please click the verification link sent to your email.",
              isError: false,
            );
          }
          await _authService.signOut();
          setState(() {
            isLogin = true;
          });
        }
      }
    } catch (e) {
      final appEx = ErrorMapper.fromError(e);
      if (mounted) {
        if (appEx.code == 'email-already-in-use') {
          UiHelpers.showPremiumSnackBar(
            context,
            message: "This email is already registered. Please log in instead.",
            isError: true,
            action: SnackBarAction(
              label: "Log In",
              onPressed: () {
                setState(() {
                  isLogin = true;
                });
              },
            ),
          );
        } else {
          UiHelpers.showPremiumSnackBar(context, message: appEx.message, isError: true);
        }
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submitSocial(Future<UserCredential> Function() socialMethod) async {
    setState(() => loading = true);
    try {
      await socialMethod();
    } catch (e) {
      final appEx = ErrorMapper.fromError(e);
      if (appEx.code != 'popup-closed-by-user' && appEx.code != 'cancelled') {
        if (mounted) {
          UiHelpers.showPremiumSnackBar(context, message: appEx.message, isError: true);
        }
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showForgotPasswordBottomSheet() {
    final TextEditingController resetEmailController = TextEditingController(text: emailController.text.trim());
    bool resetting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Forgot Password 🔑",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your email address to reset your password. We'll send you a reset link.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: resetEmailController,
                      decoration: InputDecoration(
                        hintText: "Email Address",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: resetting
                        ? null
                        : () async {
                            final email = resetEmailController.text.trim();
                            if (email.isEmpty) {
                              UiHelpers.showPremiumSnackBar(context, message: "Please enter your email address.");
                              return;
                            }
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(email)) {
                              UiHelpers.showPremiumSnackBar(context, message: "Please enter a valid email address.");
                              return;
                            }

                            setSheetState(() => resetting = true);

                            try {
                              await _authService.sendPasswordResetEmail(email);
                              if (context.mounted) {
                                Navigator.pop(context);
                                UiHelpers.showPremiumSnackBar(
                                  context,
                                  message: "Password reset email sent successfully! Please check your inbox.",
                                  isError: false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                final appEx = ErrorMapper.fromError(e);
                                UiHelpers.showPremiumSnackBar(context, message: appEx.message);
                              }
                            } finally {
                              setSheetState(() => resetting = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: resetting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Send Password Reset Link",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Icon(Icons.handshake_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isLogin ? "Welcome Back 👋" : "Create Account ✨",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin 
                      ? "Log in to connect with your friends" 
                      : "Join MeetEra to explore and connect",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: 40),

              // Inputs
              _buildTextField(
                controller: emailController,
                hintText: "Email Address",
                icon: Icons.email_outlined,
              ),
              
              _buildTextField(
                controller: passwordController,
                hintText: "Password",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              
              const SizedBox(height: 12),

              // Terms & Privacy
              if (!isLogin)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text.rich(
                    TextSpan(
                      text: "By signing up, you agree to our ",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      children: const [
                        TextSpan(
                          text: "Terms of Service",
                          style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: "."),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!isLogin) const SizedBox(height: 12),

              // Action Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isLogin ? "Log In" : "Sign Up",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              if (isLogin) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading ? null : _showForgotPasswordBottomSheet,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLogin ? "Don't have an account? " : "Already have an account? ",
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  GestureDetector(
                    onTap: loading ? null : () {
                      setState(() {
                        isLogin = !isLogin;
                        emailController.clear();
                        passwordController.clear();
                      });
                    },
                    child: Text(
                      isLogin ? "Sign Up" : "Log In",
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "OR",
                      style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              
              const SizedBox(height: 24),

              // Social Logins
              _buildSocialButton(
                fallbackIcon: Icons.g_mobiledata_rounded,
                label: "Continue with Google",
                onPressed: loading ? () {} : () => _submitSocial(_authService.signInWithGoogle),
                isDark: false,
              ),
              
              const SizedBox(height: 12),

              _buildSocialButton(
                fallbackIcon: Icons.apple_rounded,
                label: "Continue with Apple",
                onPressed: loading ? () {} : () => _submitSocial(_authService.signInWithApple),
                isDark: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData fallbackIcon,
    required String label,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fallbackIcon, color: isDark ? Colors.white : Colors.black87, size: isDark ? 28 : 38),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
