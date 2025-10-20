// ignore_for_file: use_build_context_synchronously

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:to_do_list/controller/notification_controller.dart';
import 'package:to_do_list/controller/state_controller.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/task_filter.dart';
import 'package:to_do_list/task_form.dart';
import 'package:to_do_list/utils/const/firebase_options.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/priorities.dart';
import 'package:to_do_list/utils/user_role.dart';
import 'package:to_do_list/utils/sort.dart';
import 'package:to_do_list/model/notification.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/config.dart';
import 'package:to_do_list/main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  User userProva = User(
    name: '111',
    surname: '111',
    userName: '111',
    mail: '111',
    password: 'f6e0a1e2ac41945a9aa7ff8a8aaa0cebc12a3bcc981a929ad5cf810a090e11ae',
    userRole: UserRole.ADMIN,
    iconName: Icon(Icons.park),
  );

  runApp(MyAppToDo(user: userProva));
}

class MyAppToDo extends StatelessWidget {
  final User user;
  const MyAppToDo({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: user.userName,
      home: MyHomePageToDo(user: user),
      theme: ThemeData(
        colorScheme: (!UserRole.isAdmin(user.userRole))
            ? ColorScheme.fromSeed(seedColor: Colors.deepPurple)
            : ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('es')],
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

  //bool showAllTask = true;

  List<Task> tasksToShow = [];
  List<Task> allTasks = [];

  List<Notifications> notifications = [];
  List<String> allUserNames = [];
  //List<String> usersFromTask = [];
  Map<String, String> taskAndUsersMAP = {};

  List<Task> taskToDelete = [];

  NotificationController notController = NotificationController();
  TaskController taskController = TaskController();
  UserController userController = UserController();
  StateController stateController = StateController();

  Set<String> usersSelected = {};
  Set<String> taskSelected = {};

  @override
  void initState() {
    super.initState();
    myUser = widget.user;
    loadInitialData(UserRole.isAdmin(myUser.userRole));
  }

  Future<void> loadInitialData(bool allTask) async {
    if (allTask) {
      await taskController.loadAllTasksFromDB();
      await notController.loadALLNotificationsFromDB();
    } else {
      await taskController.loadTasksFromDB(myUser.userName);
      await notController.loadNotificationsFromDB(myUser.userName);
    }
    await stateController.loadAllStates();

    notifications = notController.notifications;
    tasksToShow = taskController.tasks;
    allTasks.clear();
    allTasks.addAll(tasksToShow);

    //allTasks = tasksToShow.map((Task task) => Task.copy(task)).toList();

    //filterTask = List.from(allTasks);
    allUserNames = (await userController.loadAllUsers()).map((User user) => user.userName).toList();
    allUserNames.sort();
    allUserNames.insert(0, AppStrings.SHOWALL);

    await taskAndUsers();

    //loadTasksToDelete();

    setState(() {});
  }

  /*void loadTasksToDelete() {
    taskToDelete.clear();
    for (Task task in allTasks) {
      if (TaskState.isDone(task.state)) {
        taskToDelete.add(task);
      }
    }
    if (taskToDelete.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hi ha algunes tasques completades'),
              TextButton(
                onPressed: () async {
                  await deleteCompletedTasks();
                  //Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text('Veure tasques'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 10),
        ),
      );
    }
    setState(() {});
  }*/

  Future<bool> deleteCompletedTasks() async {
    taskSelected.clear();
    bool ret = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text('Tasques completades'),

              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selecciona les tasques que vol eliminar'),
                    SizedBox(height: 10),

                    for (Task task in taskToDelete)
                      Row(
                        children: [
                          Checkbox(
                            value: taskSelected.contains(task.id),
                            onChanged: (value) {
                              setStateDialog(() {
                                if (value == true) {
                                  taskSelected.add(task.id);
                                } else {
                                  taskSelected.remove(task.id);
                                }
                              });
                            },
                          ),
                          Text(task.name),
                        ],
                      ),
                  ],
                ),
              ),

              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    for (String taskId in taskSelected) {
                      tasksToShow.removeWhere((Task task) => task.id == taskId);
                      await taskController.deleteTaskWithRelation(taskId);
                    }
                    setState(() {});
                    Navigator.of(context).pop();
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
            );
          },
        );
      },
    );
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 500;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,

            title: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [myUser.icon, Container(width: 7), Text(myUser.userName)]),

                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Notificacions',
                        onPressed: () {
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
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();

                              final updatedUser = await Navigator.push<User>(
                                context,
                                MaterialPageRoute(builder: (context) => ConfigHP(user: myUser)),
                              );

                              if (updatedUser != null) {
                                setState(() {
                                  myUser = User.copy(updatedUser);
                                });
                              }
                              loadInitialData(UserRole.isAdmin(myUser.userRole));
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
                            onTap: () =>
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp())),
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
                Row(
                  children: [
                    taskSort(),
                    Container(width: 10),
                    if (UserRole.isAdmin(myUser.userRole)) userFilter(),
                    if (UserRole.isAdmin(myUser.userRole)) Container(width: 10),
                    taskFilter(),
                    Container(width: 10),
                    showAllTask(),
                  ],
                ),

                Expanded(
                  child: tasksToShow.isEmpty
                      ? Center(child: Text('No hi ha tasques.'))
                      : ListView.builder(
                          itemCount: tasksToShow.length,
                          itemBuilder: (context, index) {
                            final task = tasksToShow[index];

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                return Card(
                                  color: backgroundColor(task),
                                  child: isCompact
                                      ? Container(
                                          padding: const EdgeInsets.all(8.0),
                                          width: double.infinity,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                children: [
                                                  Priorities.getIconPriority(
                                                    task.priority,
                                                    task.limitDate.isBefore(DateTime.now()),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      AppStrings.titleText(task),
                                                      style: TextStyle(
                                                        //color: textColor(task),
                                                        fontSize:
                                                            Theme.of(context).textTheme.titleMedium!.fontSize! + 1,
                                                        fontWeight: Theme.of(context).textTheme.titleMedium?.fontWeight,
                                                      ),
                                                    ),
                                                    SizedBox(height: 5),
                                                    Text(
                                                      AppStrings.subtitleText(
                                                        task.description,
                                                        taskAndUsersMAP[task.id] ?? '',
                                                      ),
                                                      style: TextStyle(color: textColor(task)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              buttons(task, index),
                                            ],
                                          ),
                                        )
                                      : ListTile(
                                          leading: Container(
                                            height: 30,
                                            width: 30,
                                            /*decoration: const BoxDecoration(
                                              color: Colors.amber,
                                              shape: BoxShape.circle,
                                            ),*/

                                            //color: Colors.white,
                                            child: Priorities.getIconPriority(
                                              task.priority,
                                              task.limitDate.isBefore(DateTime.now()),
                                            ),
                                          ),

                                          title: Text(AppStrings.titleText(task)),
                                          subtitle: Text(
                                            AppStrings.subtitleText(task.description, taskAndUsersMAP[task.id] ?? ''),
                                          ),

                                          textColor: textColor(task),
                                          trailing: SizedBox(width: 150, child: buttons(task, index)),
                                          onTap: () => openShowTask(task),
                                        ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          floatingActionButton: !isCompact
              ? FloatingActionButton.extended(
                  heroTag: 'addTask',
                  onPressed: () => openForm(),
                  label: Text('Afegir tasca'),
                  icon: Icon(Icons.add),
                )
              : FloatingActionButton.extended(label: Icon(Icons.add), onPressed: () => openForm()),
        );
      },
    );
  }

  void openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 30),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: TaskForm(
                isAdmin: UserRole.isAdmin(myUser.userRole),
                onTaskCreated: (Task task, Set<String> users) async {
                  String usersToAdd = '';
                  if (UserRole.isAdmin(myUser.userRole)) {
                    await taskController.addTaskToDataBase(task, users.first);
                    usersToAdd += users.first;
                    users.remove(users.first);
                    if (users.isNotEmpty) {
                      for (String userName in users) {
                        taskController.createRelation(task.id, userName);
                        usersToAdd += '${AppStrings.USER_SEPARATOR}$userName';
                      }
                    }
                    taskAndUsersMAP[task.id] = usersToAdd;
                  } else {
                    await taskController.addTaskToDataBase(task, myUser.userName);
                    taskAndUsersMAP[task.id] = myUser.userName;
                  }

                  addTask(task);
                  //await taskAndUsers();
                  setState(() {
                    //tasks.add(task);
                    tasksToShow.sort((task1, task2) {
                      return TaskController.sortTask(sortType, task1, task2, taskAndUsersMAP);
                    });
                    taskAndUsersMAP;
                  });
                  //taskAndUsersMAP;
                },
                task: Task.empty(),
              ),
            ),
          ),
        );
      },
    );
  }

  confirmDelete(int index, String taskId, bool isDone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isDone ? 'La tasca està completada' : 'Eliminar tasca'),
          content: Text(isDone ? 'La vols eliminar?' : 'Estàs segur que vols continuar?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                List<String> allUsers = taskAndUsersMAP[taskId]!.split(AppStrings.USER_SEPARATOR);

                if (UserRole.isAdmin(myUser.userRole) && allUsers.length > 1) {
                  bool confirmed = await selectUsersToDeleteTask(taskId);
                  if (confirmed) {
                    await taskAndUsers();
                    if (taskAndUsersMAP[taskId]!.isEmpty) {
                      tasksToShow.removeAt(index);
                      allTasks.removeWhere((task) => task.id == taskId);
                      taskAndUsersMAP.remove(taskId);
                    }
                    //loadInitialData(true);
                    setState(() {});
                    Navigator.of(context).pop();
                  }
                  //await selectUsersToDeleteTask(taskId);
                } else {
                  await taskController.removeTask(taskId, myUser.userName);
                  setState(() {
                    tasksToShow.removeAt(index);
                    allTasks.removeWhere((task) => task.id == taskId);
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.red;
                  }
                  return Theme.of(context).colorScheme.primary;
                }),
              ),
              child: Text(AppStrings.CONFIRM),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.hovered)) {
                    //return Colors.indigo;
                    return Theme.of(context).colorScheme.onPrimaryContainer;
                  }
                  return Theme.of(context).colorScheme.primary;
                }),
              ),
              child: Text(AppStrings.CANCEL),
            ),
          ],
        );
      },
    );
  }

  Future<bool> selectUsersToDeleteTask(String taskId) async {
    usersSelected.clear();
    List<String> allUsers = taskAndUsersMAP[taskId]!.split(AppStrings.USER_SEPARATOR);

    allUsers = allUsers.map((e) => e.trim()).toList();
    allUsers.sort();

    bool ret = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text('Usuaris'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seleccioneu els usuaris als que voleu eliminar la tasca'),
                    for (String userName in allUsers)
                      Row(
                        children: [
                          Checkbox(
                            value: usersSelected.contains(userName),
                            onChanged: (value) {
                              setStateDialog(() {
                                if (value == true) {
                                  usersSelected.add(userName);
                                } else {
                                  usersSelected.remove(userName);
                                }
                              });
                            },
                          ),
                          Text(userName),
                        ],
                      ),
                  ],
                ),
              ),

              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    if (usersSelected.isNotEmpty) {
                      for (String userName in usersSelected) {
                        await taskController.removeTask(taskId, userName);
                      }
                      ret = true;
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(AppStrings.CONFIRM),
                ),
                TextButton(
                  onPressed: () {
                    ret = false;
                    Navigator.of(context).pop();
                    //Navigator.of(context).pop();
                  },
                  child: Text(AppStrings.CANCEL),
                ),
              ],
            );
          },
        );
      },
    );
    return ret;
  }

  void openEditTask(Task taskToEdit, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 30),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: TaskForm(
              isAdmin: UserRole.isAdmin(myUser.userRole),
              onTaskEdited: (Task task) async {
                await taskController.updateTask(task);

                setState(() {
                  tasksToShow[index] = task;
                  allTasks[allTasks.indexWhere((t) => t.id == task.id)] = task;
                  tasksToShow.sort((task1, task2) {
                    return TaskController.sortTask(sortType, task1, task2, taskAndUsersMAP);
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

  void openShowTask(Task task) {
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: viewTask(task, taskAndUsersMAP[task.id] ?? ''),
          ),
        );
      },
    );
  }

  Widget viewTask(Task task, String users) {
    users = users.replaceAll(AppStrings.USER_SEPARATOR, '\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.name, style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 20)),
        SizedBox(height: 20),
        Table(
          columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          children: [
            //buildTableRow('Nom:', task.name),
            tableRow('Descripció:', task.description),
            tableRow('Prioritat:', Priorities.priorityToString(task.priority)),
            tableRow('Data límit:', DateFormat('dd/MM/yyyy').format(task.limitDate)),
            tableRow('Estat:', task.state.name),
          ],
        ),

        Divider(height: 20),

        Text('Usuaris relacionats amb aquesta tasca:', style: TextStyle(fontWeight: FontWeight.bold)),
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

                    final isValid = await userController.userNameExists(userName);
                    if (!isValid) {
                      await userNotFoundMessage(AppStrings.NOTEXISTS_MESSAGE);
                      return;
                    }

                    final invited = await notController.taskInvitation(
                      userName,
                      task,
                      myUser.userName,
                      descriptionController.text,
                    );
                    if (!invited) {
                      await userNotFoundMessage(AppStrings.ALREADY_SHARED);
                      return;
                    }

                    Navigator.of(context).pop(true);
                  },
                  child: Text(AppStrings.CONFIRM),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(AppStrings.CANCEL),
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
              child: Text(AppStrings.ACCEPT),
            ),
          ],
        );
      },
    );
  }

  void openNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 30),

          child: SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: viewNotifications()),
        );
      },
    );
  }

  Widget viewNotifications() {
    return (notifications.isEmpty)
        ? Center(child: Text('No hi ha notificacions.'))
        : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return Card(
                color: Theme.of(context).colorScheme.inversePrimary,
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.all(5),

                  leading: Text('    ${index + 1}'),
                  title: Text(notification.message),
                  subtitle: Text(notification.description),

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
                            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return Colors.red;
                              }
                              return Colors.black54;
                            }),
                          ),
                          onPressed: () async {
                            await notController.deleteNotificationByID(notification.id);
                            //await notController.deleteNotificationInDatabase(index);
                            await notController.loadNotificationsFromDB(myUser.userName);
                            notifications = notController.notifications;
                            setState(() {});
                            Navigator.of(context).pop();
                          },
                        ),

                        //ACCEPTAR
                        IconButton(
                          tooltip: 'Acceptar tasca',
                          icon: Icon(Icons.check_circle, color: Colors.black54),
                          onPressed: () async {
                            await taskController.createRelation(notification.taskId, notification.userName);

                            Task newTask = await taskController.getTaskByID(notification.taskId);
                            await notController.deleteNotificationByID(notification.id);

                            notifications.removeAt(index);

                            //tasks.add(newTask);
                            addTask(newTask);
                            tasksToShow.sort((task1, task2) {
                              return TaskController.sortTask(sortType, task1, task2, taskAndUsersMAP);
                            });

                            await taskAndUsers();
                            setState(() {});

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

  Future<void> taskAndUsers() async {
    String users;
    taskAndUsersMAP.clear();
    for (Task task in tasksToShow) {
      users = await taskController.getUsersRelatedWithTask(task.id);

      if (taskAndUsersMAP.containsKey(task.id)) {
        logWarning('ID duplicat ${task.id}');
      } else {
        taskAndUsersMAP[task.id] = users;
      }
    }
  }

  void addTask(Task newTask) {
    bool contains = tasksToShow.any((task) => task.id == newTask.id);
    if (!contains) {
      setState(() {
        tasksToShow.add(newTask);
        allTasks.add(newTask);
      });
    }
    //taskAndUsersMAP[newTask.id] = myUser.userName;
  }

  Container taskSort() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(bottom: 10),

      child: PopupMenuButton(
        tooltip: 'Sobre quin element voleu ordenar',

        itemBuilder: (BuildContext context) => [
          _menuSortItem(Icons.error_outline_rounded, 'Prioritat', SortType.NONE),
          _menuSortItem(Icons.calendar_month_rounded, 'Data', SortType.DATE),
          _menuSortItem(Icons.text_fields_rounded, 'Nom', SortType.NAME),
          _menuSortItem(Icons.supervised_user_circle_rounded, 'Usuari', SortType.USER),
        ],
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12.0),
          ),

          child: Text('Ordenar', style: TextStyle(fontSize: 17)),
        ),
      ),
    );
  }

  Container userFilter() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(bottom: 10),

      child: PopupMenuButton(
        tooltip: 'Filtrar tasques per usuari',

        itemBuilder: (BuildContext context) => [
          for (String userName in allUserNames)
            PopupMenuItem(value: userName, child: Text(userName == myUser.userName ? 'Veure les meves' : userName)),
        ],

        onSelected: (userSelected) async {
          if (userSelected == AppStrings.SHOWALL) {
            //await taskController.loadAllTasksFromDB();
            //tasksToShow = allTasks.map((Task task) => Task.copy(task)).toList();
            _resetTasks();
          } else {
            tasksToShow = allTasks.where((Task line) => taskAndUsersMAP[line.id]!.contains(userSelected)).toList();
            //await taskController.loadTasksFromDB(userSelected);
          }
          //tasksToShow = taskController.tasks;
          setState(() {});
        },

        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12.0),
          ),

          child: Text('Usuaris', style: TextStyle(fontSize: 17)),
        ),
      ),
    );
  }

  Container taskFilter() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(bottom: 10),

      child: Tooltip(
        message: 'Filtrar tasques',

        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () => openFilterTask(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Text('Filtrar', style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container showAllTask() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(bottom: 10),

      child: Tooltip(
        message: 'Mostrar totes',

        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () {
                _resetTasks();
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Text('Treure filtres', style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /*PopupMenuItem _menuFilterItem(IconData icon, String label, TaskFilter filter) {
    return PopupMenuItem(
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
      onTap: () {
        openFilterTask(tasksToShow);
        setState(() {
          //TaskFilterPage filterTask(tasksToShow, filter);
        });
      },
    );
  }*/

  Future<void> openFilterTask() async {
    final filteredTasks = await showDialog<List<Task>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
          title: Text('Filtrar tasques'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [TaskFilterPage(tasks: tasksToShow, allTasks: allTasks)],
            ),
          ),
        );
      },
    );
    if (filteredTasks != null) {
      setState(() {
        tasksToShow = filteredTasks;
      });
    }
  }

  static TableRow tableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20), child: Text(value)),
      ],
    );
  }

  PopupMenuItem _menuSortItem(IconData icon, String label, SortType st) {
    return PopupMenuItem(
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
      onTap: () {
        setState(() {
          sortType = st;
          tasksToShow.sort((task1, task2) {
            return TaskController.sortTask(sortType, task1, task2, taskAndUsersMAP);
          });
        });
      },
    );
  }

  Row buttons(Task task, int index) {
    Color defaultColor = const Color.fromARGB(165, 0, 0, 0);
    //String tooltip = AppStrings.tooltipTextState(task.state);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: 'Editar',
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.blue.shade700;
              }
              return defaultColor;
            }),
          ),
          onPressed: () => openEditTask(task, index),
          icon: Icon(Icons.edit),
        ),
        IconButton(
          tooltip: 'Eliminar',
          onPressed: () => confirmDelete(index, task.id, false),
          icon: Icon(Icons.delete),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.red;
              }
              return defaultColor;
            }),
          ),
        ),
        IconButton(
          tooltip: 'Canviar estat (dels predeterminats)',
          icon: Icon(
            Icons.check_circle,
            /*color: TaskState.isDone(task.state)
                ? (task.limitDate.isBefore(DateTime.now()) ? Colors.green.shade400 : Colors.green.shade700)
                : null,*/
            color: stateController.getShade600(task.state.color),
          ),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.green.shade700;
              }
              return defaultColor;
            }),
          ),
          onPressed: () async {
            List<String> stateNames = AppStrings.DEFAULT_STATES;
            int index = 1;
            if (stateNames.contains(task.state.name)) {
              index = stateNames.indexOf(task.state.name) + 1;

              if (index == stateNames.length) {
                index = 0;
              }
            }
            task.state = stateController.getStateByName(stateNames[index]);
            await taskController.updateTask(task);
            setState(() {});
          },
        ),
      ],
    );
  }

  Color? backgroundColor(Task task) {
    if (task.limitDate.isBefore(DateTime.now())) {
      return Colors.red.shade300;
    } else {
      return stateController.getShade200(task.state.color);
    }
  }

  Color? textColor(Task task) {
    if (task.limitDate.isBefore(DateTime.now())) {
      return Colors.white;
    }
    return null;
  }

  void _resetTasks() {
    //tasksToShow = allTasks.map((Task task) => Task.copy(task)).toList();
    tasksToShow.clear();
    tasksToShow.addAll(allTasks);
  }
}
