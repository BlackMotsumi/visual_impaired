import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FlutterTts _tts = FlutterTts();

  final bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _speakInstructions();
  }

  Future<void> _speakInstructions() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);

    await _tts.speak(
      "A six digit verification code has been sent "
      "to your phone number. Please enter the code.",
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    // Firebase verification will be added next.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Phone Number"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sms,
                size: 90,
                color: Color(0xFF0B6E4F),
              ),

              const SizedBox(height: 30),

              const Text(
                "Enter Verification Code",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                "Code sent to ${widget.phoneNumber}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  letterSpacing: 10,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: "000000",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyCode,
                  child: _isVerifying
                      ? const CircularProgressIndicator()
                      : const Text(
                          "Verify Code",
                          style: TextStyle(fontSize: 22),
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