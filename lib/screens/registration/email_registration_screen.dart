import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:visual_impaired/login/login_screen.dart';
import '../../services/registration_service.dart';

class EmailRegistrationScreen extends StatefulWidget {
  const EmailRegistrationScreen({super.key});

  @override
  State<EmailRegistrationScreen> createState() =>
      _EmailRegistrationScreenState();
}

class _EmailRegistrationScreenState
    extends State<EmailRegistrationScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _studentNumberController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FlutterTts _tts = FlutterTts();

  final RegistrationService _registrationService =
      RegistrationService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _speak();
  }

  Future<void> _speak() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);

    await _tts.speak(
      "Welcome to email registration. "
      "Please enter your full name, student number, "
      "email address and password.",
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _nameController.dispose();
    _studentNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final fullName = _nameController.text.trim();
    final studentNumber =
        _studentNumberController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword =
        _confirmPasswordController.text;

    // Full name
    if (fullName.isEmpty) {
      await _showError(
        "Please enter your full name.",
      );
      return;
    }

    // Student number
    if (studentNumber.isEmpty) {
      await _showError(
        "Please enter your student number.",
      );
      return;
    }

    // Email
    if (email.isEmpty) {
      await _showError(
        "Please enter your email address.",
      );
      return;
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email)) {
      await _showError(
        "Please enter a valid email address.",
      );
      return;
    }

    // Password
    if (password.length < 6) {
      await _showError(
        "Your password must contain at least six characters.",
      );
      return;
    }

    // Confirm password
    if (password != confirmPassword) {
      await _showError(
        "The passwords do not match.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _tts.speak(
        "Creating your account. Please wait.",
      );

      await _registrationService.registerStudent(
        email: email,
        password: password,
        fullName: fullName,
        studentNumber: studentNumber,
        registrationMethod: "email",
      );

      if (!mounted) return;

      await _tts.speak(
        "Your registration was successful. "
        "Welcome to Central University of Technology.",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Registration successful!",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );

      await Future.delayed(
  const Duration(seconds: 2),
);

if (!mounted) return;

// Sign the newly created user out.
await FirebaseAuth.instance.signOut();

if (!mounted) return;

// Go directly to Login and remove the registration screens.
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (_) => const LoginScreen(),
  ),
  (route) => false,
);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              "This email address is already registered.";
          break;

        case 'invalid-email':
          message =
              "The email address is not valid.";
          break;

        case 'weak-password':
          message =
              "The password is too weak.";
          break;

        case 'operation-not-allowed':
          message =
              "Email registration is not enabled in Firebase.";
          break;

        case 'network-request-failed':
          message =
              "Please check your internet connection.";
          break;

        default:
          message =
              e.message ??
              "Registration failed. Please try again.";
      }

      await _tts.speak(message);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      await _tts.speak(
        "Something went wrong during registration.",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Something went wrong. Please try again.",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showError(String message) async {
    await _tts.speak(message);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Email Registration",
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.person_add_alt_1,
                size: 90,
                color: Color(0xFF0B6E4F),
              ),

              const SizedBox(height: 25),

              const Text(
                "Create Your Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // FULL NAME
              TextField(
                controller: _nameController,
                textInputAction:
                    TextInputAction.next,

                decoration: InputDecoration(
                  labelText: "Full Name",
                  hintText: "Enter your full name",
                  prefixIcon:
                      const Icon(Icons.person),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // STUDENT NUMBER
              TextField(
                controller:
                    _studentNumberController,
                keyboardType:
                    TextInputType.number,
                textInputAction:
                    TextInputAction.next,

                decoration: InputDecoration(
                  labelText: "Student Number",
                  hintText:
                      "Enter your student number",
                  prefixIcon:
                      const Icon(Icons.badge),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // EMAIL
              TextField(
                controller: _emailController,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,

                decoration: InputDecoration(
                  labelText: "Email Address",
                  hintText:
                      "example@email.com",
                  prefixIcon:
                      const Icon(Icons.email),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // PASSWORD
              TextField(
                controller:
                    _passwordController,
                obscureText:
                    _obscurePassword,
                textInputAction:
                    TextInputAction.next,

                decoration: InputDecoration(
                  labelText: "Password",
                  hintText:
                      "At least 6 characters",
                  prefixIcon:
                      const Icon(Icons.lock),

                  suffixIcon: IconButton(
                    tooltip:
                        _obscurePassword
                            ? "Show password"
                            : "Hide password",

                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),

                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CONFIRM PASSWORD
              TextField(
                controller:
                    _confirmPasswordController,
                obscureText:
                    _obscureConfirmPassword,
                textInputAction:
                    TextInputAction.done,

                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),

                  suffixIcon: IconButton(
                    tooltip:
                        _obscureConfirmPassword
                            ? "Show password"
                            : "Hide password",

                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),

                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // REGISTER BUTTON
              SizedBox(
                width: double.infinity,
                height: 65,

                child: ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : _register,

                  icon: _isLoading
                      ? const SizedBox(
                          width: 25,
                          height: 25,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(
                          Icons.person_add,
                          size: 28,
                        ),

                  label: Text(
                    _isLoading
                        ? "Creating Account..."
                        : "Create Account",
                    style: const TextStyle(
                      fontSize: 21,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Central University of Technology\n"
                "Bloemfontein Campus",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}