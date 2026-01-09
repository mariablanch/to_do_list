import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/utils/interfaces.dart';
import 'package:to_do_list/utils/priorities.dart';
import 'package:to_do_list/utils/user_role.dart';
import 'package:uuid/uuid.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/history.dart';
import 'package:to_do_list/model/notification.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/history_enums.dart';

class HistoryController {
  static const String _DELETED = DbConstants.DELETED;

  static Future<List<History>> _loadAllHistory() async {
    try {
      List<History> ret = [];
      History hist;
      final db = await FirebaseFirestore.instance.collection(DbConstants.HISTORY).get();
      for (final doc in db.docs) {
        hist = History.fromFirestore(doc, null);
        hist.user = await UserController().getUserById(hist.user.id);
        ret.add(hist);
      }
      ret.sort();
      return ret;
    } catch (e) {
      logError('LOAD ALL HISTORY', e);
      return [];
    }
  }

  static String _generateID() {
    return const Uuid().v4();
  }

  /// Agrupa els canvis indivuduals de la base de dades a un sol objecte
  ///
  /// Retorna: ```Map<History, Object>```
  ///- Key   → History amb dades essencials (data, usuari, tipus, entitat)
  ///- Value → Objecte (Task/User/Team/...)
  static Future<Map<History, BaseEntity>> eventMap() async {
    Map<History, BaseEntity> ret = {};
    Map<String, List<History>> temp = {};
    List<History> allHistory = await _loadAllHistory();
    History h;

    //SORT PER A Q ESTIGUI DEL REVES (mes antigues damunt)
    allHistory = allHistory.reversed.toList();

    for (var hist in allHistory) {
      temp.putIfAbsent(hist.idChange, () => []).add(hist);
    }

    final Map<String, List<History>> lastHistoryByEntity = {};

    for (var line in temp.entries) {
      String idObj = line.value.first.idEntity;

      List<History>? oldValue = lastHistoryByEntity[idObj];
      BaseEntity obj = _historyToObject(line.value, oldValue);

      lastHistoryByEntity[idObj] = line.value;

      h = History(
        id: "",
        idChange: line.value.first.idChange,
        idEntity: line.value.first.idEntity,
        user: line.value.first.user,
        newValue: line.value.first.newValue,
        oldValue: line.value.first.oldValue,
        changeType: line.value.first.changeType,
        field: line.value.first.field,
        entity: line.value.first.entity,
        time: line.value.first.time,
      );
      ret[h] = obj;
    }

    //SORT MAP PER A Q ESTIGUI AMB EL ORDRE CORRECTE (més noves primer)
    ret = Map.fromEntries(ret.entries.toList().reversed);

    return ret;
  }

  static BaseEntity _historyToObject(List<History> list, [List<History>? oldValue]) {
    switch (list.first.entity) {
      case Entity.NONE:
        return Task.empty();
      case Entity.TASK:
        return _mapTask(list, oldValue);
      case Entity.USER:
        return _mapUser(list, oldValue);
      case Entity.TEAM:
        // TODO: Handle this case.
        logToDo("Map de list<History> a Team", "HistoryController(_historyToObject)");
        return Team.empty();
      case Entity.NOTIFICATION:
        // TODO: Handle this case.
        logToDo("Map de list<History> a Notification", "HistoryController(_historyToObject)");
        return Notifications.empty();
      case Entity.TASKSTATE:
        // TODO: Handle this case.
        logToDo("Map de list<History> a TaskState", "HistoryController(_historyToObject)");
        return TaskState.empty();
      case Entity.TEAM_TASK:
        // TODO: Handle this case.
        logToDo("Map de list<History> a TeamTask", "HistoryController(_historyToObject)");
        return Team.empty();
      case Entity.USER_TASK:
        // TODO: Handle this case.
        logToDo("Map de list<History> a UserTask", "HistoryController(_historyToObject)");
        return Team.empty();
      case Entity.USER_TEAM:
        // TODO: Handle this case.
        logToDo("Map de list<History> a UserTeam", "HistoryController(_historyToObject)");
        return Team.empty();
    }
  }

  /// Selecciona nomes els camps que han estat editats
  ///
  /// Retorna: `Map<String, String>` amb les claus i els nous valors que han canviat.
  ///- Key   → Nom del camp (name/)
  ///- Value → Objecte (Task/User/Team/...)
  static Map<String, String> _changedFields(Map<String, String> oldO, Map<String, String> newO) {
    Map<String, String> ret = {};

    for (var item in newO.entries) {
      if (oldO[item.key] != item.value) {
        ret[item.key] = item.value;
      }
    }
    return ret;
  }

  static Future<void> _delete<T extends BaseEntity>(User creator, T entity, Entity e) async {
    try {
      final history = History(
        id: "",
        idChange: _generateID(),
        idEntity: entity.id,
        user: creator,
        newValue: "true",
        oldValue: "false",
        changeType: ChangeType.DELETE,
        field: _DELETED,
        entity: e,
        time: DateTime.now(),
      );
      await FirebaseFirestore.instance.collection(DbConstants.HISTORY).add(history.toFirestore());
    } catch (e) {
      logError("DELETE", e);
    }
  }

  //TASK
  static Future<void> createTask(Task newTask, User user) async {
    try {
      Map<String, String> newFields = _taskFields(newTask);
      final batch = FirebaseFirestore.instance.batch();
      final ref = FirebaseFirestore.instance.collection(DbConstants.HISTORY);
      final idChange = _generateID();

      for (final item in newFields.entries) {
        final history = _instanceHistoryTask(newTask.id, user, item.key, item.value, "", ChangeType.CREATE, idChange);

        final docRef = ref.doc();
        batch.set(docRef, history.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      logError('CREATE TASK HISTORY', e);
    }
  }

  static Map<String, String> _taskFields(Task task) {
    return {
      "name": task.name,
      "description": task.description,
      "priority": task.priority.name,
      "limitDate": DateFormat("dd/MMM/yyyy").format(task.limitDate),
      "openDate": DateFormat("dd/MMM/yyyy").format(task.openDate),
      "completedDate": task.completedDate != null ? DateFormat("dd/MMM/yyyy").format(task.completedDate!) : "null",
      "state": task.state.id,
      _DELETED: "${task.deleted}",
    };
  }

  static History _instanceHistoryTask(
    String taskId,
    User user,
    String field,
    String newValue,
    String oldValue,
    ChangeType ct,
    String idChange,
  ) {
    return History(
      id: "",
      idChange: idChange,
      idEntity: taskId,
      user: user,
      newValue: newValue,
      oldValue: oldValue,
      changeType: ct,
      field: field,
      entity: Entity.TASK,
      time: DateTime.now(),
    );
  }

  static Future<void> updateTask(Task oldTask, Task newTask, User user) async {
    try {
      Map<String, String> oldFields = _taskFields(oldTask);
      Map<String, String> fields = _changedFields(oldFields, _taskFields(newTask));

      final batch = FirebaseFirestore.instance.batch();
      final ref = FirebaseFirestore.instance.collection(DbConstants.HISTORY).doc();
      final idChange = _generateID();

      for (final item in fields.entries) {
        final history = _instanceHistoryTask(
          newTask.id,
          user,
          item.key,
          item.value,
          oldFields[item.key]!,
          ChangeType.UPDATE,
          idChange,
        );

        batch.set(ref, history.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      logError('UPDATE TASK HISTORY', e);
    }
  }

  static Future<void> deleteTask(Task task, User user) async {
    try {
      await _delete(user, task, Entity.TASK);
    } catch (e) {
      logError('DELETE TASK HISTORY', e);
    }
  }

  /*static Map<String, String> _taskChangedFields(Task oldTask, Task newTask) {
    Map<String, String> ret = {};
    Map<String, String> oldT = _taskFields(oldTask);
    Map<String, String> newT = _taskFields(newTask);

    for (var item in newT.entries) {
      if (oldT[item.key] != item.value) {
        ret[item.key] = item.value;
      }
    }
    return ret;
  }
*/

  static Task _mapTask(List<History> list, [List<History>? oldValue]) {
    String name = "", description = "";
    Priorities priority = Priorities.NONE;
    DateTime limitDate = DateTime.now(), openDate = DateTime.now();
    DateTime? completedDate;
    TaskState state = TaskState.empty();
    bool deleted = false;

    final Map<String, void Function(String)> taskFieldSetters = {
      "name": (v) => name = v,
      "description": (v) => description = v,
      "priority": (v) =>
          priority = Priorities.values.firstWhere((p) => p.name.toLowerCase() == v.toString().toLowerCase()),
      "limitDate": (v) => limitDate = DateFormat('dd/MMM/yyyy').parse(v),
      "openDate": (v) => openDate = DateFormat('dd/MMM/yyyy').parse(v),
      "completedDate": (v) => completedDate = (v == "null" ? null : DateFormat('dd/MMM/yyyy').parse(v)),
      "state": (v) => state = TaskState(id: v, color: null, name: '', deleted: false),
      "deleted": (v) => deleted = v == "true",
    };

    if (oldValue != null) {
      for (final h in oldValue) {
        final setter = taskFieldSetters[h.field];
        if (setter != null) setter(h.newValue);
      }
    }

    for (final h in list) {
      final setter = taskFieldSetters[h.field];
      if (setter != null) setter(h.newValue);
    }

    return Task(
      id: list.first.idEntity,
      name: name,
      description: description,
      priority: priority,
      limitDate: limitDate,
      openDate: openDate,
      completedDate: completedDate,
      state: state,
      deleted: deleted,
    );
  }

  //USER
  static Future<void> createUser(User newUser, User creator) async {
    try {
      Map<String, String> fields = _userFields(newUser);
      final batch = FirebaseFirestore.instance.batch();
      final ref = FirebaseFirestore.instance.collection(DbConstants.HISTORY);
      final idChange = _generateID();

      for (final item in fields.entries) {
        final history = _instanceHistoryUser(creator, newUser, item.key, item.value, "", idChange, ChangeType.CREATE);

        final docRef = ref.doc();
        batch.set(docRef, history.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      logError('CREATE USER HISTORY', e);
    }
  }

  static Map<String, String> _userFields(User user) {
    return {
      "name": user.name,
      "surname": user.surname,
      "userName": user.userName,
      "mail": user.mail,
      "password": user.password,
      "userRole": user.userRole.name,
      _DELETED: '${user.deleted}',
      "icon": User.iconMap.entries.firstWhere((line) => line.value == user.icon.icon).key,
    };
  }

  static History _instanceHistoryUser(
    User creator,
    User user,
    String field,
    String newValue,
    String oldValue,
    String idChange,
    ChangeType ct,
  ) {
    return History(
      id: "",
      idChange: idChange,
      idEntity: user.id,
      user: creator,
      newValue: newValue,
      oldValue: oldValue,
      changeType: ct,
      field: field,
      entity: Entity.USER,
      time: DateTime.now(),
    );
  }

  static Future<void> updateUser(User oldUser, User updatedUser, User creator) async {
    try {
      Map<String, String> oldFields = _userFields(oldUser);
      Map<String, String> fields = _changedFields(oldFields, _userFields(updatedUser));

      final batch = FirebaseFirestore.instance.batch();
      final ref = FirebaseFirestore.instance.collection(DbConstants.HISTORY).doc();
      final idChange = _generateID();

      for (final item in fields.entries) {
        final history = _instanceHistoryUser(
          creator,
          updatedUser,
          item.key,
          item.value,
          oldFields[item.key]!,
          idChange,
          ChangeType.UPDATE,
        );
        batch.set(ref, history.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      logError('UPDATE USER HISTORY', e);
    }
  }

  static Future<void> deleteUser(User user, User creator) async {
    try {
      await _delete(creator, user, Entity.USER);
    } catch (e) {
      logError('DELETE USER HISTORY', e);
    }
  }

  static User _mapUser(List<History> list, [List<History>? oldValue]) {
    String name = "", surname = "", userName = "", mail = "", password = "";
    UserRole userRole = UserRole.USER;
    Icon iconName = Icon(User.getRandomIcon());
    bool deleted = false;

    final Map<String, void Function(String)> userFieldSetters = {
      "name": (v) => name = v,
      "surname": (v) => surname = v,
      "userName": (v) => userName = v,
      "mail": (v) => mail = v,
      "password": (v) => password = v,
      "userRole": (v) => userRole = UserRole.values.firstWhere((uR) => uR.name.toLowerCase() == v.toLowerCase()),
      _DELETED: (v) => deleted = (v == "true"),
      "icon": (v) => iconName = Icon(User.iconMap[v] ?? Icons.person),
    };

    if (oldValue != null) {
      for (final h in oldValue) {
        final setter = userFieldSetters[h.field];
        if (setter != null) setter(h.newValue);
      }
    }

    for (final h in list) {
      final setter = userFieldSetters[h.field];
      if (setter != null) setter(h.newValue);
    }

    return User(
      id: list.first.idEntity,
      name: name,
      surname: surname,
      userName: userName,
      mail: mail,
      password: password,
      userRole: userRole,
      iconName: iconName,
      deleted: deleted,
    );
  }

  //TASK STATE
  static Future<void> createTaskState(TaskState newState, User user) async {
    try {
      Map<String, String> fields = _stateFields(newState);
      final batch = FirebaseFirestore.instance.batch();
      final ref = FirebaseFirestore.instance.collection(DbConstants.HISTORY);
      final idChange = _generateID();

      for (final item in fields.entries) {
        final history = _instanceHistoryCreateTaskState(
          newState,
          user,
          item.key,
          item.value,
          "",
          idChange,
          ChangeType.CREATE,
        );

        final docRef = ref.doc();
        batch.set(docRef, history.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      logError('CREATE TASK-STATE HISTORY', e);
    }
  }

  static Map<String, String> _stateFields(TaskState state) {
    return {"name": state.name, "color": TaskState.colorName(state.color)};
  }

  static History _instanceHistoryCreateTaskState(
    TaskState state,
    User user,
    String field,
    String newValue,
    String oldValue,
    String idChange,
    ChangeType changeType,
  ) {
    return History(
      id: "",
      idChange: idChange,
      idEntity: state.id,
      user: user,
      newValue: newValue,
      oldValue: oldValue,
      changeType: changeType,
      field: field,
      entity: Entity.TASKSTATE,
      time: DateTime.now(),
    );
  }

  //TEAM
  static Future<void> createTeam(Team newTeam, User user) async {
    try {
      Map<String, String> fields = _teamFields(newTeam);
      final batch = FirebaseFirestore.instance.batch();
      final ref = FirebaseFirestore.instance.collection(DbConstants.HISTORY);
      final idChange = _generateID();

      for (final item in fields.entries) {
        final history = _instanceHistoryCreateTeam(newTeam, user, item.key, item.value, "", idChange);

        final docRef = ref.doc();
        batch.set(docRef, history.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      logError('CREATE TEAM HISTORY', e);
    }
  }

  static Map<String, String> _teamFields(Team team) {
    return {"name": team.name};
  }

  static History _instanceHistoryCreateTeam(
    Team team,
    User user,
    String field,
    String newValue,
    String oldValue,
    String idChange,
  ) {
    return History(
      id: "",
      idChange: idChange,
      idEntity: team.id,
      user: user,
      newValue: newValue,
      oldValue: oldValue,
      changeType: ChangeType.CREATE,
      field: field,
      entity: Entity.TEAM,
      time: DateTime.now(),
    );
  }

  //NOTIFICATION
  static Future<void> createNotification(Notifications newNot, User user) async {
    try {
      Map<String, String> fields = _notificationFields(newNot);
      final batch = FirebaseFirestore.instance.batch();
      final ref = FirebaseFirestore.instance.collection(DbConstants.HISTORY);
      final idChange = _generateID();

      for (final item in fields.entries) {
        final history = _instanceHistoryCreateNotification(newNot, user, item.key, item.value, "", idChange);

        final docRef = ref.doc();
        batch.set(docRef, history.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      logError('CREATE USER HISTORY', e);
    }
  }

  static Map<String, String> _notificationFields(Notifications not) {
    return {
      DbConstants.TASKID: not.taskId,
      "description": not.description,
      DbConstants.USERID: not.user.id,
      "message": not.message,
    };
  }

  static History _instanceHistoryCreateNotification(
    Notifications not,
    User user,
    String field,
    String newValue,
    String oldValue,
    String idChange,
  ) {
    return History(
      id: "",
      idChange: idChange,
      idEntity: not.id,
      user: user,
      newValue: newValue,
      oldValue: oldValue,
      changeType: ChangeType.CREATE,
      field: field,
      entity: Entity.NONE,
      time: DateTime.now(),
    );
  }
}
