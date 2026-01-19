import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/model/history.dart';
import 'package:to_do_list/model/notification.dart';
import 'package:to_do_list/model/relation_tables/team_task.dart';
import 'package:to_do_list/model/relation_tables/user_task.dart';
import 'package:to_do_list/model/relation_tables/user_team.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/history_enums.dart';
import 'package:to_do_list/utils/interfaces.dart';
import 'package:to_do_list/utils/priorities.dart';
import 'package:to_do_list/utils/roles.dart';

/// Taules que s'utilitzen més d'un cop a més d'una classe
///
class Tables {
  static TableRow tableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          child: Text(value, style: label.isEmpty ? TextStyle(color: Colors.red) : null),
        ),
      ],
    );
  }

  static Widget viewTasks(Task task, Color colorIverseSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.name, style: TextStyle(color: colorIverseSurface, fontSize: 20)),
        SizedBox(height: 20),
        Table(
          columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          children: [
            tableRow("Descripció:", task.description),
            tableRow("Prioritat:", Priorities.priorityToString(task.priority)),
            tableRow("Data obertura:", DateFormat("dd/MM/yyyy").format(task.openDate)),
            tableRow("Data límit:", DateFormat("dd/MM/yyyy").format(task.limitDate)),
            if (task.completedDate != null)
              tableRow("Data completada:", DateFormat("dd/MM/yyyy").format(task.completedDate!)),
            tableRow("Estat:", task.state.name),
            if (task.deleted) tableRow("", "Tasca eliminada"),
          ],
        ),
      ],
    );
  }

  static Widget viewUsers(User user, bool isviewTeam) {
    return Table(
      columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        tableRow("Nom:", user.name),
        tableRow("Cognom:", user.surname),
        tableRow("Nom d'usuari:", user.userName),
        tableRow("Correu:", user.mail),
        if (isviewTeam) tableRow("Rol:", (UserRole.isAdmin(user.userRole)) ? "Administrador" : "Usuari"),
      ],
    );
  }

  //HISTORY TABLES
  static Widget _historyHeader(String text) {
    return Expanded(
      flex: 1,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  static Container historyHeader(bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.grey.shade300,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _historyHeader("Data"),
              _historyHeader("Nom"),
              _historyHeader("Tipus entitat"),
              if (isWide) ...[_historyHeader("Abans"), _historyHeader("Després")],
            ],
          ),
          if (!isWide)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_historyHeader("Abans"), _historyHeader("Després")],
            ),
        ],
      ),
    );
  }

  static Expanded _cell(String text) {
    return Expanded(flex: 1, child: Text(text, overflow: TextOverflow.ellipsis));
  }

  static Padding historyLine(bool isWide, String nameObj, History h, String oldValue, String newValue) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Tables._cell(DateFormat("dd/MM/yyyy").format(h.time)),
              Tables._cell(nameObj),
              Tables._cell(h.entity.name),
              if (isWide) ...[Tables._cell(oldValue), Tables._cell(newValue)],
            ],
          ),
          if (!isWide)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [Tables._cell(oldValue), Tables._cell(newValue)],
            ),
        ],
      ),
    );
  }

  static TableRow _tableRowHist(String label, String value1, String value2) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: value2.isNotEmpty ? Colors.red.shade900 : null),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
          child: Text(value1, style: value2.isNotEmpty ? TextStyle(color: Colors.red) : null),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
          child: Text(value2, style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  static Table historyTable(Entity e, BaseEntity oldEntity, BaseEntity newEntity) {
    List<TableRow> children = [];

    switch (e) {
      case Entity.TASK:
        if (oldEntity is Task) {
          children = _taskLines(oldEntity, newEntity as Task);
        }
        break;
      case Entity.USER:
        if (oldEntity is User) {
          children = _userLines(oldEntity, newEntity as User);
        }
        break;
      case Entity.TEAM:
        if (oldEntity is Team) {}
        break;
      case Entity.NOTIFICATION:
        if (oldEntity is Notifications) {}
        break;
      case Entity.TASKSTATE:
        if (oldEntity is TaskState) {}
        break;
      case Entity.TEAM_TASK:
        if (oldEntity is TeamTask) {}
        break;
      case Entity.USER_TASK:
        if (oldEntity is UserTask) {}
        break;
      case Entity.USER_TEAM:
        if (oldEntity is UserTeam) {}
      case Entity.NONE:
        return Table();
    }

    return Table(
      columnWidths: {0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth(), 2: IntrinsicColumnWidth()},
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text("Camp", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
              child: Text("Valor actual", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
              child: Text("Valor anterior", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (final line in children) line,
      ],
    );
  }

  static List<TableRow> _taskLines(Task task, Task newTask) {
    return [
      _tableRowHist("Nom", task.name, (task.name == newTask.name) ? "" : newTask.name),
      _tableRowHist(
        "Descripció",
        task.description,
        (task.description == newTask.description) ? "" : newTask.description,
      ),
      _tableRowHist(
        "Prioritat",
        Priorities.priorityToString(task.priority),
        (task.priority == newTask.priority) ? "" : Priorities.priorityToString(newTask.priority),
      ),
      _tableRowHist(
        "Data obertura",
        DateFormat("dd/MM/yyyy").format(task.openDate),
        (task.openDate == newTask.openDate) ? "" : DateFormat("dd/MM/yyyy").format(newTask.openDate),
      ),
      _tableRowHist(
        "Data límit",
        DateFormat("dd/MM/yyyy").format(task.limitDate),
        (task.limitDate == newTask.limitDate) ? "" : DateFormat("dd/MM/yyyy").format(newTask.limitDate),
      ),
      if (task.completedDate != null)
        _tableRowHist(
          "Data completada",
          DateFormat("dd/MM/yyyy").format(task.completedDate!),
          (task.completedDate == newTask.completedDate) ? "" : DateFormat("dd/MM/yyyy").format(newTask.completedDate!),
        ),
      _tableRowHist("Estat", task.state.name, (task.state.id == newTask.state.id) ? "" : newTask.state.name),
      if (task.deleted) _tableRowHist("", "Tasca eliminada", ""),
    ];
  }

  static List<TableRow> _userLines(User user, User newUser) {
    return [
      _tableRowHist("Nom", user.name, (user.name == newUser.name) ? "" : newUser.name),
      _tableRowHist("Cognom", user.surname, (user.surname == newUser.surname) ? "" : newUser.surname),
      _tableRowHist("Nom d'usuari", user.userName, (user.userName == newUser.userName) ? "" : newUser.userName),

      _tableRowHist("Cognom", user.mail, (user.mail == newUser.mail) ? "" : newUser.mail),
      _tableRowHist("Cognom", user.password, (user.password == newUser.password) ? "" : newUser.password),
      _tableRowHist("Cognom", user.userRole.name, (user.userRole == newUser.userRole) ? "" : newUser.userRole.name),

      _tableRowHist(
        "Icona",
        User.iconMap.entries.firstWhere((line) => line.value == user.icon.icon).key,
        (user.userName == newUser.userName)
            ? ""
            : User.iconMap.entries.firstWhere((line) => line.value == newUser.icon.icon).value.toString(),
      ),

      if (user.deleted) _tableRowHist("", "Tasca eliminada", ""),
    ];
  }
}
