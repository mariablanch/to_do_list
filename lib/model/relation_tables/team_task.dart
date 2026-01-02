import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/interfaces.dart';

class TeamTask implements Comparable<TeamTask>, BaseEntity {
  String _id;
  Team _team;
  Task _task;
  bool _deleted;

  TeamTask.empty() : _team = Team.empty(), _task = Task.empty(), _id = "", _deleted = false;

  TeamTask({required Team team, required Task task, required String id, required bool deleted})
    : _team = team,
      _task = task,
      _deleted = deleted,
      _id = id;

  TeamTask.copy(TeamTask tTask) : _team = tTask.team, _task = tTask.task, _deleted = tTask.deleted, _id = tTask.id;

  TeamTask copyWith({Team? team, Task? task, bool? deleted, String? id}) {
    return TeamTask(team: team ?? _team, task: task ?? _task, id: id ?? _id, deleted: deleted ?? _deleted);
  }

  Team get team => _team;
  Task get task => _task;
  @override
  bool get deleted => _deleted;
  @override
  String get id => _id;

  Map<String, dynamic> toFirestore() {
    return {DbConstants.TASKID: task.id, DbConstants.TEAMID: team.id, DbConstants.DELETED: deleted};
  }

  factory TeamTask.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    Team team = Team.empty().copyWith(id: data?[DbConstants.TEAMID] ?? '');
    Task task = Task.empty().copyWith(id: data?[DbConstants.TASKID] ?? '');
    return TeamTask(team: team, task: task, deleted: data?[DbConstants.DELETED] ?? false, id: snapshot.id);
  }

  @override
  int compareTo(TeamTask ut) {
    int comp = 0;
    if (comp == 0) {
      comp = task.compareTo(ut.task);
    }
    return comp;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamTask && other.team.id == team.id && other.task.id == task.id;
  }

  @override
  int get hashCode => Object.hash(team.id, task.id);
}
