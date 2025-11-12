// ignore_for_file: unnecessary_this

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:to_do_list/controller/notification_controller.dart';
import 'package:to_do_list/controller/state_controller.dart';
import 'package:to_do_list/controller/team_controller.dart';
import 'package:to_do_list/model/relation_tables/team_task.dart';
import 'package:to_do_list/model/relation_tables/user_task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/sort.dart';
import 'package:to_do_list/model/task.dart';

class TaskController {
  List<Task> tasks;

  TaskController({List<Task>? tasks}) : this.tasks = tasks ?? [];
  //TaskController(List<Task> tasks) : this.tasks = tasks;

  Future<void> loadTasksFromDB(String userName) async {
    Task task;
    try {
      List<Task> loadedTasks = [];

      //AGAFAR TASQUES DE LA RELACIÓ
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      List<String> taskIds = db.docs.map((doc) => doc[DbConstants.TASKID] as String).toList();

      if (taskIds.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection(DbConstants.TASK)
            .where(FieldPath.documentId, whereIn: taskIds)
            .get();

        for (var doc in query.docs) {
          task = await _loadTask(doc);
          loadedTasks.add(task);
        }
      }

      loadedTasks.sort((task1, task2) {
        return TaskController.sortTask(SortType.NONE, task1, task2, {});
      });

      this.tasks = loadedTasks;
    } catch (e) {
      logError('LOAD TASKS FROM DB', e);
    }
  }

  Future<Task> _loadTask(doc) async {
    StateController sc = StateController();
    TaskState state;
    Task task = Task.fromFirestore(doc, null);
    await sc.loadState(task.state.id);
    state = sc.state.copyWith();
    task.state = state;
    return task;
  }

  Future<void> loadAllTasksFromDB() async {
    Task task;
    try {
      List<Task> loadedTasks = [];

      final db = await FirebaseFirestore.instance.collection(DbConstants.TASK).get();

      for (var doc in db.docs) {
        if (doc.exists) {
          task = await _loadTask(doc);

          loadedTasks.add(task);
        }
      }

      loadedTasks.sort((task1, task2) {
        return TaskController.sortTask(SortType.NONE, task1, task2, {});
      });

      this.tasks = loadedTasks;
    } catch (e) {
      logError('LOAD ALL TASKS FROM DB', e);
    }
  }

  Future<List<Task>> loadTaskByTeam(Team team) async {
    List<Task> loadedTasks = [];
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.TEAMTASK)
          .where(DbConstants.TEAMID, isEqualTo: team.id)
          .get();
      for (var doc in db.docs) {
        TeamTask tt = TeamTask.fromFirestore(doc, null);
        String taskId = tt.task.id;
        final db2 = await FirebaseFirestore.instance.collection(DbConstants.TASK).doc(taskId).get();
        if (db2.exists) {
          loadedTasks.add(Task.fromFirestore(db2, null));
        }
      }
    } catch (e) {
      logError('LOAD TASK BY TEAM', e);
    }
    return loadedTasks;
  }

  Future<Task> getTaskByID(String taskId) async {
    Task task = Task.empty();
    try {
      final doc = await FirebaseFirestore.instance.collection(DbConstants.TASK).doc(taskId).get();

      if (doc.exists) {
        task = await _loadTask(doc);
      }
    } catch (e) {
      logError('GET TASK BY ID', e);
    }
    //this.tasks.add(task);
    return task;
  }

  Future<void> updateTask(Task task) async {
    StateController stateController = StateController();
    try {
      stateController.loadAllStates();

      if (task.state.name == AppStrings.DEFAULT_STATES[2] && task.completedDate == null) {
        task = task.copyWith(completedDate: DateTime.now());
      } else if (task.state.name != AppStrings.DEFAULT_STATES[2] && task.completedDate != null) {
        task = task.copyWith(completedDate: null);
      }

      /*if (stateController.states.any((s) => s.name == AppStrings.DEFAULT_STATES[2])) {
        //task = task.copyWith(state: stateController.getStateByName(stateNames[index]), completedDate: );
      }*/

      await FirebaseFirestore.instance.collection(DbConstants.TASK).doc(task.id).update(task.toFirestore());
    } catch (e) {
      logError('UPDATE TASK', e);
    }
  }

  Future<void> addTaskToDataBaseUser(Task newTask, String userName) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection(DbConstants.TASK).add(newTask.toFirestore());

      String taskId = docRef.id;
      newTask.id = taskId;

      createRelation(taskId, userName);
    } catch (e) {
      logError('ADD TASK TO DATABASE', e);
    }
  }

  Future<void> addTaskToDataBaseTeam(TeamTask tt) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection(DbConstants.TASK).add(tt.task.toFirestore());

      String taskId = docRef.id;
      tt.task.id = taskId;

      //createRelation(taskId, userName);
      TeamController().addTaskToTeam(tt);
    } catch (e) {
      logError('ADD TASK TO DATABASE', e);
    }
  }

  Future<void> createRelation(String taskId, String userName) async {
    UserTask ut = UserTask(taskId: taskId, userName: userName);

    try {
      await FirebaseFirestore.instance.collection(DbConstants.USERTASK).add(ut.toFirestore());
    } catch (e) {
      logError('CREATE RELATION', e);
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await FirebaseFirestore.instance.collection(DbConstants.TASK).doc(taskId).delete();
    } catch (e) {
      logError('DELETE TASK', e);
    }
  }

  Future<void> deleteUserTaskRelationsByUser(String userName) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      for (var doc in db.docs) {
        final taskId = doc.get(DbConstants.TASKID);
        await removeTask(taskId, userName);
      }
    } catch (e) {
      logError('DELETE USER-TASK BY USER', e);
    }
  }

  Future<void> _deleteUserTaskRelationsByTask(String taskId) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .get();

      for (var doc in db.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      logError('DELETE USER-TASK BY TASK', e);
    }
  }

  Future<void> _deleteUserTaskRelation(String userName, String taskId) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();
      for (var doc in db.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      logError('DELETE USER-TASK RELATION', e);
    }
  }

  Future<void> removeTask(String taskId, String userName) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .get();

      if (db.docs.length == 1) {
        await deleteTaskWithRelation(taskId);
      } else {
        await _deleteUserTaskRelation(userName, taskId);
      }
    } catch (e) {
      logError('REMOVE TASK', e);
    }
  }

  Future<void> deleteTaskWithRelation(String taskId) async {
    try {
      await _deleteTask(taskId);
      await _deleteUserTaskRelationsByTask(taskId);
      await NotificationController().deleteNotificationByTask(taskId);
    } catch (e) {
      logError('DELETE TASK WITH RELATION', e);
    }
  }

  Future<String> getUsersRelatedWithTask(String taskId) async {
    List<String> userNames = [];
    String str = '';
    String userName = '';
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .get();

      for (var doc in db.docs) {
        userName = doc.get(DbConstants.USERNAME);
        userNames.add(userName);
      }

      userNames.sort();

      str = userNames.join(AppStrings.USER_SEPARATOR);
    } catch (e) {
      logError('GET USERS RELATED WITH TASK', e);
    }

    return str;
  }

  static int sortTask(SortType type, Task task1, Task task2, Map<String, String> usersMAP) {
    switch (type) {
      case SortType.NONE: //PRIORITAT
        return task1.compareTo(task2);
      case SortType.DATE:
        return task1.limitDate.compareTo(task2.limitDate);
      case SortType.NAME:
        return task1.name.compareTo(task2.name);
      case SortType.USER:
        String str1 = usersMAP[task1.id] ?? '';
        String str2 = usersMAP[task2.id] ?? '';
        int len1 = str1.split(AppStrings.USER_SEPARATOR).length;
        int len2 = str2.split(AppStrings.USER_SEPARATOR).length;
        int ret = len2 - len1;
        if (ret == 0) {
          ret = str1.compareTo(str2);
        }
        return ret;
    }
  }
}
