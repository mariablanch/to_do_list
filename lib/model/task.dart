import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/utils/priorities.dart';
import 'package:to_do_list/utils/task_state.dart';

class Task implements Comparable<Task> {
  String _id;
  String _name;
  String _description;
  Priorities _priority;
  DateTime _limitDate;
  //bool _completed;
  TaskState _state;

  Task.empty()
    : _id = '',
      _name = '',
      _description = '',
      _priority = Priorities.NONE,
      _limitDate = DateTime.now(),
      _state = TaskState.PENDING;

  Task.copy(Task task)
    : _name = task.name,
      _description = task.description,
      _priority = task.priority,
      _limitDate = task.limitDate,
      //this._completed = task.isCompleted,
      _state = task.state,
      _id = task.id;

  Task copyWith({
    String? id,
    String? name,
    String? description,
    Priorities? priority,
    DateTime? limitDate,
    TaskState? state,
  }) {
    return Task(
      id: id ?? _id,
      name: name ?? _name,
      description: description ?? _description,
      priority: priority ?? _priority,
      limitDate: limitDate ?? _limitDate,
      //completed: completed ?? this._completed,
      state: state ?? _state,
    );
  }

  Task({
    required String id,
    required String name,
    required String description,
    required Priorities priority,
    required DateTime limitDate,
    required TaskState state,
  }) : _name = name,
       _description = description,
       _priority = priority,
       _limitDate = limitDate,
       _state = state,
       _id = id;

  String get name => _name;
  String get description => _description;
  Priorities get priority => _priority;
  DateTime get limitDate => _limitDate;
  TaskState get state => _state;
  String get id => _id;

  set id(String newId) => _id = newId;

  @override
  String toString() {
    String dateformat = DateFormat('dd/MM/yyyy').format(_limitDate);

    String str = 'Id: $_id \n';
    str += 'Nom: $_name \n';
    str += 'Descripció: $_description \n';
    str += 'Prioritat: $_priority \n';
    str += 'Data límit: $dateformat \n';
    str += 'Estat: $_state';
    return str;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': _name,
      'description': _description,
      'priority': _priority.name,
      'limitDate': Timestamp.fromDate(_limitDate),
      'state': _state.name,
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
      state: TaskState.values.firstWhere(
        (st) => st.name.toLowerCase() == (data['state'] ?? '').toString().toLowerCase(),
      ),
    );
  }

  @override
  int compareTo(Task task) {
    int comp = _priority.index.compareTo(task._priority.index);
    if (comp == 0) comp = _name.compareTo(task._name);
    return comp;
  }
}
