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
  final bool isMBS;
  //final TaskFilter filter;
  //final Function(List<Task>) returnTasks;

  const TaskFilterPage({super.key, required this.tasks, required this.allTasks, required this.isMBS});

  @override
  State<TaskFilterPage> createState() => TaskFilterPageState();
}

class TaskFilterPageState extends State<TaskFilterPage> {
  late List<Task> tasks;
  late List<Task> allTasks;
  List<Task> tasksToShow = [];

  List<bool> priotitySelected = [false, false, false];
  TextEditingController initialLimitDateController = TextEditingController();
  TextEditingController finalLimitDateController = TextEditingController();

  TextEditingController initialOpenDateController = TextEditingController();
  TextEditingController finalOpenDateController = TextEditingController();

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  final DateTime now = DateTime.now();

  TaskState? stateSelected;
  DateTime? selectedInitialLimitDate;
  DateTime? selectedFinalLimitDate;

  DateTime? selectedInitialOpenDate;
  DateTime? selectedFinalOpenDate;

  @override
  void initState() {
    super.initState();
    tasks = widget.tasks;
    allTasks = widget.allTasks;
  }

  @override
  Widget build(BuildContext context) {
    bool isMBS = widget.isMBS;
    bool isPageWide = MediaQuery.of(context).size.width * 0.5 > 500;
    bool isMobile = !(!isMBS && isPageWide);

    return Column(
      //mainAxisAlignment: MainAxisAlignment.center,
      //crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        isMobile
            ? Table(
                columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                children: [
                  _tableRow(
                    'Data límit',
                    Column(children: [limitDateInit(), SizedBox(height: 10), limitDateFin()]),
                  ), //SELECCIONAR 2 DATES (O 1) I MIRAR SI ESTA ENTRE LES DOS (O ABANS O DESPRES SI NOMES HA POSAT 1)

                  _tableRow('Data obertura', Column(children: [openDateInit(), SizedBox(height: 10), openDateFin()])),
                  _tableRow('Estat', state()),
                  _tableRow('Prioritat', priorities()),
                  _tableRow(
                    'Nom',
                    Column(children: [name(), SizedBox(height: 10), description()]),
                  ), //NOMS QUE COMTIMGUIN EL STRING ESCRIT
                  _tableRow('Usuari(s)', Column()), //USUARI SELECCIONAT O USUARIS QUE CONTINGUIN STRING
                  _tableRow('Equip', Column()), //EQUIP SELECCIONAT (S'HA DE FER EQUIPS)
                ],
              )
            : widePage(),
        Row(
          mainAxisAlignment: widget.isMBS ? MainAxisAlignment.start : MainAxisAlignment.end,
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

  TableRow _wideTableRow(String label, Widget options, [Widget? options2]) {
    return TableRow(
      children: [
        //Divider(height: 5, color: Colors.amber,),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), child: options),
        Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), child: options2),
      ],
    );
  }

  Table widePage() {
    return Table(
      columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        _wideTableRow(
          'Data límit',
          limitDateInit(),
          limitDateFin(),
        ), //SELECCIONAR 2 DATES (O 1) I MIRAR SI ESTA ENTRE LES DOS (O ABANS O DESPRES SI NOMES HA POSAT 1)

        _wideTableRow('Data obertura', openDateInit(), openDateFin()),
        _wideTableRow('Estat', state()),
        _wideTableRow('Prioritat', priorities()),
        _wideTableRow('Nom', name(), description()), //NOMS QUE COMTIMGUIN EL STRING ESCRIT
        _wideTableRow('Usuari(s)', Column()), //USUARI SELECCIONAT O USUARIS QUE CONTINGUIN STRING
        _wideTableRow('Equip', Column()), //EQUIP SELECCIONAT (S'HA DE FER EQUIPS)
      ],
    );
  }

  void filter() {
    tasksToShow.clear();
    tasksToShow.addAll(allTasks);
    tasks.clear();
    _dateLimitFilter();
    _nameFilter();
    _stateFilter();
    _priorityFilter();
    _dateOpenFilter();
    _userFilter();
    _teamFilter();

    tasks.addAll(tasksToShow);
  }

  void _dateLimitFilter() {
    if (!(selectedInitialLimitDate == null && selectedFinalLimitDate == null)) {
      if (selectedInitialLimitDate == null && selectedFinalLimitDate != null) {
        tasksToShow = tasksToShow.where((task) => task.limitDate.isBefore(selectedFinalLimitDate!)).toList();
      } else if (selectedInitialLimitDate != null && selectedFinalLimitDate == null) {
        tasksToShow = tasksToShow.where((task) => task.limitDate.isAfter(selectedInitialLimitDate!)).toList();
      } else {
        tasksToShow = tasksToShow.where((task) {
          return task.limitDate.isBefore(selectedFinalLimitDate!) && task.limitDate.isAfter(selectedInitialLimitDate!);
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

  void _dateOpenFilter() {
    if (!(selectedInitialOpenDate == null && selectedFinalOpenDate == null)) {
      if (selectedFinalOpenDate == null && selectedFinalOpenDate != null) {
        tasksToShow = tasksToShow.where((task) => task.openDate.isBefore(selectedFinalOpenDate!)).toList();
      } else if (selectedFinalOpenDate != null && selectedFinalOpenDate == null) {
        tasksToShow = tasksToShow.where((task) => task.openDate.isAfter(selectedFinalOpenDate!)).toList();
      } else {
        tasksToShow = tasksToShow.where((task) {
          return task.openDate.isBefore(selectedFinalOpenDate!) && task.openDate.isAfter(selectedFinalOpenDate!);
        }).toList();
      }
    }
  }

  void _userFilter() {
    logToDo('filtrar', 'TaskFilterPageState(userFilter)');
  }

  void _teamFilter() {
    logToDo('filtrar', 'TaskFilterPageState(teamFilter)');
  }

  ToggleButtons priorities() {
    return ToggleButtons(
      isSelected: priotitySelected,
      onPressed: (int index) {
        setState(() {
          priotitySelected[index] = !priotitySelected[index];
        });
      },
      children: AppStrings.PRIORITIES_STR.map((str) => Text(str)).toList(),
    );
  }

  DropdownMenu state() {
    return DropdownMenu(
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
                  allTasks.firstWhere((task) => task.state.name.trim() == label).state.color ?? Colors.black87,
                ),
              ),
            ),
          )
          .toList(),

      onSelected: (value) => stateSelected = value as TaskState?,
    );
  }

  TextField name() {
    return TextField(
      controller: nameController,
      decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Nom Tasca'),
    );
  }

  TextField description() {
    return TextField(
      controller: descriptionController,
      decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Descripció Tasca'),
    );
  }

  TextFormField limitDateInit() {
    return TextFormField(
      controller: initialLimitDateController,
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
            selectedInitialLimitDate = picked;
            initialLimitDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
      //validator: (value) => (value == null || value.isEmpty) ? 'Siusplau, seleccioneu una data' : null,
    );
  }

  TextFormField limitDateFin() {
    return TextFormField(
      controller: finalLimitDateController,
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
            selectedFinalLimitDate = picked;
            finalLimitDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
      //validator: (value) => (value == null || value.isEmpty) ? 'Siusplau, seleccioneu una data' : null,
    );
  }

  TextFormField openDateInit() {
    return TextFormField(
      controller: initialOpenDateController,
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
            selectedInitialOpenDate = picked;
            initialOpenDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
      //validator: (value) => (value == null || value.isEmpty) ? 'Siusplau, seleccioneu una data' : null,
    );
  }

  TextFormField openDateFin() {
    return TextFormField(
      controller: finalOpenDateController,
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
            selectedFinalOpenDate = picked;
            finalOpenDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
      //validator: (value) => (value == null || value.isEmpty) ? 'Siusplau, seleccioneu una data' : null,
    );
  }
}
