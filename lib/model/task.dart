// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/priorities.dart';
import 'package:to_do_list/model/task_state.dart';

class Task implements Comparable<Task> {
  String _id;
  String _name;
  String _description;
  Priorities _priority;
  DateTime _limitDate;
  DateTime _openDate;
  DateTime? _completedDate;
  TaskState _state;
  bool _deleted;
  //static final Entity _entity = Entity.TASK;

  Task.empty()
    : _id = '',
      _name = '',
      _description = '',
      _priority = Priorities.NONE,
      _limitDate = DateTime.now(),
      _openDate = DateTime.now(),
      _completedDate = null,
      _state = TaskState.empty(),
      _deleted = false;

  Task.copy(Task task)
    : _name = task.name,
      _description = task.description,
      _priority = task.priority,
      _limitDate = task.limitDate,
      _openDate = task.openDate,
      _completedDate = task.completedDate,
      _state = TaskState.copy(task.state),
      _id = task.id,
      _deleted = task.deleted;

  Task copyWith({
    String? id,
    String? name,
    String? description,
    Priorities? priority,
    DateTime? limitDate,
    DateTime? openDate,
    DateTime? completedDate,
    TaskState? state,
    bool? deleted,
  }) {
    return Task(
      id: id ?? _id,
      name: name ?? _name,
      description: description ?? _description,
      priority: priority ?? _priority,
      limitDate: limitDate ?? _limitDate,
      openDate: openDate ?? _openDate,
      completedDate: completedDate,
      state: state ?? _state,
      deleted: deleted ?? _deleted,
    );
  }

  Task({
    required String id,
    required String name,
    required String description,
    required Priorities priority,
    required DateTime limitDate,
    required DateTime openDate,
    required DateTime? completedDate,
    required TaskState state,
    required bool deleted,
  }) : _name = name,
       _description = description,
       _priority = priority,
       _limitDate = limitDate,
       _openDate = openDate,
       _completedDate = completedDate,
       _state = TaskState.copy(state),
       _id = id,
       _deleted = deleted;

  String get name => _name;
  String get description => _description;
  Priorities get priority => _priority;
  DateTime get limitDate => _limitDate;
  DateTime get openDate => _openDate;
  DateTime? get completedDate => _completedDate;
  TaskState get state => _state;
  String get id => _id;
  bool get deleted => _deleted;

  set id(String newId) => _id = newId;
  set state(TaskState newState) => _state = newState;

  @override
  String toString() {
    String limitDateF = DateFormat('dd/MM/yyyy').format(_limitDate);
    String openDateF = DateFormat('dd/MM/yyyy').format(_openDate);
    String completedDateF = _completedDate != null ? DateFormat('dd/MM/yyyy').format(_completedDate!) : "NO COMPLETADA";

    String str = 'Id: $_id \n';
    str += 'Nom: $_name \n';
    str += 'Descripció: $_description \n';
    str += 'Prioritat: $_priority \n';
    str += 'Data límit: $limitDateF \n';
    str += 'Data completada: $completedDateF \n';
    str += 'Data obertura: $openDateF \n';
    str += 'Estat: ${_state.name} \n';
    str += 'Eliminada: $deleted \n ';
    return str;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': _name,
      'description': _description,
      'priority': _priority.name,
      DbConstants.LIMIT_DATE: Timestamp.fromDate(_limitDate),
      DbConstants.OPEN_DATE: Timestamp.fromDate(_openDate),
      DbConstants.COMPLETED_DATE: _completedDate != null ? Timestamp.fromDate(_completedDate!) : null,
      DbConstants.STATE: _state.id,
      DbConstants.DELETED: deleted,
    };
  }

  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();

    return Task(
      id: snapshot.id,
      name: data?['name'] ?? '',
      description: data?['description'] ?? '',
      priority: Priorities.values.firstWhere(
        (p) => p.name.toLowerCase() == (data?['priority'] ?? '').toString().toLowerCase(),
      ),
      limitDate: (data?[DbConstants.LIMIT_DATE] as Timestamp).toDate(),
      completedDate: data?[DbConstants.COMPLETED_DATE] != null
          ? (data?[DbConstants.COMPLETED_DATE] as Timestamp).toDate()
          : null,
      openDate: (data?[DbConstants.OPEN_DATE] as Timestamp).toDate(),
      state: TaskState(id: data?['state'] ?? '', color: null, name: ''),
      deleted: data?[DbConstants.DELETED] ?? false,
    );
  }

  @override
  int compareTo(Task task) {
    int comp = _priority.index.compareTo(task._priority.index);
    if (comp == 0) comp = _name.compareTo(task._name);
    return comp;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }
}
