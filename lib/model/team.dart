import 'package:cloud_firestore/cloud_firestore.dart';

class Team implements Comparable<Team> {
  String _id;
  String _name;

  Team.empty() : _id = '', _name = '';

  Team.copy(Team team) : _name = team.name, _id = team.id;

  Team copyWith({String? id, String? name}) {
    return Team(id: id ?? _id, name: name ?? _name);
  }

  Team({required String id, required String name}) : _name = name, _id = id;

  String get name => _name;
  String get id => _id;

  set id(String newId) => _id = newId;

  @override
  String toString() {
    String str = 'Id: $_id \n';
    str += 'Nom: $_name \n';
    return str;
  }

  Map<String, dynamic> toFirestore() {
    return {'name': _name};
  }

  factory Team.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();

    return Team(id: snapshot.id, name: data?['name'] ?? '');
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
