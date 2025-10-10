import 'package:flutter/material.dart';
import 'package:to_do_list/utils/const/app_strings.dart';

enum TaskStateee {
  NONE,
  PENDING,
  INPROGRES,
  COMPLETED;

  static TaskStateee stateFromString(String str) {
    switch (str) {
      case AppStrings.ST_COMP:
        return TaskStateee.COMPLETED;
      case AppStrings.ST_INP:
        return TaskStateee.INPROGRES;
      case AppStrings.ST_PEND:
        return TaskStateee.PENDING;
      default:
        return TaskStateee.NONE;
    }
  }

  static String stateToString(TaskStateee state) {
    switch (state) {
      case TaskStateee.COMPLETED:
        return AppStrings.ST_COMP;
      case TaskStateee.INPROGRES:
        return AppStrings.ST_INP;
      case TaskStateee.PENDING:
        return AppStrings.ST_PEND;
      case TaskStateee.NONE:
        return '';
    }
  }

  static bool isDone(TaskStateee state) {
    return state == COMPLETED;
  }

  static TaskStateee changeState(TaskStateee state) {
    List<TaskStateee> states = TaskStateee.values.skip(1).toList();
    int index = states.indexOf(state) + 1;
    if (index == states.length) {
      index = 0;
    }
    return states[index];
  }

  static Color? stateColor(TaskStateee state) {
    switch (state) {
      case TaskStateee.COMPLETED:
        return Colors.green.shade200;
      case TaskStateee.INPROGRES:
        return Colors.orange.shade200;
      case TaskStateee.PENDING:
        return null;
      case TaskStateee.NONE:
        return Colors.black;
    }
  }

  static Color? iconColorByState(TaskStateee state){
       switch (state) {
      case TaskStateee.COMPLETED:
        return Colors.green.shade600;
      case TaskStateee.INPROGRES:
        return Colors.orange.shade600;
      case TaskStateee.PENDING:
        return null;
      case TaskStateee.NONE:
        return null;
    }
  }
}
