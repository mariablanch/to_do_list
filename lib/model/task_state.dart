import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/interfaces.dart';

class TaskState implements BaseEntity{
  String _id;
  String _name;
  Color? _color;
  bool _deleted;

  TaskState.empty() : _id = '', _name = '', _color = null, _deleted = false;

  TaskState({required String id, required String name, required Color? color, required bool deleted}) : _id = id, _name = name, _color = color, _deleted = deleted;

  TaskState.copy(TaskState state) : _id = state.id, _name = state.name, _color = state.color, _deleted = state.deleted;

  TaskState copyWith({String? id, String? name, Color? color,  bool setColor = false, bool? deleted}) {
    return TaskState(id: id ?? _id, name: name ?? _name, color: setColor ? color : _color, deleted: deleted ?? _deleted);
  }

  @override
  String get id => _id;
  String get name => _name;
  @override
  bool get deleted => _deleted;
  Color? get color => _color;

  set id(String newId) => _id = newId; 

  Map<String, dynamic> toFirestore() {
    return {
      'name': _name,
      'color': colorName(_color),
      //'color': _color == null ? null : colorName(_color),
      DbConstants.DELETED: _deleted,
    };
  }

  factory TaskState.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return TaskState(id: snapshot.id, name: data?['name'] ?? '', color: TaskState.colorValue(data?['color']), deleted: data?[DbConstants.DELETED] ?? false);
  }

  static final Map<String, Color?> colorMap = {
    'null': null,
    'pink': Colors.pink,
    //'red': Colors.red,
    'orange': Colors.orange,
    'amber': Colors.amber,
    'yellow': Colors.yellow,
    'lime': Colors.lime,
    'green': Colors.green,
    'teal': Colors.teal,
    'cyan': Colors.cyan,
    'blue': Colors.blue,
    'indigo': Colors.indigo,
    'purple': Colors.purple,
    'deepPurple': Colors.deepPurple,
    'brown': Colors.brown,
    //'grey': Colors.grey,
  };

  static String colorName(Color? color) {
    if (color == null) {
      return 'null';
    }
    return colorMap.entries.firstWhere((line) => line.value == color).key;
  }

  static Color? colorValue(String colorName) {
    return colorMap[colorName];
  }

  @override
  String toString() {
    String str = 'Id: $_id \n';
    str += 'Nom: $_name \n';
    str += 'Color: $_color \n';
    return str;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskState && other.id == id;
  }
}
