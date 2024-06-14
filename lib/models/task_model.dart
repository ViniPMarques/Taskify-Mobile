import 'package:flutter/material.dart';

class Task {
  final int? id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;

  Task({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime != null
          ? '${dueTime!.hour}:${dueTime!.minute}'
          : null,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      dueTime: map['dueTime'] != null
          ? TimeOfDay(
        hour: int.parse(map['dueTime'].split(':')[0]),
        minute: int.parse(map['dueTime'].split(':')[1]),
      )
          : null,
    );
  }
}
