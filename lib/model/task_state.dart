import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskState {
  String _id;
  String _name;
  Color? _color;

  TaskState.empty() : _id = '', _name = '', _color = null;

  TaskState({required String id, required String name, required Color? color}) : _id = id, _name = name, _color = color;

  TaskState.copy(TaskState state) : _id = state.id, _name = state.name, _color = state.color;

  TaskState copyWith({String? id, String? name, Color? color,  bool setColor = false}) {
    return TaskState(id: id ?? _id, name: name ?? _name, color: setColor ? color : _color);
  }

  String get id => _id;
  String get name => _name;
  Color? get color => _color;

  set id(String newId) => _id = newId; 

  Map<String, dynamic> toFirestore() {
    return {
      'name': _name,
      'color': colorName(_color)
      //'color': _color == null ? null : colorName(_color),
    };
  }

  factory TaskState.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return TaskState(id: snapshot.id, name: data?['name'] ?? '', color: TaskState.colorValue(data?['color']));
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
}
