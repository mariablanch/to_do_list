import 'package:flutter/material.dart';

enum Priorities {
  NONE,
  HIGH,
  MEDIUM,
  LOW;

  static Icon getIconPriority(Priorities priority){
    //Priorities priority = task.priority;
    switch (priority) {
      case Priorities.HIGH:
        return Icon(Icons.arrow_upward, color: Colors.red);
      case Priorities.MEDIUM:
        return Icon(Icons.keyboard_arrow_up, color: Colors.orange);
      case Priorities.LOW:
        return Icon(Icons.arrow_drop_up, color: Colors.green);
      default:
        return Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  static Priorities priorityFromString(String str) {
    switch (str) {
      case 'Alt':
        return Priorities.HIGH;
      case 'Mitjà':
        return Priorities.MEDIUM;
      case 'Baix':
        return Priorities.LOW;
      default:
        return Priorities.NONE;
    }
  }

  static String priorityToString(Priorities priority) {
    switch (priority) {
      case Priorities.HIGH:
        return 'Alt';
      case Priorities.MEDIUM:
        return 'Mitjà';
      case Priorities.LOW:
        return 'Baix';
      case Priorities.NONE:
        return '';
    }
  }
}
