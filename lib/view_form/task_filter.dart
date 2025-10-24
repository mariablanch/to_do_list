import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/priorities.dart';

class TaskFilterPage extends StatefulWidget {
  final List<Task> tasks;
  final List<Task> allTasks;
  //final TaskFilter filter;
  //final Function(List<Task>) returnTasks;

  const TaskFilterPage({super.key, required this.tasks, required this.allTasks});

  State<TaskFilterPage> createState() => TaskFilterPageState();
}

class TaskFilterPageState extends State<TaskFilterPage> {
  late List<Task> tasks;
  late List<Task> allTasks;
  List<Task> tasksToShow = [];

  List<bool> priotitySelected = [false, false, false];
  TextEditingController initialDateController = TextEditingController();
  TextEditingController finalDateController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  final DateTime now = DateTime.now();

  TaskState? stateSelected;
  DateTime? selectedInitialDate;
  DateTime? selectedFinalDate;

  @override
  void initState() {
    super.initState();
    tasks = widget.tasks;
    allTasks = widget.allTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      //mainAxisAlignment: MainAxisAlignment.center,
      //crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Table(
          columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          children: [
            _tableRow(
              'Data',
              Column(
                children: [
                  TextFormField(
                    controller: initialDateController,
                    decoration: InputDecoration(labelText: 'Data Inicial', border: OutlineInputBorder()),
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(now.year, now.month - 3),
                        lastDate: DateTime(now.year + 50),
                        locale: const Locale('es', 'ES'),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedInitialDate = picked;
                          initialDateController.text = DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                    //validator: (value) => (value == null || value.isEmpty) ? 'Siusplau, seleccioneu una data' : null,
                  ),

                  SizedBox(height: 10),

                  TextFormField(
                    controller: finalDateController,
                    decoration: InputDecoration(labelText: 'Data final', border: OutlineInputBorder()),
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(now.year, now.month - 3),
                        lastDate: DateTime(now.year + 50),
                        locale: const Locale('es', 'ES'),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedFinalDate = picked;
                          finalDateController.text = DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                    //validator: (value) => (value == null || value.isEmpty) ? 'Siusplau, seleccioneu una data' : null,
                  ),
                ],
              ),
            ), //SELECCIONAR 2 DATES (O 1) I MIRAR SI ESTA ENTRE LES DOS (O ABANS O DESPRES SI NOMES HA POSAT 1)
            _tableRow(
              'Estat',
              DropdownMenu(
                initialSelection: 'Estat de la tasca',
                menuHeight: 140,
                //dropdownMenuEntries: tasks.map((line) => DropdownMenuEntry(value: line, label: line.state.name.trim())).toSet().toList(),
                dropdownMenuEntries: allTasks
                    .map((t) => t.state.name.trim())
                    .toSet()
                    .map(
                      (label) => DropdownMenuEntry(
                        value: allTasks.firstWhere((task) => task.state.name.trim() == label).state,
                        label: label,
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(
                            allTasks.firstWhere((task) => task.state.name.trim() == label).state.color ??
                                Colors.black87,
                          ),
                        ),
                      ),
                    )
                    .toList(),

                onSelected: (value) => stateSelected = value as TaskState?,
              ),
            ),
            _tableRow(
              'Prioritat',
              ToggleButtons(
                isSelected: priotitySelected,
                onPressed: (int index) {
                  setState(() {
                    priotitySelected[index] = !priotitySelected[index];
                  });
                },
                children: AppStrings.PRIORITIES_STR.map((str) => Text(str)).toList(),
              ),
            ),
            _tableRow(
              'Nom',
              Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Nom Tasca'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Descripció Tasca'),
                  ),
                ],
              ),
            ), //NOMS QUE COMTIMGUIN EL STRING ESCRIT
            _tableRow('Usuari(s)', Column()), //USUARI SELECCIONAT O USUARIS QUE CONTINGUIN STRING
            _tableRow('Equip', Column()), //EQUIP SELECCIONAT (S'HA DE FER EQUIPS)
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                filter();
                Navigator.of(context).pop(tasks);
              },
              child: Text(AppStrings.CONFIRM),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppStrings.CANCEL),
            ),
          ],
        ),
      ],
    );
  }

  TableRow _tableRow(String label, Widget options) {
    return TableRow(
      children: [
        //Divider(height: 5, color: Colors.amber,),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), child: options),
      ],
    );
  }

  /*void filterTask() {
    switch () {
      case TaskFilter.DATE:
        _dateFilter();
        break;
      case TaskFilter.NAME:
        _nameFilter();
        break;
      case TaskFilter.STATE:
        _stateFilter();
        break;
      case TaskFilter.PRIORITY:
        _priorityFilter();
        break;
      case TaskFilter.USER:
        _userFilter();
        break;
      case TaskFilter.TEAM:
        _teamFilter();
        break;
    }
  }*/

  void filter() {
    tasksToShow.clear();
    tasksToShow.addAll(allTasks);
    tasks.clear();
    _dateFilter();
    _nameFilter();
    _stateFilter();
    _priorityFilter();
    _userFilter();
    _teamFilter();

    tasks.addAll(tasksToShow);
  }

  void _dateFilter() {
    if (!(selectedInitialDate == null && selectedFinalDate == null)) {
      if (selectedInitialDate == null && selectedFinalDate != null) {
        tasksToShow = tasksToShow.where((task) => task.limitDate.isBefore(selectedFinalDate!)).toList();
      } else if (selectedInitialDate != null && selectedFinalDate == null) {
        tasksToShow = tasksToShow.where((task) => task.limitDate.isAfter(selectedInitialDate!)).toList();
      } else {
        tasksToShow = tasksToShow.where((task) {
          return task.limitDate.isBefore(selectedFinalDate!) && task.limitDate.isAfter(selectedInitialDate!);
        }).toList();
      }
    }
    //logToDo('filtrar', 'TaskFilterPageState(dateFilter)');
  }

  void _nameFilter() {
    if (!(nameController.text == '' && descriptionController.text == '')) {
      if (nameController.text == '' && descriptionController.text != '') {
        tasksToShow = tasksToShow
            .where((task) => task.description.toLowerCase().contains(descriptionController.text.toLowerCase()))
            .toList();
      } else if (nameController.text != '' && descriptionController.text == '') {
        tasksToShow = tasksToShow
            .where((task) => task.name.toLowerCase().contains(nameController.text.toLowerCase()))
            .toList();
      } else {
        tasksToShow = tasksToShow.where((task) {
          return task.description.toLowerCase().contains(descriptionController.text.toLowerCase()) &&
              task.name.toLowerCase().contains(nameController.text.toLowerCase());
        }).toList();
      }
    }
    //logToDo('filtrar', 'TaskFilterPageState(nameFilter)');
  }

  void _stateFilter() {
    if (stateSelected != null) {
      tasksToShow = tasksToShow.where((line) {
        return line.state.id == stateSelected!.id;
      }).toList();
    }
    //logToDo('filtrar', 'TaskFilterPageState(stateFilter)');
  }

  void _priorityFilter() {
    List<Priorities> pSelected = [];
    if (priotitySelected.contains(true)) {
      int pos = 0;
      for (bool isSelected in priotitySelected) {
        if (isSelected) {
          //AppStrings.PRIORITIES_STR[pos]
          pSelected.add(Priorities.priorityFromString(AppStrings.PRIORITIES_STR[pos]));
        }
        pos++;
      }

      tasksToShow = tasksToShow.where((line) {
        return pSelected.contains(line.priority);
      }).toList();
    }

    //logToDo('filtrar', 'TaskFilterPageState(priorityFilter)');
  }

  void _userFilter() {
    logToDo('filtrar', 'TaskFilterPageState(userFilter)');
  }

  void _teamFilter() {
    logToDo('filtrar', 'TaskFilterPageState(teamFilter)');
  }
}
