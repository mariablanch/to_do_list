import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/utils/priorities.dart';

class Task implements Comparable<Task> {
  String _id;
  String _name;
  String _description;
  Priorities _priority;
  DateTime _limitDate;
  bool _completed;

  Task.empty()
    : this._id = '',
      this._name = '',
      this._description = '',
      this._priority = Priorities.NONE,
      this._limitDate = DateTime.now(),
      this._completed = false;

  Task.copy(Task task)
    : this._name = task.name,
      this._description = task.description,
      this._priority = task.priority,
      this._limitDate = task.limitDate,
      this._completed = task.isCompleted,
      this._id = task.id;

  Task copyWith({
    String? id,
    String? name,
    String? description,
    Priorities? priority,
    DateTime? limitDate,
    bool? completed,
  }) {
    return Task(
      id: id ?? this._id,
      name: name ?? this._name,
      description: description ?? this._description,
      priority: priority ?? this._priority,
      limitDate: limitDate ?? this._limitDate,
      completed: completed ?? this._completed,
    );
  }

  Task({
    required String id,
    required String name,
    required String description,
    required Priorities priority,
    required DateTime limitDate,
    required bool completed,
  }) : this._name = name,
       this._description = description,
       this._priority = priority,
       this._limitDate = limitDate,
       this._completed = completed,
       this._id = id;

  String get name => this._name;
  String get description => this._description;
  Priorities get priority => this._priority;
  DateTime get limitDate => this._limitDate;
  bool get isCompleted => this._completed;
  String get id => this._id;

  set id(String newId) => _id = newId;

  @override
  String toString() {
    String dateformat = DateFormat('dd/MM/yyyy').format(_limitDate);

    String str = 'Id: $_id \n';
    str += 'Nom: $_name \n';
    str += 'Descripció: $_description \n';
    str += 'Prioritat: $_priority \n';
    str += 'Data límit: $dateformat \n';
    _completed ? str += 'Completada' : str += 'Pendent';
    return str;
  }

  Map<String, dynamic> toFirestore() {
    return {
      //'id': id,
      'name': _name,
      'description': _description,
      'priority': _priority.name,
      'limitDate': Timestamp.fromDate(_limitDate),
      'completed': _completed,
    };
  }

  factory Task.fromFirestore(DocumentSnapshot doc, _) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      priority: Priorities.values.firstWhere(
        (p) => p.name.toLowerCase() == (data['priority'] ?? '').toString().toLowerCase(),
      ),
      limitDate: (data['limitDate'] as Timestamp).toDate(),
      completed: data['completed'] ?? false,
    );
  }

  @override
  int compareTo(Task task) {
    int comp = this._priority.index.compareTo(task._priority.index);
    if (comp == 0) comp = this._name.compareTo(task._name);
    return comp;
  }
}
