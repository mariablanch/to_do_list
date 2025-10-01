import 'package:flutter/material.dart';
import 'package:to_do_list/utils/const/app_strings.dart';

enum Priorities {
  NONE,
  HIGH,
  MEDIUM,
  LOW;

  static Icon getIconPriority(Priorities priority, bool hasPassed) {
    //Priorities priority = task.priority;
    Color defColor = Colors.white;
    switch (priority) {
      case Priorities.HIGH:
        return Icon(Icons.arrow_upward, color: hasPassed ? defColor : Colors.redAccent);
      case Priorities.MEDIUM:
        return Icon(Icons.keyboard_arrow_up, color: hasPassed ? defColor : Colors.orange.shade800);
      case Priorities.LOW:
        return Icon(Icons.arrow_drop_up, color: hasPassed ? defColor : Colors.green.shade700);
      default:
        return Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  static Priorities priorityFromString(String str) {
    switch (str) {
      case AppStrings.PR_HIGH:
        return Priorities.HIGH;
      case AppStrings.PR_MEDIUM:
        return Priorities.MEDIUM;
      case AppStrings.PR_LOW:
        return Priorities.LOW;
      default:
        return Priorities.NONE;
    }
  }

  static String priorityToString(Priorities priority) {
    switch (priority) {
      case Priorities.HIGH:
        return AppStrings.PR_HIGH;
      case Priorities.MEDIUM:
        return AppStrings.PR_MEDIUM;
      case Priorities.LOW:
        return AppStrings.PR_LOW;
      case Priorities.NONE:
        return '';
    }
  }
}
