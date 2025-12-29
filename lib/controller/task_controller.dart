// ignore_for_file: unnecessary_this

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/controller/history_controller.dart';

import 'package:to_do_list/controller/notification_controller.dart';
import 'package:to_do_list/controller/state_controller.dart';
import 'package:to_do_list/controller/team_controller.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/relation_tables/team_task.dart';
import 'package:to_do_list/model/relation_tables/user_task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/sort.dart';
import 'package:to_do_list/model/task.dart';

class TaskController {
  List<Task> tasks;

  TaskController({List<Task>? tasks}) : this.tasks = tasks ?? [];
  //TaskController(List<Task> tasks) : this.tasks = tasks;

  //LOAD
  Future<void> loadTasksFromDB(String userId) async {
    Task task;
    try {
      List<Task> loadedTasks = [];

      //AGAFAR TASQUES DE LA RELACIÓ
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.USERID, isEqualTo: userId)
          .get();

      List<String> taskIds = db.docs.map((doc) => doc[DbConstants.TASKID] as String).toList();

      if (taskIds.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection(DbConstants.TASK)
            .where(FieldPath.documentId, whereIn: taskIds)
            .where(DbConstants.DELETED, isEqualTo: false)
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

  Future<void> loadAllTasksFromDB(bool configPage) async {
    try {
      if (configPage) {
        this.tasks = await _loadDeletedTask();
      } else {
        this.tasks = await _loadAllNormalTask();
      }
    } catch (e) {
      logError('LOAD ALL TASKS FROM DB', e);
    }
  }

  Future<List<Task>> _loadDeletedTask() async {
    Task task;
    List<Task> loadedTasks = [];
    try {
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
    } catch (e) {
      logError('LOAD DELETED TASK', e);
    }
    return loadedTasks;
  }

  Future<List<Task>> _loadAllNormalTask() async {
    Task task;
    List<Task> loadedTasks = [];
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.TASK)
          .where(DbConstants.DELETED, isEqualTo: false)
          .get();
      for (var doc in db.docs) {
        if (doc.exists) {
          task = await _loadTask(doc);
          loadedTasks.add(task);
        }
      }
      loadedTasks.sort((task1, task2) {
        return TaskController.sortTask(SortType.NONE, task1, task2, {});
      });
    } catch (e) {
      logError('LOAD NORMAL TASK', e);
    }
    return loadedTasks;
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

  Future<String> getUsersRelatedWithTask(String taskId) async {
    List<String> userNames = [];
    String str = '';
    String userName = '';
    UserController uc = UserController();
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .get();

      for (var doc in db.docs) {
        String userId = doc.get(DbConstants.USERID);
        userName = (await uc.getUserById(userId)).userName;
        userNames.add(userName);
      }

      userNames.sort();

      str = userNames.join(AppStrings.SEPARATOR);
    } catch (e) {
      logError('GET USERS RELATED WITH TASK', e);
    }

    return str;
  }

  //CREATE
  //    TASK
  Future<void> addTaskToDataBase(Task newTask, User creator) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection(DbConstants.TASK).add(newTask.toFirestore());
      String taskId = docRef.id;
      newTask.id = taskId;

      HistoryController.createTask(newTask, creator);
    } catch (e) {
      logError('ADD TASK TO DATABASE', e);
    }
  }

  //    USER RELATION
  Future<void> addTaskToDataBaseUser(Task newTask, User user, User creator) async {
    try {
      await addTaskToDataBase(newTask, creator);
      await createUserTaskRelation(newTask, user);
    } catch (e) {
      logError('ADD TASK TO DATABASE USER', e);
    }
  }

  Future<void> createUserTaskRelation(Task task, User user) async {
    UserTask ut = UserTask(task: task, user: user);
    try {
      await FirebaseFirestore.instance.collection(DbConstants.USERTASK).add(ut.toFirestore());
    } catch (e) {
      logError('CREATE RELATION', e);
    }
  }

  //    TEAM RELATION
  Future<void> addTaskToDataBaseTeam(TeamTask tt) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection(DbConstants.TASK).add(tt.task.toFirestore());

      String taskId = docRef.id;
      tt.task.id = taskId;

      //createRelation(taskId, userName);
      addTaskToTeam(tt);
    } catch (e) {
      logError('ADD TASK TO DATABASE', e);
    }
  }

  Future<void> addTaskToTeam(TeamTask tt) async {
    await FirebaseFirestore.instance.collection(DbConstants.TEAMTASK).add(tt.toFirestore());
  }

  //UPDATE TASK
  Future<void> updateTask(Task task) async {
    StateController stateController = StateController();
    try {
      stateController.loadAllStates();
      if (task.state.name == AppStrings.DEFAULT_STATES[2] && task.completedDate == null) {
        task = task.copyWith(completedDate: DateTime.now());
      } else if (task.state.name != AppStrings.DEFAULT_STATES[2] && task.completedDate != null) {
        task = task.copyWith(completedDate: null);
      }
      await FirebaseFirestore.instance.collection(DbConstants.TASK).doc(task.id).update(task.toFirestore());
    } catch (e) {
      logError('UPDATE TASK', e);
    }
  }
  //UPDATE RELATION USER - TASK && TEAM - TASK (almb el bool de deleted)

  //DELETE TASK
  Future<void> _deleteTask(String taskId) async {
    try {
      await FirebaseFirestore.instance.collection(DbConstants.TASK).doc(taskId).delete();
    } catch (e) {
      logError('DELETE TASK', e);
    }
  }

  Future<void> deleteUserTaskRelationsByUser(User user) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.USERID, isEqualTo: user.id)
          .get();

      for (var doc in db.docs) {
        final taskId = doc.get(DbConstants.TASKID);
        await removeTaskUser(taskId, user.id);
      }
    } catch (e) {
      logError('DELETE USER-TASK BY USER', e);
    }
  }

  Future<void> _deleteUserTaskRelations(String taskId) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .get();

      for (var doc in db.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      logError('DELETE USER-TASK RELATION', e);
    }
  }

  Future<void> _deleteUserTaskRelation(String userId, String taskId) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .where(DbConstants.USERID, isEqualTo: userId)
          .get();
      for (var doc in db.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      logError('DELETE USER-TASK RELATION', e);
    }
  }

  Future<void> removeTaskUser(String taskId, String userId) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .get();

      if (db.docs.length == 1) {
        await _deleteUserTask(taskId);
      } else {
        await _deleteUserTaskRelation(userId, taskId);
      }
    } catch (e) {
      logError('REMOVE TASK', e);
    }
  }

  Future<void> _deleteUserTask(String taskId) async {
    try {
      await _deleteTask(taskId);
      await _deleteUserTaskRelations(taskId);
      await NotificationController().deleteNotificationByTask(taskId);
    } catch (e) {
      logError('DELETE TASK WITH USER RELATION', e);
    }
  }

  Future<void> removeTeam(String taskId, String teamName) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.TEAMTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .get();

      if (db.docs.length == 1) {
        await deleteTaskWithTeamRelation(taskId);
      } else {
        String teamId = (await TeamController().loadTeamTask(
          false,
        )).firstWhere((tt) => tt.task.id == taskId && tt.team.name == teamName).team.id;

        final db = await FirebaseFirestore.instance
            .collection(DbConstants.TEAMTASK)
            .where(DbConstants.TASKID, isEqualTo: taskId)
            .where(DbConstants.TEAMID, isEqualTo: teamId)
            .get();

        for (var doc in db.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      logError('REMOVE TEAM', e);
    }
  }

  Future<void> deleteTaskWithTeamRelation(String taskId) async {
    try {
      await _deleteTask(taskId);
      await _deleteTeamTaskRelations(taskId);
      await NotificationController().deleteNotificationByTask(taskId);
    } catch (e) {
      logError('DELETE TASK WITH TEAM RELATION', e);
    }
  }

  Future<void> _deleteTeamTaskRelations(String taskId) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.TEAMTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .get();

      for (var doc in db.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      logError('DELETE TEAM-TASK BY TASK', e);
    }
  }

  Future<void> disableTask(Task task) async {
    try {
      task = task.copyWith(deleted: true, completedDate: task.completedDate);
      await updateTask(task);
    } catch (e) {
      logError('DISABLE TASK', e);
    }
  }

  //OTHER
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
        int len1 = str1.split(AppStrings.SEPARATOR).length;
        int len2 = str2.split(AppStrings.SEPARATOR).length;
        int ret = len2 - len1;
        if (ret == 0) {
          ret = str1.compareTo(str2);
        }
        return ret;
    }
  }
}
