import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/controller/state_controller.dart';
import 'package:to_do_list/controller/team_controller.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/priorities.dart';

class TaskForm extends StatefulWidget {
  final Function(Task, Set<User>, Set<Team>)? onTaskCreated;
  final Function(Task)? onTaskEdited;
  final Task task;
  final bool isAdmin;

  //const TaskForm({super.key, this.onTaskCreated, required this.task, this.onTaskEdited, required this.isAdmin})
  //: assert(onTaskCreated != null || onTaskEdited != null, "S'ha de proporcionar onTaskCreated o onTaskEdited");

  const TaskForm({super.key, this.onTaskCreated, this.onTaskEdited, required this.task, required this.isAdmin})
    : assert(onTaskCreated != null || onTaskEdited != null, "S'ha de proporcionar onTaskCreated o onTaskEdited");

  @override
  TaskFormState createState() => TaskFormState();
}

class TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedFinalDate, selectedOpenDate;
  String? prioritySTR, stateSTR;

  late TextEditingController finalDateController, openDateController, nameController, descriptionController;

  StateController stateController = StateController();
  TeamController teamController = TeamController();

  late bool isAdmin = false;

  List<User> users = [];
  Set<User> selectedUserIds = {};

  List<Team> allTeams = [];
  Set<Team> selectedTeams = {};

  bool isCreating = false;
  List<TaskState> states = [];

  String validator = "";

  @override
  void initState() {
    super.initState();
    selectedFinalDate = widget.task.limitDate;
    selectedOpenDate = widget.task.openDate;
    prioritySTR = Priorities.priorityToString(widget.task.priority);

    if (widget.onTaskCreated != null) {
      isCreating = true;
      finalDateController = TextEditingController(text: null);
      openDateController = TextEditingController(text: DateFormat("dd/MM/yyyy").format(DateTime.now()));
      stateSTR = AppStrings.DEFAULT_STATES[0];
    } else {
      finalDateController = TextEditingController(text: DateFormat("dd/MM/yyyy").format(widget.task.limitDate));
      openDateController = TextEditingController(text: DateFormat("dd/MM/yyyy").format(widget.task.openDate));
      stateSTR = widget.task.state.name;
    }

    nameController = TextEditingController(text: widget.task.name);
    descriptionController = TextEditingController(text: widget.task.description);

    if (widget.isAdmin == true) {
      isAdmin = true;
      usersFromTask();
      loadTeams();
    }
    loadStates();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Task newTask = Task.copy(widget.task);

    String name = newTask.name;
    String description = newTask.description;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            //NOM
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Nom", border: OutlineInputBorder()),
              validator: (value) => (value == null || value.isEmpty) ? "El nom no pot ser buit" : null,
              onSaved: (value) => name = value!,
            ),

            SizedBox(height: 10),

            //DESCRIPCIÓ
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Descripció", border: OutlineInputBorder()),
              maxLines: null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Es requereix de la descripció";
                }
                return null;
              },
              onSaved: (value) => description = value!,
            ),

            SizedBox(height: 10),

            //DATA INICI
            TextFormField(
              controller: openDateController,
              decoration: InputDecoration(labelText: "Data obertura/inici", border: OutlineInputBorder()),
              readOnly: true,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedOpenDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2050),
                  locale: const Locale("es", "ES"),
                );
                if (picked != null) {
                  setState(() {
                    selectedOpenDate = picked;
                    openDateController.text = DateFormat("dd/MM/yyyy").format(picked);
                  });
                }
              },
              validator: (value) => (value == null || value.isEmpty) ? "Siusplau, seleccioneu una data" : null,
            ),

            SizedBox(height: 10),

            //DATA LIMIT
            TextFormField(
              controller: finalDateController,
              decoration: InputDecoration(labelText: "Data límit", border: OutlineInputBorder()),
              readOnly: true,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedFinalDate,
                  firstDate: newTask.limitDate.isBefore(DateTime.now()) ? newTask.limitDate : DateTime.now(),
                  lastDate: DateTime(2050),
                  locale: const Locale("es", "ES"),
                );
                if (picked != null) {
                  setState(() {
                    selectedFinalDate = picked;
                    finalDateController.text = DateFormat("dd/MM/yyyy").format(picked);
                  });
                }
              },
              validator: (value) => (value == null || value.isEmpty) ? "Siusplau, seleccioneu una data" : null,
            ),

            SizedBox(height: 10),

            //PRIORITAT
            DropdownButtonFormField<String>(
              decoration: InputDecoration(border: OutlineInputBorder()),
              hint: Text("Selecciona nivell de prioritat"),
              value: prioritySTR!.isNotEmpty ? prioritySTR : null,
              items: AppStrings.PRIORITIES_STR.map((line) => DropdownMenuItem(value: line, child: Text(line))).toList(),
              onChanged: (value) {
                setState(() {
                  prioritySTR = value;
                });
              },
              validator: (value) => value == null ? "Siusplau, seleccioneu una prioritat" : null,
            ),

            SizedBox(height: 10),

            //AFEGIR USUARIS
            if (isAdmin && isCreating) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Usuaris que tindran aquesta tasca:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              SizedBox(height: 5),

              Autocomplete<User>(
                displayStringForOption: (user) => user.userName,

                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<User>.empty();
                  return users.where(
                    (u) =>
                        u.userName.toLowerCase().contains(textEditingValue.text.toLowerCase()) &&
                        !selectedUserIds.contains(u),
                  );
                },
                onSelected: (User selection) {
                  setState(() {
                    selectedUserIds.add(selection);
                  });
                },

                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,

                    decoration: InputDecoration(
                      //labelText: "Nom d'usuari",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 8,
                  children: selectedUserIds
                      .map(
                        (u) => Chip(
                          label: Text(u.userName),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(90),
                          side: BorderSide(color: Theme.of(context).colorScheme.inversePrimary),

                          onDeleted: () {
                            setState(() {
                              selectedUserIds.remove(u);
                            });
                          },
                          deleteButtonTooltipMessage: "Eliminar",
                        ),
                      )
                      .toList(),
                ),
              ),
              
              //AFEGIR EQUIPS
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Equips que tindran aquesta tasca:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              if (isAdmin && isCreating) SizedBox(height: 5),
              if (isAdmin && isCreating)
                Autocomplete<Team>(
                  displayStringForOption: (team) => team.name,

                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<Team>.empty();
                    return allTeams.where(
                      (t) =>
                          t.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) &&
                          !selectedTeams.contains(t),
                    );
                  },

                  onSelected: (Team selection) {
                    setState(() {
                      selectedTeams.add(selection);
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,

                      decoration: InputDecoration(
                        //labelText: "Nom equip",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                      ),
                    );
                  },
                ),
              if (isAdmin && isCreating) SizedBox(height: 10),
              if (isAdmin && isCreating)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: selectedTeams
                        .map(
                          (t) => Chip(
                            label: Text(t.name),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(90),
                            side: BorderSide(color: Theme.of(context).colorScheme.inversePrimary),

                            onDeleted: () {
                              setState(() {
                                selectedTeams.remove(t);
                              });
                            },
                            deleteButtonTooltipMessage: "Eliminar",
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
            if (isAdmin && !isCreating)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(border: OutlineInputBorder()),
                hint: Text("Canviar el estat"),
                value: stateSTR!.isNotEmpty ? stateSTR : null,
                items: states
                    .map(
                      (line) => DropdownMenuItem(
                        value: line.name,
                        child: Text(line.name, style: TextStyle(color: line.color)),
                      ),
                    )
                    .toList(),

                onChanged: (value) {
                  setState(() {
                    stateSTR = value;
                  });
                },
                validator: (value) => value == null ? "Siusplau, seleccioneu un estat" : null,
              ),

            SizedBox(height: 10),
            Text(validator),
            SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                if (isCreating && isAdmin && (selectedUserIds.isEmpty && selectedTeams.isEmpty)) {
                  validator = "S'ha de seleccionar mínim un usuari";
                  setState(() {});
                  return;
                }

                validator = "";
                setState(() {});
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  description = trimDescription(description);

                  Task updatedTask = widget.task.copyWith(
                    name: name,
                    description: description,
                    priority: Priorities.priorityFromString(prioritySTR!),
                    limitDate: selectedFinalDate!,
                    openDate: selectedOpenDate!,
                    completedDate: widget.task.completedDate,
                    state: stateController.getStateByName(stateSTR!),
                  );

                  if (isCreating) {
                    widget.onTaskCreated!(updatedTask.copyWith(id: ""), selectedUserIds, selectedTeams);
                  } else if (widget.onTaskEdited != null) {
                    widget.onTaskEdited!(updatedTask);
                  }

                  Navigator.of(context).pop();
                }
              },
              icon: Icon(isCreating ? Icons.add : Icons.edit),
              label: Text(isCreating ? "Crear" : "Editar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadStates() async {
    await stateController.loadAllStates();
    states = stateController.states;
  }

  Future<void> usersFromTask() async {
    UserController uc = UserController();
    users = await uc.loadAllUsers(false);
    users.sort((user1, user2) => user1.userName.compareTo(user2.userName));
    setState(() {});
    //users = usersList.map((User user) => user.userName).toList();
  }

  Future<void> loadTeams() async {
    await teamController.loadAllTeamsWithUsers();
    allTeams = teamController.allTeamsAndUsers.keys.toList();
  }

  String trimDescription(String desc) {
    String str = "";
    List<String> lines = desc.split("\n");
    for (int pos = 0; pos < lines.length; pos++) {
      lines[pos].trim();
      str += lines[pos].isEmpty ? "" : lines[pos];

      if ((pos + 1 < lines.length) && lines[pos + 1].isNotEmpty) {
        str += "\n";
      }
    }
    return str;
  }

  @override
  void dispose() {
    super.dispose();
    finalDateController.dispose();
    nameController.dispose();
    descriptionController.dispose();
  }
}
