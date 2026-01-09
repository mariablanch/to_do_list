import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/priorities.dart';
import 'package:to_do_list/utils/user_role_team.dart';

/// Taules que s'utilitzen més d'un cop a més d'una classe
///
class Tables {
  static TableRow tableRow2(String label, String value) {
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
            tableRow2("Descripció:", task.description),
            tableRow2("Prioritat:", Priorities.priorityToString(task.priority)),
            tableRow2("Data obertura:", DateFormat("dd/MM/yyyy").format(task.openDate)),
            tableRow2("Data límit:", DateFormat("dd/MM/yyyy").format(task.limitDate)),
            if (task.completedDate != null)
              tableRow2("Data completada:", DateFormat("dd/MM/yyyy").format(task.completedDate!)),
            tableRow2("Estat:", task.state.name),
            if (task.deleted) tableRow2("", "Tasca eliminada"),
          ],
        ),
      ],
    );
  }

  static Widget viewUsers(User user, bool isviewTeam) {
    return Table(
      columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        tableRow2("Nom:", user.name),
        tableRow2("Cognom:", user.surname),
        tableRow2("Nom d'usuari:", user.userName),
        tableRow2("Correu:", user.mail),
        if (isviewTeam) tableRow2("Rol:", (UserRole.isAdmin(user.userRole)) ? "Administrador" : "Usuari"),
      ],
    );
  }

  static Expanded header(String text) {
    return Expanded(
      flex: 1,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  static Expanded cell(String text) {
    return Expanded(
      flex: 1,
      child: Text(text, overflow: TextOverflow.ellipsis),
    );
  }
}
