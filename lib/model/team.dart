import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/interfaces.dart';

class Team implements Comparable<Team>, BaseEntity {
  String _id;
  String _name;
  bool _deleted;

  Team.empty() : _id = '', _name = '', _deleted = false;

  Team.copy(Team team) : _name = team.name, _id = team.id, _deleted = team.deleted;

  Team copyWith({String? id, String? name, bool? deleted}) {
    return Team(id: id ?? _id, name: name ?? _name, deleted: deleted ?? _deleted);
  }

  Team({required String id, required String name, required bool deleted}) : _name = name, _id = id, _deleted = deleted;

  String get name => _name;
  @override
  String get id => _id;
  @override
  bool get deleted => _deleted;

  set id(String newId) => _id = newId;

  @override
  String toString() {
    String str = 'Id: $_id \n';
    str += 'Nom: $_name \n';
    return str;
  }

  Map<String, dynamic> toFirestore() {
    return {'name': _name, DbConstants.DELETED: _deleted};
  }

  factory Team.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();

    return Team(id: snapshot.id, name: data?['name'] ?? '', deleted: data?[DbConstants.DELETED] ?? false);
  }

  @override
  int compareTo(Team other) {
    return name.compareTo(other.name);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team && other.id == id;
  }
}
