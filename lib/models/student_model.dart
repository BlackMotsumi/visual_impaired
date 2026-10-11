import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String uid;
  final String fullName;
  final String studentNumber;
  final String email;
  final String registrationMethod;
  final DateTime createdAt;

  StudentModel({
    required this.uid,
    required this.fullName,
    required this.studentNumber,
    required this.email,
    required this.registrationMethod,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'studentNumber': studentNumber,
      'email': email,
      'registrationMethod': registrationMethod,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      studentNumber: map['studentNumber'] ?? '',
      email: map['email'] ?? '',
      registrationMethod:
          map['registrationMethod'] ?? '',
      createdAt:
          (map['createdAt'] as Timestamp).toDate(),
    );
  }
}