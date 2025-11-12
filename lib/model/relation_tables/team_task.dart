import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/utils/const/db_constants.dart';

class TeamTask implements Comparable<TeamTask> {
  Team _team;
  Task _task;

  TeamTask.empty() : _team = Team.empty(), _task = Task.empty();

  TeamTask({required Team team, required Task task}) : _team = team, _task = task;

  TeamTask.copy(TeamTask uTeam) : _team = uTeam.team, _task = uTeam.task;

  TeamTask copyWith({Team? team, Task? task}) {
    return TeamTask(team: team ?? _team, task: task ?? _task);
  }

  Team get team => _team;
  Task get task => _task;

  Map<String, dynamic> toFirestore() {
    return {DbConstants.TASKID: task.id, DbConstants.TEAMID: team.id};
  }

  factory TeamTask.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    Team team = Team.empty().copyWith(id: data?[DbConstants.TEAMID] ?? '');
    Task task = Task.empty().copyWith(id: data?[DbConstants.TASKID] ?? '');
    return TeamTask(team: team, task: task);
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
