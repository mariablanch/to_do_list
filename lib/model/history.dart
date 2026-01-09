import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/history_enums.dart';

class History implements Comparable<History> {
  String id;
  String idChange;
  String idEntity;
  User user;
  String newValue;
  String oldValue;
  ChangeType changeType;
  String field;
  Entity entity;
  DateTime time;

  History.empty()
    : this.id = "",
      this.idChange = "",
      this.idEntity = "",
      this.user = User.empty(),
      this.newValue = "",
      this.oldValue = "",
      this.changeType = ChangeType.NONE,
      this.field = "",
      this.entity = Entity.NONE,
      this.time = DateTime.now();

  History({
    required this.id,
    required this.idChange,
    required this.idEntity,
    required this.user,
    required this.newValue,
    required this.oldValue,
    required this.changeType,
    required this.field,
    required this.entity,
    required this.time,
  });

  History.copy(History history)
    : this.id = history.id,
      this.idChange = history.idChange,
      this.idEntity = history.idEntity,
      this.user = history.user,
      this.newValue = history.newValue,
      this.oldValue = history.oldValue,
      this.changeType = history.changeType,
      this.field = history.field,
      this.entity = history.entity,
      this.time = history.time;

  History copyWith({
    String? id,
    String? idChange,
    String? idEntity,
    User? user,
    String? newValue,
    String? oldValue,
    ChangeType? changeType,
    String? field,
    Entity? entity,
    DateTime? time,
  }) {
    return History(
      id: id ?? this.id,
      idChange: idChange ?? this.idChange,
      idEntity: idEntity ?? this.idEntity,
      user: user ?? this.user,
      newValue: newValue ?? this.newValue,
      oldValue: oldValue ?? this.oldValue,
      changeType: changeType ?? this.changeType,
      field: field ?? this.field,
      entity: entity ?? this.entity,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "idEntity": idEntity,
      "idChange": idChange,
      "user": user.id,
      "newValue": newValue,
      "oldValue": oldValue,
      "changeType": changeType.name,
      "field": field,
      "entity": entity.name,
      "time": Timestamp.fromDate(time),
    };
  }

  factory History.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return History(
      id: snapshot.id,
      idChange: data?["idChange"] ?? '',
      idEntity: data?["idEntity"] ?? '',
      user: User.empty().copyWith(id: data?["user"] ?? ''),
      newValue: data?["newValue"] ?? '',
      oldValue: data?["oldValue"] ?? '',
      changeType: ChangeType.values.firstWhere(
        (c) => c.name.toLowerCase() == (data?["changeType"] ?? '').toString().toLowerCase(),
      ),
      field: data?["field"] ?? '',
      entity: Entity.values.firstWhere((e) => e.name.toLowerCase() == (data?["entity"] ?? '').toString().toLowerCase()),
      time: (data?["time"] as Timestamp).toDate(),
    );
  }

  @override
  int compareTo(History h) {
    int ret = -this.time.compareTo(h.time);
    if (ret == 0) {
      ret = this.changeType.index - h.changeType.index;
      if (ret == 0) {
        ret = this.entity.index - h.entity.index;
      }
    }
    return ret;
  }

  @override
  String toString() {
    String str = "History{id: $id,\n";
    str += "idChange: $idChange,\n";
    str += "idEntity: $idEntity,\n";
    str += "user: ${user.userName},\n";
    str += "newValue: $newValue,\n";
    str += "oldValue: $oldValue,\n";
    str += "changeType: ${changeType.name},\n";
    str += "field: $field,\n";
    str += "entity: ${entity.name}}";
    return str;
  }
}
