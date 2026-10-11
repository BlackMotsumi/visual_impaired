import 'package:flutter/material.dart';

class CampusBuilding {
  final String name;
  final String type;
  final IconData icon;
  final String description;
  final String seats;
  final String openingTime;
  final String closingTime;
  final double? latitude;
  final double? longitude;

  const CampusBuilding({
    required this.name,
    required this.type,
    required this.icon,
    required this.description,
    required this.seats,
    required this.openingTime,
    required this.closingTime,
    required this.latitude,
    required this.longitude,
  });
}