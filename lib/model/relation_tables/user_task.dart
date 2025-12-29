import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/db_constants.dart';

class UserTask {
  //String _task;
  //String _user;
  Task _task;
  User _user;

  UserTask.empty() : _task = Task.empty(), _user  = User.empty();

  UserTask({required Task task, required User user}) : _task = task, _user = user;

  UserTask.copy(UserTask uTask) : _task = uTask.task, _user = uTask.user;

  UserTask copyWith({Task? task, User? user}) {
    return UserTask(task: task ?? _task, user: user ?? _user);
  }

  Task get task => _task;
  User get user => _user;

  Map<String, dynamic> toFirestore() {
    return {DbConstants.USERID: user.id, DbConstants.TASKID: task.id};
  }

  factory UserTask.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return UserTask(task: Task.empty().id = data?[DbConstants.TASKID] ?? '', user: User.empty().id = data?[DbConstants.USERID] ?? '');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserTask && other._task == _task && other._user == _user;
  }

  @override
  int get hashCode => Object.hash(_task, _user);
}
