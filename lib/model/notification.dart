import 'package:cloud_firestore/cloud_firestore.dart';

class Notifications implements Comparable<Notifications>{
  String _id;
  String _taskID;
  String _name;
  String _userName;
  String _description;

  Notifications.empty()
    : this._id = '',
      this._taskID = '',
      this._name = '',
      this._userName = '',
      this._description = '';

  Notifications.coppy(Notifications not)
    : this._id = not.id,
      this._taskID = not.taskID,
      this._name = not.name,
      this._userName = not.userName,
      this._description = not.description;

  Notifications copyWith({
    String? id,
    String? taskID,
    String? name,
    String? userName,
    String? description,
  }) {
    return Notifications(
      id: id ?? this._id,
      taskID: taskID ?? this._taskID,
      name: name ?? this._name,
      userName: userName ?? this._userName,
      description: description ?? this._description,
    );
  }

  String get id => this._id;
  String get taskID => this._taskID;
  String get name => this._name;
  String get userName => this._userName;
  String get description => this._description;

  Notifications({
    required String id,
    required String taskID,
    required String name,
    required String userName,
    required String description,
  }) : this._id = id,
       this._taskID = taskID,
       this._name = name,
       this._userName = userName,
       this._description = description;

  Map<String, dynamic> toFirestore() {
    return {
      //'id': id,
      'taskID': _taskID,
      'name': _name,
      'userName': _userName,
      'description': _description,
    };
  }

  factory Notifications.fromFirestore(DocumentSnapshot doc, _) {
    final data = doc.data() as Map<String, dynamic>;
    return Notifications(
      id: doc.id,
      taskID: data['taskID'] ?? '',
      name: data['name'] ?? '',
      userName: data['userName'] ?? '',
      description: data['description'] ?? '',
    );
  }
  
  @override
  int compareTo(Notifications not) {
    return this.description.compareTo(not.description);
  }
}
