import 'package:flutter/material.dart';

enum Entity { NONE, TASK, USER, TEAM, NOTIFICATION, TASKSTATE, TEAM_TASK, USER_TASK, USER_TEAM }

enum ChangeType {
  NONE,
  CREATE,
  UPDATE,
  DELETE;

  Color? getColor() {
    switch (this) {
      case ChangeType.NONE:
        return null;
      case ChangeType.CREATE:
        return Colors.lightGreen.shade400;
      case ChangeType.UPDATE:
        return Colors.orange.shade300;
      case ChangeType.DELETE:
        return Colors.red.shade300;
    }
  }

  Color textColor() {
    switch (this) {
      case ChangeType.NONE:
        return Colors.black;
      case ChangeType.CREATE:
        return Colors.black;
      case ChangeType.UPDATE:
        return Colors.black;
      case ChangeType.DELETE:
        return Colors.black;
    }
  }
}
