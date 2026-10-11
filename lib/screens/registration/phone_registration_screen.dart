import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../otp/otp_screen.dart';

class PhoneRegistrationScreen extends StatefulWidget {
  const PhoneRegistrationScreen({super.key});

  @override
  State<PhoneRegistrationScreen> createState() =>
      _PhoneRegistrationScreenState();
}

class _PhoneRegistrationScreenState
    extends State<PhoneRegistrationScreen> {

  final TextEditingController _phoneController = TextEditingController();

  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speak();
  }

  Future<void> _speak() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);

    await _tts.speak(
      "Please enter your South African cellphone number beginning with zero."
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _phoneController.dispose();
    super.dispose();
  }

  String formatNumber(String value) {

    value = value.replaceAll(" ", "");

    if (value.length > 3) {
      value = "${value.substring(0,3)} ${value.substring(3)}";
    }

    if (value.length > 7) {
      value = "${value.substring(0,7)} ${value.substring(7)}";
    }

    return value;
  }

  bool isValidNumber(String number) {

    number = number.replaceAll(" ", "");

    return RegExp(r'^0[6-8][0-9]{8}$').hasMatch(number);

  }

  Future<void> _continue() async {
  final phone = _phoneController.text.replaceAll(" ", "");

  if (!isValidNumber(phone)) {
    await _tts.speak(
      "The phone number entered is not valid. "
      "Please check the number and try again.",
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Enter a valid South African cellphone number",
        ),
      ),
    );

    return;
  }

  final firebaseNumber = "+27${phone.substring(1)}";

  await _tts.speak(
    "Thank you. Sending your verification code.",
  );

  if (!mounted) return;

  try {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: firebaseNumber,

      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      },

      verificationFailed: (FirebaseAuthException e) async {
        await _tts.speak(
          "We could not send the verification code. "
          "Please check your phone number and try again.",
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? "Phone verification failed.",
            ),
          ),
        );
      },

      codeSent: (
        String verificationId,
        int? resendToken,
      ) {
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: phone,
            ),
          ),
        );
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  } catch (e) {
    if (!mounted) return;

    await _tts.speak(
      "Something went wrong. Please try again.",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Phone Registration"),
      ),

      body: Padding(

        padding: const EdgeInsets.all(25),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.phone_android,
              size: 90,
              color: Color(0xFF0B6E4F),
            ),

            const SizedBox(height: 30),

            const Text(
              "South African Cellphone Number",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Example: 072 123 4567",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 40),

            TextField(

              controller: _phoneController,

              keyboardType: TextInputType.phone,

              inputFormatters: [

                FilteringTextInputFormatter.digitsOnly,

                LengthLimitingTextInputFormatter(10),

              ],

              onChanged: (value) {

                final formatted = formatNumber(value);

                _phoneController.value = TextEditingValue(

                  text: formatted,

                  selection: TextSelection.collapsed(
                    offset: formatted.length,
                  ),

                );

              },

              decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  hintText: "081 420 5438",
                  labelText: "Cellphone number",
                ),
                         ),

            const SizedBox(height: 40),

            SizedBox(

              width: double.infinity,

              height: 60,

              child: ElevatedButton(

                onPressed: _continue,

                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 22),
                ),

              ),

            ),
          ],
        ),
      ),
    );
  }
}