import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

import 'package:to_do_list/controller/notification_controller.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/utils/firebase_options.dart';
import 'package:to_do_list/utils/db_constants.dart';
import 'package:to_do_list/utils/priorities.dart';
import 'package:to_do_list/utils/sort.dart';
import 'package:to_do_list/model/notification.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/config.dart';
import 'package:to_do_list/main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  User userProva = User.parameter(
    '111',
    '111',
    '111',
    '111',
    'f6e0a1e2ac41945a9aa7ff8a8aaa0cebc12a3bcc981a929ad5cf810a090e11ae',
  );

  runApp(MyAppToDo(user: userProva));
}

class MyAppToDo extends StatelessWidget {
  final User user;
  const MyAppToDo({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDoList',
      home: MyHomePageToDo(user: user),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}

class MyHomePageToDo extends StatefulWidget {
  final User user;
  const MyHomePageToDo({super.key, required this.user});

  @override
  State<MyHomePageToDo> createState() => ToDoPage();
}

class ToDoPage extends State<MyHomePageToDo> {
  SortType sortType = SortType.NONE;
  late User myUser;

  List<Task> tasks = [];
  List<Notifications> notifications = [];

  NotificationController notController = NotificationController.empty();
  TaskController taskController = TaskController.empty();
  UserController userController = UserController();

  @override
  void initState() {
    super.initState();
    myUser = widget.user;
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await taskController.loadTasksFromDB(myUser.userName, sortType);
    await notController.loadNotificationsFromDB(myUser.userName);
    setState(() {
      notifications = notController.notifications;
      tasks = taskController.tasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(myUser.userName),

              Row(
                children: [
                  //viewNotifications(),
                  IconButton(
                    tooltip: 'Notificacions',
                    onPressed: () async {
                      openNotifications();
                    },
                    icon: (notifications.isEmpty)
                        ? Icon(Icons.notifications)
                        : Icon(Icons.notifications_active, color: Colors.red),
                  ),

                  PopupMenuButton(
                    icon: Icon(Icons.menu),
                    tooltip: 'Menú',
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.settings, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('Configuració'),
                          ],
                        ),

                        onTap: () async {
                          final updatedUser = await Navigator.push<User>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfigHP(user: myUser),
                            ),
                          );

                          if (updatedUser != null) {
                            setState(() {
                              myUser = User.copy(updatedUser);
                            });
                            taskController.loadTasksFromDB(
                              myUser.userName,
                              sortType,
                            );
                          }
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.exit_to_app, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('Tancar sessió'),
                          ],
                        ),
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MyHomePage()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(30),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.only(bottom: 10),

              child: PopupMenuButton(
                tooltip: 'Sobre quin element voleu ordenar',

                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 8),
                        Text('Prioritat'),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        sortType = SortType.NONE;
                        tasks.sort((task1, task2) {
                          return Task.sortTask(sortType, task1, task2);
                        });
                      });
                    },
                  ),

                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 8),
                        Text('Data'),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        sortType = SortType.DATE;
                        tasks.sort((task1, task2) {
                          return Task.sortTask(sortType, task1, task2);
                        });
                      });
                    },
                  ),

                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.text_fields_rounded, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Nom'),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        sortType = SortType.NAME;
                        tasks.sort((task1, task2) {
                          return Task.sortTask(sortType, task1, task2);
                        });
                      });
                    },
                  ),
                ],
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(28, 104, 58, 183),
                    borderRadius: BorderRadius.circular(12.0),
                  ),

                  child: Text('Ordenar', style: TextStyle(fontSize: 17)),
                ),
              ),
            ),

            Expanded(
              child: tasks.isEmpty
                  ? Center(child: Text('No hi ha tasques.'))
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];

                        return Card(
                          child: ListTile(
                            leading: getIconPriority(task),
                            title: Text(
                              '${task.getName()}   -   ${DateFormat('dd/MMM').format(task.getLimitDate())}',
                            ),
                            subtitle: Text(task.getDescription()),
                            textColor: task.limitDate.isBefore(DateTime.now())
                                ? Colors.red
                                : null,
                            trailing: SizedBox(
                              width: 150,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: 'Editar',
                                    onPressed: () => openEditTask(task, index),
                                    icon: Icon(Icons.edit),
                                  ),

                                  //BOTO PER A ELIMINAR
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    onPressed: () async {
                                      await confirmDelete(
                                        index,
                                        task.id,
                                        false,
                                      );
                                    },
                                    icon: Icon(Icons.delete),
                                    style: ButtonStyle(
                                      foregroundColor:
                                          WidgetStateProperty.resolveWith<
                                            Color
                                          >((states) {
                                            if (states.contains(
                                              WidgetState.hovered,
                                            )) {
                                              return Colors.red;
                                            }
                                            return Colors.black54;
                                          }),
                                    ),
                                  ),

                                  //BOTO MARCAR FETA
                                  IconButton(
                                    tooltip: 'Marcar com a feta',
                                    icon: Icon(
                                      Icons.check_circle,
                                      color: task.completed
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    onPressed: () async {
                                      Task updatedTask = task.copyWith(
                                        completed: !task.completed,
                                      );
                                      await taskController.updateTaskInDatabase(
                                        updatedTask,
                                        task.id,
                                      );
                                      setState(() {
                                        tasks[index] = updatedTask;
                                      });
                                      if (updatedTask.completed) {
                                        await confirmDelete(
                                          index,
                                          task.id,
                                          true,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              String str = await taskController
                                  .getUsersRelatedWithTask(task.id);
                              openShowTask(task, str);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addTask',
        onPressed: () {
          openForm();
        },
        label: Text('Afegir tasca'),
        icon: Icon(Icons.add),
      ),
    );
  }

  openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 30,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: TaskForm(
              onTaskCreated: (Task task) async {
                await taskController.addTaskToDataBase(task, myUser.userName);
                setState(() {
                  tasks.add(task);
                  tasks.sort((task1, task2) {
                    return Task.sortTask(sortType, task1, task2);
                  });
                });
              },
              task: Task.empty(),
            ),
          ),
        );
      },
    );
  }

  confirmDelete(int index, String id, bool isDone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isDone ? 'La tasca està completada' : 'Eliminar tasca'),
          content: Text(
            isDone ? 'La vols eliminar?' : 'Estàs segur que vols continuar?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await taskController.deleteTaskInDatabase(id);
                //loadInitialData();
                setState(() {
                  tasks.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.red;
                  }
                  return Theme.of(context).colorScheme.primary;
                }),
              ),
              child: Text('Confirmar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.indigo;
                  }
                  return Theme.of(context).colorScheme.primary;
                }),
              ),
              child: Text('Cancel·lar'),
            ),
          ],
        );
      },
    );
  }

  Icon getIconPriority(Task task) {
    Priorities priority = task.getPriority();
    switch (priority) {
      case Priorities.HIGH:
        return Icon(Icons.arrow_upward, color: Colors.red);
      case Priorities.MEDIUM:
        return Icon(Icons.keyboard_arrow_up, color: Colors.orange);
      case Priorities.LOW:
        return Icon(Icons.arrow_drop_up, color: Colors.green);
      default:
        return Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  openEditTask(Task taskToEdit, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 30,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: TaskForm(
              onTaskEdited: (Task task) async {
                await taskController.updateTaskInDatabase(task, task.getId());

                setState(() {
                  tasks[index] = task;
                  tasks.sort((task1, task2) {
                    return Task.sortTask(sortType, task1, task2);
                  });
                });
              },
              task: taskToEdit,
            ),
          ),
        );
      },
    );
  }

  openShowTask(Task task, String users) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsetsGeometry.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 30,
          ),
          child: viewTask(task, users),
        );
      },
    );
  }

  Widget viewTask(Task task, String users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.name,
          style: TextStyle(color: Colors.deepPurple, fontSize: 20),
        ),
        SizedBox(height: 20),
        Table(
          columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          children: [
            //buildTableRow('Nom:', task.name),
            tableRow('Descripció:', task.description),
            tableRow(
              'Prioritat:',
              TaskFormState().priorityToString(task.priority),
            ),
            tableRow(
              'Data límit:',
              DateFormat('dd/MM/yyyy').format(task.limitDate),
            ),
            tableRow('', task.completed ? 'Completada' : 'Pendent'),
          ],
        ),

        SizedBox(height: 20),
        Divider(),
        Text(
          'Usuaris relacionats amb aquesta tasca:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(users),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            enterUserName(task);
          },
          label: Text('Compartir amb un altre usuari'),
          icon: Icon(Icons.send_rounded),
        ),
      ],
    );
  }

  Future<bool> enterUserName(Task task) async {
    final TextEditingController userNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Compartir Tasca'),
          //content: Text('Nom d\'usuari a qui es vol compartir'),
          actions: <Widget>[
            Row(children: [Text('Nom d\'usuari a qui es vol compartir')]),

            TextField(
              controller: userNameController,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),

            SizedBox(height: 10),

            Row(children: [Text('Descripció')]),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),

            SizedBox(height: 10),

            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    final userName = userNameController.text.trim();

                    final isValid = await userController.userNameExists(
                      userName,
                    );
                    if (!isValid) {
                      await userNotFoundMessage('Aquest usuari no existeix');
                      return;
                    }

                    final invited = await notController.taskInvitation(
                      userName,
                      task,
                      myUser.userName,
                      descriptionController.text,
                    );
                    if (!invited) {
                      await userNotFoundMessage(
                        'Aquesta tasca ja ha estat compartida',
                      );
                      return;
                    }

                    Navigator.of(context).pop(true);
                  },
                  child: Text('Confirmar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel·lar'),
                ),
              ],
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  userNotFoundMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Acceptar'),
            ),
          ],
        );
      },
    );
  }

  TableRow tableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
          child: Text(value),
        ),
      ],
    );
  }

  openNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 30,
          ),

          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: viewNotifications(),
          ),
        );
      },
    );
  }

  viewNotifications() {
    return (notifications.isEmpty)
        ? Center(child: Text('No hi ha notificacions.'))
        : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return Card(
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.all(5),

                  leading: Text('    ${index + 1}'),
                  title: Text(notification.description),
                  tileColor: Colors.deepPurple.shade50,
                  subtitle: Text(notification.name),

                  trailing: SizedBox(
                    width: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        //ELIMINAR
                        IconButton(
                          tooltip: 'Eliminar',
                          icon: Icon(Icons.delete),
                          style: ButtonStyle(
                            foregroundColor:
                                WidgetStateProperty.resolveWith<Color>((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return Colors.red;
                                  }
                                  return Colors.black54;
                                }),
                          ),
                          onPressed: () async {
                            await notController.deleteNotificationInDatabase(
                              index,
                            );
                            setState(() {
                              notifications = notController.notifications;
                            });
                            await notController.loadNotificationsFromDB(
                              myUser.userName,
                            );
                            notifications = notController.notifications;
                            Navigator.of(context).pop();
                          },
                        ),

                        //ACCEPTAR
                        IconButton(
                          tooltip: 'Acceptar tasca',
                          icon: Icon(Icons.check_circle, color: Colors.grey),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection(DbConstants.USERTASK)
                                .add({
                                  'userName': notification.userName,
                                  'taskId': notification.taskId,
                                });

                            Task newTask = await taskController.getTaskByID(
                              notification.taskId,
                            );
                            await notController.deleteNotificationInDatabase(
                              index,
                            );
                            setState(() {
                              notifications = notController.notifications;
                            });
                            await notController.loadNotificationsFromDB(
                              myUser.userName,
                            );
                            setState(() {
                              tasks.add(newTask);
                              tasks.sort((task1, task2) {
                                return Task.sortTask(sortType, task1, task2);
                              });
                              notifications = notController.notifications;
                            });

                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  //onTap: () => openShowTask(notification),
                ),
              );
            },
          );
  }
}

class TaskForm extends StatefulWidget {
  final Function(Task)? onTaskCreated;
  final Function(Task)? onTaskEdited;
  final Task task;

  const TaskForm({
    super.key,
    this.onTaskCreated,
    required this.task,
    this.onTaskEdited,
  }) : assert(
         onTaskCreated != null || onTaskEdited != null,
         'S\'ha de proporcionar onTaskCreated o onTaskEdited',
       );

  @override
  TaskFormState createState() => TaskFormState();
}

class TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();

  DateTime? selectedDate;
  late TextEditingController dateController;
  String? prioritySTR;

  late TextEditingController nameController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.task.getLimitDate();
    prioritySTR = priorityToString(widget.task.getPriority());
    widget.onTaskCreated != null
        ? dateController = TextEditingController(text: null)
        : dateController = TextEditingController(
            text: DateFormat('dd/MM/yyyy').format(widget.task.getLimitDate()),
          );
    nameController = TextEditingController(text: widget.task.getName());
    descriptionController = TextEditingController(
      text: widget.task.getDescription(),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> priorities = ['Alt', 'Mitjà', 'Baix'];
    Task newTask = Task.copy(widget.task);

    String name = newTask.getName();
    String description = newTask.getDescription();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          //NOM
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? 'El nom no pot ser buit'
                : null,
            onSaved: (value) => name = value!,
          ),

          SizedBox(height: 10),

          //DESCRIPCIÓ
          TextFormField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: 'Descripció',
              border: OutlineInputBorder(),
            ),
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
            decoration: InputDecoration(
              labelText: 'Data límit',
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: widget.task.getLimitDate(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2050),
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                  dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                });
              }
            },
            validator: (value) => (value == null || value.isEmpty)
                ? 'Siusplau, seleccioneu una data'
                : null,
          ),

          SizedBox(height: 10),

          //PRIORITAT
          DropdownButtonFormField<String>(
            decoration: InputDecoration(border: OutlineInputBorder()),
            hint: Text('Selecciona nivell de prioritat'),
            value: prioritySTR!.isNotEmpty ? prioritySTR : null,
            items: priorities
                .map((line) => DropdownMenuItem(value: line, child: Text(line)))
                .toList(),
            onChanged: (value) {
              setState(() {
                prioritySTR = value;
              });
            },
            validator: (value) =>
                value == null ? 'Siusplau, seleccioneu una prioritat' : null,
          ),

          SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                Task updatedTask = widget.task.copyWith(
                  name: name,
                  description: description,
                  priority: priorityFromString(prioritySTR!),
                  limitDate: selectedDate!,
                );

                if (widget.onTaskCreated != null) {
                  widget.onTaskCreated!(updatedTask.copyWith(id: ''));
                } else if (widget.onTaskEdited != null) {
                  widget.onTaskEdited!(updatedTask);
                }

                Navigator.of(context).pop();
              }
            },
            icon: Icon(widget.onTaskCreated != null ? Icons.add : Icons.edit),
            label: Text(widget.onTaskCreated != null ? 'Crear' : 'Editar'),
          ),
        ],
      ),
    );
  }

  Priorities priorityFromString(String str) {
    switch (str) {
      case 'Alt':
        return Priorities.HIGH;
      case 'Mitjà':
        return Priorities.MEDIUM;
      case 'Baix':
        return Priorities.LOW;
      default:
        return Priorities.NONE;
    }
  }

  String priorityToString(Priorities priority) {
    switch (priority) {
      case Priorities.HIGH:
        return 'Alt';
      case Priorities.MEDIUM:
        return 'Mitjà';
      case Priorities.LOW:
        return 'Baix';
      default:
        return '';
    }
  }
}
