import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/interfaces.dart';

class UserTask implements BaseEntity {
  String _id;
  Task _task;
  User _user;
  bool _deleted;

  UserTask.empty() : _task = Task.empty(), _user = User.empty(), _id = "", _deleted = false;

  UserTask({required Task task, required User user, required String id, required bool deleted})
    : _task = task,
      _user = user,
      _deleted = deleted,
      _id = id;

  UserTask.copy(UserTask uTask) : _task = uTask.task, _user = uTask.user, _deleted = uTask.deleted, _id = uTask.id;

  UserTask copyWith({Task? task, User? user, bool? deleted, String? id}) {
    return UserTask(task: task ?? _task, user: user ?? _user, id: id ?? _id, deleted: deleted ?? _deleted);
  }

  Task get task => _task;
  User get user => _user;
  @override
  bool get deleted => _deleted;
  @override
  String get id => _id;

  Map<String, dynamic> toFirestore() {
    return {DbConstants.USERID: user.id, DbConstants.TASKID: task.id, DbConstants.DELETED: deleted};
  }

  factory UserTask.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return UserTask(
      task: Task.empty().id = data?[DbConstants.TASKID] ?? '',
      user: User.empty().id = data?[DbConstants.USERID] ?? '',
      deleted: data?[DbConstants.DELETED] ?? false,
      id: snapshot.id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserTask && other._task == _task && other._user == _user;
  }

  @override
  int get hashCode => Object.hash(_task, _user);
}
