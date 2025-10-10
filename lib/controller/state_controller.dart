import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/const/messages.dart';

class StateController {
  TaskState state;
  List<TaskState> states;

  StateController() : state = TaskState.empty(), states = [];

  Future<void> loadAllStates() async {
    TaskState tState;
    states.clear();

    try {
      final db = (await FirebaseFirestore.instance.collection(DbConstants.TASKSTATE).get()).docs;

      for (final doc in db) {
        tState = TaskState.fromFirestore(doc, null);
        states.add(tState);
      }
    } catch (e) {
      logError('LOAD ALL STATES', e);
    }
  }

  Future<void> loadState(String stateId) async {
    try {
      /*final db = await FirebaseFirestore.instance
          .collection(DbConstants.TASKSTATE)
          .where('id', isEqualTo: stateId)
          .get();*/

      final db = await FirebaseFirestore.instance.collection(DbConstants.TASKSTATE).doc(stateId).get();

      if (db.exists) {
        state = TaskState.fromFirestore(db, null);
      }
    } catch (e) {
      logError('LOAD STATE', e);
    }
  }

  Future<void> deleteState(String stateId) async {
    try {
      await FirebaseFirestore.instance.collection(DbConstants.TASKSTATE).doc(stateId).delete();
      states.removeWhere((TaskState state) => state.id == stateId);
    } catch (e) {
      logError('DELETE STATE', e);
    }
  }

  Future<void> updateState(TaskState tState) async {
    try {
      await FirebaseFirestore.instance.collection(DbConstants.TASKSTATE).doc(tState.id).update(tState.toFirestore());
    } catch (e) {
      logError('UPDATE STATE', e);
    }
  }

  Future<void> createState(TaskState tState) async {
    try {
      await FirebaseFirestore.instance.collection(DbConstants.TASKSTATE).add(tState.toFirestore());
    } catch (e) {
      logError('CREATE STATE', e);
    }
  }

  Color? getShade200(Color? color) {
    if (color is MaterialColor) {
      return color.shade200;
    }
    return color;
  }

  Color? getShade600(Color? color) {
    if (color is MaterialColor) {
      return color.shade600;
    }
    return color;
  }
}
