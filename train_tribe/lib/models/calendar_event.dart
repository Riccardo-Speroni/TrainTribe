import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id; // Unique identifier for the event
  String? generatedBy; // ID of the original event for recurrent copies
  DateTime date;
  int hour; // Start hour
  int endHour; // End hour
  String departureStation;
  String arrivalStation;
  double? widthFactor; // Factor to adjust width for overlapping events
  Alignment? alignment; // Alignment for the event cell
  bool isBeingDragged = false; // Indicates if the event is being dragged
  bool isRecurrent; // Indicates if the event is recurrent
  DateTime? recurrenceEndDate; // End date for recurrence

  CalendarEvent({
    String? id,
    this.generatedBy,
    required this.date,
    required this.hour,
    required this.endHour,
    required this.departureStation,
    required this.arrivalStation,
    this.widthFactor,
    this.alignment,
    this.isRecurrent = false,
    this.recurrenceEndDate,
  }) : id = id ?? const Uuid().v4(); // Generate a unique ID if not provided

  // Factory per creare un evento da un documento Firebase
  factory CalendarEvent.fromFirestore(String id, Map<String, dynamic> data) {
    final DateTime start = (data['event_start'] as Timestamp).toDate();
    final DateTime end = (data['event_end'] as Timestamp).toDate();
    return CalendarEvent(
      id: id,
      date: DateTime(start.year, start.month, start.day),
      hour: ((start.hour - 6) * 4 + (start.minute ~/ 15)).clamp(0, 75),
      endHour: ((end.hour - 6) * 4 + (end.minute ~/ 15)).clamp(0, 76),
      departureStation: data['origin'] ?? '',
      arrivalStation: data['destination'] ?? '',
      isRecurrent: data['recurrent'] ?? false,
      recurrenceEndDate: data['recurrence_end'] != null
          ? (data['recurrence_end'] as Timestamp).toDate()
          : null,
    );
  }
}
