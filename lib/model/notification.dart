import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/utils/const/db_constants.dart';

class Notifications implements Comparable<Notifications> {
  String _id;
  String _taskId;
  String _description;
  String _userName;
  String _message;

  Notifications.empty()
    : this._id = '',
      this._taskId = '',
      this._description = '',
      this._userName = '',
      this._message = '';

  Notifications.coppy(Notifications not)
    : this._id = not.id,
      this._taskId = not.taskId,
      this._description = not.description,
      this._userName = not.userName,
      this._message = not.message;

  Notifications copyWith({String? id, String? taskId, String? description, String? userName, String? message}) {
    return Notifications(
      id: id ?? this._id,
      taskId: taskId ?? this._taskId,
      description: description ?? this._description,
      userName: userName ?? this._userName,
      message: message ?? this._message,
    );
  }

  String get id => this._id;
  String get taskId => this._taskId;
  String get description => this._description;
  String get userName => this._userName;
  String get message => this._message;

  Notifications({
    required String id,
    required String taskId,
    required String description,
    required String userName,
    required String message,
  }) : this._id = id,
       this._taskId = taskId,
       this._description = description,
       this._userName = userName,
       this._message = message;

  Map<String, dynamic> toFirestore() {
    return {
      DbConstants.TASKID: _taskId,
      'description': _description,
      DbConstants.USERNAME: _userName,
      'message': _message,
    };
  }

  factory Notifications.fromFirestore(DocumentSnapshot doc, _) {
    final data = doc.data() as Map<String, dynamic>;
    return Notifications(
      id: doc.id,
      taskId: data[DbConstants.TASKID] ?? '',
      description: data['description'] ?? '',
      userName: data[DbConstants.USERNAME] ?? '',
      message: data['message'] ?? '',
    );
  }

  @override
  int compareTo(Notifications not) {
    return this.message.compareTo(not.message);
  }
}
