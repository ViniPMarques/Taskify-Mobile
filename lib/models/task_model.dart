import 'package:flutter/material.dart';

class Task {
  int? id;
  String title;
  String description;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  String? imagePath;

  Task({
    this.id,
    required this.title,
    required this.description,
    this.dueDate,
    this.dueTime,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime != null ? "${dueTime!.hour}:${dueTime!.minute}" : null,
      'imagePath': imagePath,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      dueTime: map['dueTime'] != null ? TimeOfDay(
          hour: int.parse(map['dueTime'].split(":")[0]),
          minute: int.parse(map['dueTime'].split(":")[1])
      ) : null,
      imagePath: map['imagePath'],
    );
  }
}

