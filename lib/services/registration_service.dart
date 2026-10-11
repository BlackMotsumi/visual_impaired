import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/student_model.dart';

class RegistrationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<UserCredential> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String studentNumber,
    required String registrationMethod,
  }) async {
    print('STEP 1: Creating Firebase Authentication account...');

    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    print('STEP 2: Firebase Authentication account created.');

    final User? user = credential.user;

    if (user == null) {
      throw Exception(
        'Firebase account was created but no user was returned.',
      );
    }

    print('STEP 3: Firebase UID = ${user.uid}');

    final student = StudentModel(
      uid: user.uid,
      fullName: fullName,
      studentNumber: studentNumber,
      email: email,
      registrationMethod: registrationMethod,
      createdAt: DateTime.now(),
    );

    print('STEP 4: Saving student to Firestore...');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(student.toMap())
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw Exception(
              'Firestore request timed out after 20 seconds.',
            );
          },
        );

    print('STEP 5: Student successfully saved to Firestore.');

    return credential;
  }
}