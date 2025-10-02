import 'package:flutter/material.dart';
import 'package:to_do_list/utils/const/app_strings.dart';

enum TaskState {
  NONE,
  PENDING,
  INPROGRES,
  COMPLETED;

  static TaskState stateFromString(String str) {
    switch (str) {
      case AppStrings.ST_COMP:
        return TaskState.COMPLETED;
      case AppStrings.ST_INP:
        return TaskState.INPROGRES;
      case AppStrings.ST_PEND:
        return TaskState.PENDING;
      default:
        return TaskState.NONE;
    }
  }

  static String stateToString(TaskState state) {
    switch (state) {
      case TaskState.COMPLETED:
        return AppStrings.ST_COMP;
      case TaskState.INPROGRES:
        return AppStrings.ST_INP;
      case TaskState.PENDING:
        return AppStrings.ST_PEND;
      case TaskState.NONE:
        return '';
    }
  }

  static bool isDone(TaskState state) {
    return state == COMPLETED;
  }

  static TaskState changeState(TaskState state) {
    List<TaskState> states = TaskState.values.skip(1).toList();
    int index = states.indexOf(state) + 1;
    if (index == states.length) {
      index = 0;
    }
    return states[index];
  }

  static Color? stateColor(TaskState state) {
    switch (state) {
      case TaskState.COMPLETED:
        return Colors.green.shade200;
      case TaskState.INPROGRES:
        return Colors.orange.shade200;
      case TaskState.PENDING:
        return null;
      case TaskState.NONE:
        return Colors.black;
    }
  }

  static Color? iconColorByState(TaskState state){
       switch (state) {
      case TaskState.COMPLETED:
        return Colors.green.shade600;
      case TaskState.INPROGRES:
        return Colors.orange.shade600;
      case TaskState.PENDING:
        return null;
      case TaskState.NONE:
        return null;
    }
  }
}
