import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/model/relation_tables/team_task.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/priorities.dart';

class TaskFilterPage extends StatefulWidget {
  final List<Task> tasks;
  final List<Task> allTasks;
  final bool isMBS;
  final Map<String, String> taskAndUsersMAP;
  final List<String> allUserNames;
  final List<TeamTask> teamTask;

  const TaskFilterPage({
    super.key,
    required this.tasks,
    required this.allTasks,
    required this.isMBS,
    required this.taskAndUsersMAP,
    required this.allUserNames,
    required this.teamTask,
  });

  @override
  State<TaskFilterPage> createState() => TaskFilterPageState();
}

class TaskFilterPageState extends State<TaskFilterPage> {
  late List<Task> tasks;
  late List<Task> allTasks;
  List<Task> tasksToShow = [];
  List<String> allUserNames = [];
  List<String> selectedUserIds = [];
  List<String> selectedTeamIds = [];
  List<String> teams = [];

  Map<String, String> taskAndUsersMAP = {};

  List<bool> priotitySelected = [false, false, false];
  TextEditingController initialLimitDateController = TextEditingController();
  TextEditingController finalLimitDateController = TextEditingController();

  TextEditingController initialOpenDateController = TextEditingController();
  TextEditingController finalOpenDateController = TextEditingController();

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  final DateTime now = DateTime.now();

  TaskState? stateSelected;
  DateTime? limitDateInitSelected;
  DateTime? limitDateFinalSelected;

  DateTime? openDateInitSelected;
  DateTime? openDateFinalSelected;

  @override
  void initState() {
    super.initState();
    tasks = widget.tasks;
    allTasks = widget.allTasks;
    allUserNames = widget.allUserNames;
    allUserNames = allUserNames.where((element) => element != AppStrings.SHOWALL).toList();
    taskAndUsersMAP = widget.taskAndUsersMAP;
    getTeams();
  }

  void getTeams() {
    List<TeamTask> teamTask = widget.teamTask;
    for (TeamTask tt in teamTask) {
      if (!teams.contains(tt.team.name)) {
        teams.add(tt.team.name);
      }
    }
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
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  _tableRow(
                    'Nom i\nDescripció',
                    Column(children: [name(), SizedBox(height: 10), description()]),
                  ), //NOMS QUE COMTIMGUIN EL STRING ESCRIT
                  _tableRow(
                    'Usuari(s)',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [selectUser(), SizedBox(height: 10), showUsersSelected()],
                    ),
                  ), //USUARI SELECCIONAT O USUARIS QUE CONTINGUIN STRING
                  if (teams.isNotEmpty)
                    _tableRow(
                      'Equip',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [selectTeam(), SizedBox(height: 10), showTeamsSelected()],
                      ),
                    ), //EQUIP SELECCIONAT (S'HA DE FER EQUIPS)
                  _tableRow('Estat', state()),
                  _tableRow('Prioritat', priorities()),
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
        _wideTableRow('Data límit', limitDateInit(), limitDateFin()),
        _wideTableRow('Data obertura', openDateInit(), openDateFin()),
        _wideTableRow('Nom i\nDescripció', name(), description()), //NOMS QUE COMTIMGUIN EL STRING ESCRIT
        _wideTableRow(
          'Usuari(s)',
          selectUser(),
          showUsersSelected(),
        ), //USUARI SELECCIONAT O USUARIS QUE CONTINGUIN STRING
        if (teams.isNotEmpty)
          _wideTableRow('Equip', selectTeam(), showTeamsSelected()), //EQUIP SELECCIONAT (S'HA DE FER EQUIPS)
        _wideTableRow('Estat', state()),
        _wideTableRow('Prioritat', priorities()),
      ],
    );
  }

  void filter() {
    tasksToShow.clear();
    tasksToShow.addAll(allTasks);
    tasks.clear();

    _dateLimitFilter();
    _nameFilter();
    _descriptionFilter();
    _stateFilter();
    _priorityFilter();
    _dateOpenFilter();
    _userFilter();
    _teamFilter();

    tasks.addAll(tasksToShow);
  }

  void _dateLimitFilter() {
    if (!(limitDateInitSelected == null && limitDateFinalSelected == null)) {
      if (limitDateInitSelected == null && limitDateFinalSelected != null) {
        tasksToShow = tasksToShow.where((task) => task.limitDate.isBefore(limitDateFinalSelected!)).toList();
      } else if (limitDateInitSelected != null && limitDateFinalSelected == null) {
        tasksToShow = tasksToShow.where((task) => task.limitDate.isAfter(limitDateInitSelected!)).toList();
      } else {
        tasksToShow = tasksToShow.where((task) {
          return task.limitDate.isBefore(limitDateFinalSelected!) && task.limitDate.isAfter(limitDateInitSelected!);
        }).toList();
      }
    }
  }

  void _descriptionFilter() {
    if (descriptionController.text != '') {
      tasksToShow = tasksToShow
          .where((task) => task.description.toLowerCase().contains(descriptionController.text.toLowerCase()))
          .toList();
    }
  }

  void _nameFilter() {
    if (nameController.text != '') {
      tasksToShow = tasksToShow
          .where((task) => task.name.toLowerCase().contains(nameController.text.toLowerCase()))
          .toList();
    }
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
    if (!(openDateInitSelected == null && openDateFinalSelected == null)) {
      if (openDateInitSelected == null && openDateFinalSelected != null) {
        tasksToShow = tasksToShow.where((task) => task.openDate.isBefore(openDateFinalSelected!)).toList();
      } else if (openDateInitSelected != null && openDateFinalSelected == null) {
        tasksToShow = tasksToShow.where((task) => task.openDate.isAfter(openDateInitSelected!)).toList();
      } else {
        tasksToShow = tasksToShow.where((task) {
          return task.openDate.isBefore(openDateFinalSelected!) && task.openDate.isAfter(openDateInitSelected!);
        }).toList();
      }
    }
  }

  void _userFilter() {
    if (selectedUserIds.isNotEmpty) {
      final taskFromUser = taskAndUsersMAP.entries
          .where((e) {
            final usersInTask = e.value.split(AppStrings.SEPARATOR).map((u) => u.trim()).toList();
            return usersInTask.any((u) => selectedUserIds.contains(u));
          })
          .map((e) {
            return e.key;
          })
          .toList();

      tasksToShow = tasksToShow.where((task) => taskFromUser.contains(task.id)).toList();
    }
  }

  void _teamFilter() {
    if (selectedTeamIds.isNotEmpty) {
      List<Task> tasks = widget.teamTask
          .where((tt) => selectedTeamIds.contains(tt.team.name))
          .map((tt) => tt.task)
          .toList();
      tasksToShow = tasksToShow.where((task) => tasks.contains(task)).toList();
    }
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
          initialDate: limitDateInitSelected ?? limitDateFinalSelected ?? now,
          firstDate: DateTime(now.year, now.month - 3),
          lastDate: limitDateFinalSelected ?? DateTime(now.year + 50),
          locale: const Locale('es', 'ES'),
        );
        if (picked != null) {
          setState(() {
            limitDateInitSelected = picked;
            initialLimitDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
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
          initialDate: limitDateFinalSelected ?? limitDateInitSelected ?? now,
          firstDate: limitDateInitSelected ?? DateTime(now.year, now.month - 3),
          lastDate: DateTime(now.year + 50),
          locale: const Locale('es', 'ES'),
        );
        if (picked != null) {
          setState(() {
            limitDateFinalSelected = picked;
            finalLimitDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
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
          initialDate: openDateInitSelected ?? openDateFinalSelected ?? now,
          firstDate: DateTime(now.year, now.month - 3),
          lastDate: openDateFinalSelected ?? DateTime(now.year + 50),
          locale: const Locale('es', 'ES'),
        );
        if (picked != null) {
          setState(() {
            openDateInitSelected = picked;
            initialOpenDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
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
          initialDate: openDateFinalSelected ?? openDateInitSelected ?? now,
          firstDate: openDateInitSelected ?? DateTime(now.year, now.month - 3),
          lastDate: DateTime(now.year + 50),
          locale: const Locale('es', 'ES'),
        );
        if (picked != null) {
          setState(() {
            openDateFinalSelected = picked;
            finalOpenDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
    );
  }

  Autocomplete<String> selectUser() {
    return Autocomplete<String>(
      displayStringForOption: (userName) => userName,

      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return allUserNames.where(
          (u) => u.toLowerCase().contains(textEditingValue.text.toLowerCase()) && !selectedUserIds.contains(u),
        );
      },

      onSelected: (String selection) {
        setState(() {
          selectedUserIds.add(selection);
        });
      },

      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Nom d\'usuari',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
          ),
        );
      },
    );
  }

  Wrap showUsersSelected() {
    return Wrap(
      spacing: 8,
      children: selectedUserIds
          .map(
            (u) => Chip(
              label: Text(u),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              //side: BorderSide(color: Theme.of(context).colorScheme.inversePrimary),
              onDeleted: () {
                setState(() {
                  selectedUserIds.remove(u);
                });
              },
              deleteButtonTooltipMessage: 'Eliminar',
            ),
          )
          .toList(),
    );
  }

  Autocomplete<String> selectTeam() {
    return Autocomplete<String>(
      displayStringForOption: (team) => team,

      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return teams.where(
          (u) => u.toLowerCase().contains(textEditingValue.text.toLowerCase()) && !selectedTeamIds.contains(u),
        );
      },

      onSelected: (String selection) {
        setState(() {
          selectedTeamIds.add(selection);
        });
      },

      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Nom del equip',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
          ),
        );
      },
    );
  }

  Wrap showTeamsSelected() {
    return Wrap(
      spacing: 8,
      children: selectedTeamIds
          .map(
            (u) => Chip(
              label: Text(u),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              //side: BorderSide(color: Theme.of(context).colorScheme.inversePrimary),
              onDeleted: () {
                setState(() {
                  selectedTeamIds.remove(u);
                });
              },
              deleteButtonTooltipMessage: 'Eliminar',
            ),
          )
          .toList(),
    );
  }
}
