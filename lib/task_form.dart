import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/controller/state_controller.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/priorities.dart';

class TaskForm extends StatefulWidget {
  final Function(Task, Set<String>)? onTaskCreated;
  final Function(Task)? onTaskEdited;
  final Task task;
  final bool isAdmin;

  //const TaskForm({super.key, this.onTaskCreated, required this.task, this.onTaskEdited, required this.isAdmin})
  //: assert(onTaskCreated != null || onTaskEdited != null, 'S\'ha de proporcionar onTaskCreated o onTaskEdited');

  const TaskForm({super.key, this.onTaskCreated, this.onTaskEdited, required this.task, required this.isAdmin})
    : assert(onTaskCreated != null || onTaskEdited != null, 'S\'ha de proporcionar onTaskCreated o onTaskEdited');

  @override
  TaskFormState createState() => TaskFormState();
}

class TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();

  DateTime? selectedDate;
  String? prioritySTR;
  String? stateSTR;

  late TextEditingController dateController;
  late TextEditingController nameController;
  late TextEditingController descriptionController;

  StateController stateController = StateController();

  late bool isAdmin = false;

  List<User> users = [];
  Set<String> selectedUserIds = {};

  bool isCreating = false;
  List<TaskState> states = [];

  String validator = '';

  @override
  void initState() {
    super.initState();
    selectedDate = widget.task.limitDate;
    prioritySTR = Priorities.priorityToString(widget.task.priority);

    if (widget.onTaskCreated != null) {
      isCreating = true;
    }
    isCreating
        ? dateController = TextEditingController(text: null)
        : dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(widget.task.limitDate));
    nameController = TextEditingController(text: widget.task.name);
    descriptionController = TextEditingController(text: widget.task.description);

    stateSTR = widget.task.state.name;
    if (isCreating) {
      stateSTR = AppStrings.DEFAULT_STATES[0];
    }

    if (widget.isAdmin == true) {
      isAdmin = true;
      usersFromTask();
    }

    loadStates();
    setState(() {});
  }

  Future<void> usersFromTask() async {
    UserController uc = UserController();
    users = await uc.loadAllUsers();
    users.sort((user1, user2) => user1.userName.compareTo(user2.userName));
    setState(() {});
    //users = usersList.map((User user) => user.userName).toList();
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
              decoration: InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.isEmpty) ? 'El nom no pot ser buit' : null,
              onSaved: (value) => name = value!,
            ),

            SizedBox(height: 10),

            //DESCRIPCIÓ
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Descripció', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Es requereix de la descripció';
                }
                return null;
              },
              onSaved: (value) => description = value!,
            ),

            SizedBox(height: 10),

            //DATA LIMIT
            TextFormField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Data límit', border: OutlineInputBorder()),
              readOnly: true,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  //initialDate: widget.task.limitDate,
                  initialDate: newTask.limitDate,
                  //firstDate: DateTime.now(),
                  firstDate: newTask.limitDate.isBefore(DateTime.now()) ? newTask.limitDate : DateTime.now(),
                  lastDate: DateTime(2050),
                  locale: const Locale('es', 'ES'),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                  });
                }
              },
              validator: (value) => (value == null || value.isEmpty) ? 'Siusplau, seleccioneu una data' : null,
            ),

            SizedBox(height: 10),

            //PRIORITAT
            DropdownButtonFormField<String>(
              decoration: InputDecoration(border: OutlineInputBorder()),
              hint: Text('Selecciona nivell de prioritat'),
              value: prioritySTR!.isNotEmpty ? prioritySTR : null,
              items: AppStrings.PRIORITIES_STR.map((line) => DropdownMenuItem(value: line, child: Text(line))).toList(),
              onChanged: (value) {
                setState(() {
                  prioritySTR = value;
                });
              },
              validator: (value) => value == null ? 'Siusplau, seleccioneu una prioritat' : null,
            ),

            SizedBox(height: 10),

            if (isAdmin && isCreating)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Usuaris que tindran aquesta tasca:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),

            if (isAdmin && isCreating)
              Column(
                children: [
                  for (User user in users)
                    Row(
                      children: [
                        Checkbox(
                          value: selectedUserIds.contains(user.userName),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedUserIds.add(user.userName);
                              } else {
                                selectedUserIds.remove(user.userName);
                              }
                            });
                          },
                        ),
                        Text(user.userName),
                      ],
                    ),
                ],
              ),

            if (isAdmin && !isCreating)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(border: OutlineInputBorder()),
                hint: Text('Canviar el estat'),
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
                validator: (value) => value == null ? 'Siusplau, seleccioneu un estat' : null,
              ),

            SizedBox(height: 10),
            Text(validator),
            SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                if (isCreating && selectedUserIds.isEmpty && isAdmin) {
                  validator = 'S\'ha de seleccionar mínim un usuari';
                  setState(() {});
                  return;
                }

                validator = '';
                setState(() {});
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  Task updatedTask = widget.task.copyWith(
                    name: name,
                    description: description,
                    priority: Priorities.priorityFromString(prioritySTR!),
                    limitDate: selectedDate!,
                    state: stateController.getStateByName(stateSTR!),
                  );

                  if (isCreating) {
                    widget.onTaskCreated!(updatedTask.copyWith(id: ''), selectedUserIds);
                  } else if (widget.onTaskEdited != null) {
                    widget.onTaskEdited!(updatedTask);
                  }

                  Navigator.of(context).pop();
                }
              },
              icon: Icon(isCreating ? Icons.add : Icons.edit),
              label: Text(isCreating ? 'Crear' : 'Editar'),
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

  @override
  void dispose() {
    super.dispose();
    dateController.dispose();
    nameController.dispose();
    descriptionController.dispose();
  }
}
