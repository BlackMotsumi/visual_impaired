import 'package:flutter/material.dart';
import '../../services/registration_service.dart';

class VoicePasswordScreen extends StatefulWidget {
  final String fullName;
  final String studentNumber;
  final String email;

  const VoicePasswordScreen({
    super.key,
    required this.fullName,
    required this.studentNumber,
    required this.email,
  });

  @override
  State<VoicePasswordScreen> createState() => _VoicePasswordScreenState();
}

class _VoicePasswordScreenState extends State<VoicePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final RegistrationService _registrationService = RegistrationService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _register() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Please enter your password twice.");
      return;
    }

    if (password.length < 6) {
      _showMessage("Password must contain at least 6 characters.");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("The passwords do not match.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      /*
       * Firebase Authentication requires an email address.
       *
       * Since this is voice registration, we need an email
       * associated with the account.
       *
       * For now, we will generate one from the student number.
       */

      final email = "${widget.studentNumber}@visualimpaired.local";

      await _registrationService.registerStudent(
        email: email,
        password: password,
        fullName: widget.fullName,
        studentNumber: widget.studentNumber,
        registrationMethod: "voice",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration successful!")));

      // TODO:
      // Navigate to the next screen after registration.
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registration failed: $e")));
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("Create Password")),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.lock_outline,
                size: 100,
                color: Color(0xFF0B6E4F),
              ),

              const SizedBox(height: 30),

              const Text(
                "Create Your Password",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              const Text(
                "For your security, please type your password.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 35),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,

                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Enter password",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),

                  prefixIcon: const Icon(Icons.lock),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 25),

              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                keyboardType: TextInputType.visiblePassword,

                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  hintText: "Enter password again",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password must contain at least 6 characters.",
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 65,

                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,

                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          "Create Account",
                          style: TextStyle(fontSize: 21),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
