import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
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
      TaskController tc = TaskController();
      await tc.loadAllTasksFromDB();
      var tasks = tc.tasks;
      tasks = tasks.where((Task tsk) => tsk.state.id == stateId).toList();
      
      for (Task task in tasks) {
        logPrintClass(task.toString());
        task.state = defaultState();
        tc.updateTask(task);
      }

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
      final docRef = await FirebaseFirestore.instance.collection(DbConstants.TASKSTATE).add(tState.toFirestore());
      String stateId = docRef.id;
      tState.id = stateId;
    } catch (e) {
      logError('CREATE STATE', e);
    }
  }

  TaskState defaultState() {
    return getStateByName(AppStrings.DEFAULT_STATES[0]);
    //return TaskState(id:'TaPsLJBEtQizeFUxc5jU', name: 'Completada', color: Colors.green);
  }

  TaskState getStateByName(String name) {
    return states.firstWhere((state) => state.name == name);
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
