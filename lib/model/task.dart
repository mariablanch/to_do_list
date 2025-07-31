import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/utils/priorities.dart';
import 'package:to_do_list/utils/sort.dart';

class Task implements Comparable<Task> {
  String id;
  String name;
  String description;
  Priorities priority;
  DateTime limitDate;
  bool completed;

  Task.empty()
    : this.id = '',
      this.name = '',
      this.description = '',
      this.priority = Priorities.NONE,
      this.limitDate = DateTime.now(),
      this.completed = false;

  Task.copy(Task task)
    : this.name = task.name,
      this.description = task.description,
      this.priority = task.priority,
      this.limitDate = task.limitDate,
      this.completed = task.completed,
      this.id = task.id;

  Task copyWith({
    String? id,
    String? name,
    String? description,
    Priorities? priority,
    DateTime? limitDate,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      limitDate: limitDate ?? this.limitDate,
      completed: completed ?? this.completed,
    );
  }

  Task({
    required String id,
    required String name,
    required String description,
    required Priorities priority,
    required DateTime limitDate,
    required bool completed,
  }) : this.name = name,
       this.description = description,
       this.priority = priority,
       this.limitDate = limitDate,
       this.completed = completed,
       this.id = id;

  String getName() => this.name;
  String getDescription() => this.description;
  Priorities getPriority() => this.priority;
  DateTime getLimitDate() => this.limitDate;
  bool isCompleted() => this.completed;
  String getId() => this.id;

  @override
  String toString() {
    String dateformat = DateFormat('dd/MM/yyyy').format(limitDate);

    String str = 'Id: $id \n';
    str += 'Nom: $name \n';
    str += 'Descripció: $description \n';
    str += 'Prioritat: $priority \n';
    str += 'Data límit: $dateformat \n';
    completed ? str += 'Completada' : str += 'Pendent';
    return str;
  }

  Map<String, dynamic> toFirestore() {
    return {
      //'id': id,
      'name': name,
      'description': description,
      'priority': priority.name,
      'limitDate': Timestamp.fromDate(limitDate),
      'completed': completed,
    };
  }

  factory Task.fromFirestore(DocumentSnapshot doc, _) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      priority: Priorities.values.firstWhere(
        (p) =>
            p.name.toLowerCase() ==
            (data['priority'] ?? '').toString().toLowerCase(),
      ),
      limitDate: (data['limitDate'] as Timestamp).toDate(),
      completed: data['completed'] ?? false,
    );
  }

  @override
  int compareTo(Task task) {
    int comp = this.priority.index.compareTo(task.priority.index);
    if (comp == 0) comp = this.name.compareTo(task.name);
    return comp;
  }

  static int sortTask(SortType type, Task task1, Task task2) {
    switch (type) {
      case SortType.NONE:
        return task1.compareTo(task2);
      case SortType.DATE:
        return task1.limitDate.compareTo(task2.limitDate);
      case SortType.NAME:
        return task1.name.compareTo(task2.name);
    }
  }
}
