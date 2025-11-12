import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/utils/const/db_constants.dart';

class UserTask {
  String _taskId;
  String _userName;

  UserTask.empty() : _taskId = '', _userName = '';

  UserTask({required String taskId, required String userName}) : _taskId = taskId, _userName = userName;

  UserTask.copy(UserTask uTask) : _taskId = uTask.taskId, _userName = uTask.userName;

  UserTask copyWith({String? taskId, String? userName}) {
    return UserTask(taskId: taskId ?? _taskId, userName: userName ?? _userName);
  }

  String get taskId => _taskId;
  String get userName => _userName;

  Map<String, dynamic> toFirestore() {
    return {DbConstants.USERNAME: userName, DbConstants.TASKID: taskId};
  }

  factory UserTask.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return UserTask(taskId: data?[DbConstants.TASKID] ?? '', userName: data?[DbConstants.USERNAME] ?? '');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserTask && other._taskId == _taskId && other._userName == _userName;
  }

  @override
  int get hashCode => Object.hash(_taskId, _userName);
}
