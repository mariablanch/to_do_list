import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:to_do_list/controller/notification_controller.dart';
import 'package:to_do_list/controller/history_controller.dart';
import 'package:to_do_list/controller/state_controller.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/controller/team_controller.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/relation_tables/team_task.dart';
import 'package:to_do_list/model/notification.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/utils/const/firebase_options.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/priorities.dart';
import 'package:to_do_list/utils/roles.dart';
import 'package:to_do_list/utils/widgets.dart';
import 'package:to_do_list/utils/sort.dart';
import 'package:to_do_list/view_form/task_filter.dart';
import 'package:to_do_list/view_form/task_form.dart';
import 'package:to_do_list/config.dart';
import 'package:to_do_list/main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  User userProva = User(
    id: "yycmf4AXVmQ9aXANlZxe",
    name: "111",
    surname: "111",
    userName: "111",
    mail: "111",
    password: "f6e0a1e2ac41945a9aa7ff8a8aaa0cebc12a3bcc981a929ad5cf810a090e11ae",
    userRole: UserRole.ADMIN,
    deleted: false,
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
      title: "ToDoList - ${user.userName}",
      home: MyHomePageToDo(user: user),
      theme: ThemeData(
        colorScheme: (!UserRole.isAdmin(user.userRole))
            ? ColorScheme.fromSeed(seedColor: Colors.pink)
            : ColorScheme.fromSeed(seedColor: Colors.blue),
        //colorScheme: ColorScheme.fromSeed(seedColor: TaskState.colorMap.values.elementAt(Random().nextInt(TaskState.colorMap.length - 1) + 1)!),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale("en"), Locale("es")],
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

  List<Task> tasksToShow = [];
  List<Task> allTasks = [];
  bool showCompleted = true, isFiltering = false;

  List<Notifications> notifications = [];
  List<String> allUserNames = [];
  Map<String, String> taskAndUsersMAP = {};
  List<TeamTask> teamTask = [];

  NotificationController notController = NotificationController();
  TaskController taskController = TaskController();
  UserController userController = UserController();
  StateController stateController = StateController();
  TeamController teamController = TeamController();

  bool isLoading = true;

  Set<String> usersSelected = {};
  List<String> usersToShow = [];

  Set<String> teamsSelected = {};
  List<String> teamsToShow = [];

  @override
  void initState() {
    super.initState();
    myUser = widget.user;
    loadInitialData(UserRole.isAdmin(myUser.userRole));
  }

  //ScaffoldMessenger.of(context).showSnackBar(SnackBar())

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 500;
        return Scaffold(
          appBar: _appbar(),
          body: Container(
            margin: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [filterButtons(isCompact)],
                            ),
                          ),
                          shownTasks(),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: filterButtons(isCompact),
                            ),
                          ),
                          shownTasks(),
                        ],
                      ),

                SizedBox(height: 10),

                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : tasksToShow.isEmpty
                      ? Center(child: Text("No hi ha tasques."))
                      : taskList(isCompact),
                ),
              ],
            ),
          ),

          floatingActionButton: !isCompact
              ? FloatingActionButton.extended(
                  heroTag: "addTask",
                  onPressed: () => openForm(),
                  label: Text("Afegir tasca"),
                  icon: Icon(Icons.add),
                )
              : FloatingActionButton.extended(heroTag: "addTask", label: Icon(Icons.add), onPressed: () => openForm()),
        );
      },
    );
  }

  //VIEW
  AppBar _appbar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      automaticallyImplyLeading: false,

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
                  tooltip: "Notificacions",
                  onPressed: () {
                    openNotifications();
                  },
                  icon: (notifications.isEmpty)
                      ? Icon(Icons.notifications)
                      : Icon(Icons.notifications_active, color: Colors.red),
                ),

                PopupMenuButton(
                  icon: Icon(Icons.menu),
                  tooltip: "Menú",
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.settings, color: Colors.black54),
                          SizedBox(width: 8),
                          Text("Configuració"),
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
                          Text("Tancar sessió"),
                        ],
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyApp())),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget viewNotifications() {
    return (notifications.isEmpty)
        ? Center(child: Text("No hi ha notificacions."))
        : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return Card(
                color: Theme.of(context).colorScheme.inversePrimary,
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.all(5),

                  leading: Text("    ${index + 1}"),
                  title: Text(notification.message),
                  subtitle: Text(notification.description),

                  trailing: SizedBox(
                    width: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        //ELIMINAR
                        IconButton(
                          tooltip: "Eliminar",
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
                            await notController.loadNotificationsFromDB(myUser.id);
                            notifications = notController.notifications;
                            setState(() {});
                            Navigator.of(context).pop();
                          },
                        ),

                        //ACCEPTAR
                        IconButton(
                          tooltip: "Acceptar tasca",
                          icon: Icon(Icons.check_circle, color: Colors.black54),
                          onPressed: () async {
                            Task task = Task.empty();
                            task.id = notification.taskId;
                            await taskController.createUserTaskRelation(task, notification.user);

                            Task newTask = await taskController.getTaskByID(notification.taskId);
                            await notController.deleteNotificationByID(notification.id);

                            notifications.removeAt(index);

                            //tasks.add(newTask);
                            addTask(newTask);

                            await loadTaskAndUsers();
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

  Widget viewTask(Task task, String users, bool isCompact) {
    users = users.replaceAll(AppStrings.SEPARATOR, "\n");

    List<Team> teams = teamTask.where((tt) => tt.task == task).map((tt) => tt.team).toSet().toList();
    String teamsSTR = teamStr(task).replaceAll(AppStrings.SEPARATOR, "\n");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Text(task.name, style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 20)),
        //SizedBox(height: 20),
        Tables.viewTasks(task, Theme.of(context).colorScheme.inverseSurface),

        Divider(height: 20),

        Row(
          children: [
            Text("Usuaris relacionats amb aquesta tasca:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 10),

            if (!isCompact) shareTask(task),
          ],
        ),
        if (isCompact) shareTask(task),
        SizedBox(height: isCompact ? 20 : 5),
        Text(users),
        SizedBox(height: 20),

        Row(
          children: [
            Text("Equips relacionats amb aquesta tasca:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            if (!isCompact) shareTask(task, teams: teams),
          ],
        ),
        if (isCompact) shareTask(task, teams: teams),
        SizedBox(height: isCompact ? 20 : 5),
        Text(teamsSTR),
        SizedBox(height: 20),
      ],
    );
  }

  Widget taskList(bool isCompact) {
    return ListView.builder(
      itemCount: tasksToShow.length,
      itemBuilder: (context, index) {
        final task = tasksToShow[index];
        final hasPassedDate = isColorRed(task);

        return LayoutBuilder(
          builder: (context, constraints) {
            return Card(
              color: backgroundColor(task, hasPassedDate),

              shape: hasPassedDate
                  ? RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,

              elevation: 3,

              child: isCompact
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          openShowTask(task, isCompact);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(children: [Priorities.getIconPriority(task.priority, hasPassedDate)]),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.titleText(task),
                                      style: TextStyle(
                                        color: textColor(task, hasPassedDate),
                                        fontSize: Theme.of(context).textTheme.titleMedium!.fontSize! + 1,
                                        fontWeight: Theme.of(context).textTheme.titleMedium?.fontWeight,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      AppStrings.subtitleText(
                                        task.description,
                                        taskAndUsersMAP[task.id] ?? "",
                                        teamStr(task),
                                      ),
                                      style: TextStyle(color: textColor(task, hasPassedDate)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              buttons(task, index),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListTile(
                      leading: SizedBox(
                        height: 30,
                        width: 30,
                        child: Priorities.getIconPriority(task.priority, hasPassedDate),
                      ),

                      title: Text(AppStrings.titleText(task)),
                      subtitle: Text(
                        AppStrings.subtitleText(task.description, taskAndUsersMAP[task.id] ?? "", teamStr(task)),
                      ),

                      textColor: textColor(task, hasPassedDate),
                      trailing: SizedBox(width: 150, child: buttons(task, index)),
                      onTap: () => openShowTask(task, isCompact),
                    ),
            );
          },
        );
      },
    );
  }

  //OTHER
  static Color? backgroundColor(Task task, bool hasPassedDate) {
    if (hasPassedDate) {
      return Colors.red.shade300;
    } else {
      return StateController().getShade200(task.state.color);
    }
  }

  Color? textColor(Task task, bool hasPassedDate) {
    if (hasPassedDate) {
      return Colors.white;
    }
    return null;
  }

  bool isColorRed(Task task) {
    bool isDone = task.completedDate != null;
    if (isDone) {
      return task.limitDate.add(Duration(days: 1)).isBefore(task.completedDate!);
    } else {
      return task.limitDate.add(Duration(days: 1)).isBefore(DateTime.now());
    }
  }

  void _resetTasks() {
    allTasks.sort((task1, task2) {
      return TaskController.sortTask(sortType, task1, task2, taskAndUsersMAP);
    });
    tasksToShow.clear();
    tasksToShow.addAll(allTasks);

    if (!showCompleted) {
      tasksToShow.removeWhere((t) => t.state.id == stateController.getStateByName(AppStrings.DEFAULT_STATES[2]).id);
    }
  }

  /*static TableRow tableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20), child: Text(value)),
      ],
    );
  }*/

  void _endFilterTask(List<Task>? filteredTasks) {
    isFiltering = false;
    if (filteredTasks != null) {
      tasksToShow = filteredTasks;
    }
    setState(() {});
  }

  ElevatedButton shareTask(Task task, {List<Team>? teams}) {
    bool isTeam = teams != null;
    return ElevatedButton.icon(
      onPressed: () {
        !isTeam ? enterUserName(task) : selectTeamToShare(task, teams);
      },
      label: !isTeam ? Text("Compartir amb un altre usuari") : Text("Compartir amb un altre equip"),
    );
  }

  void addTask(Task newTask) {
    bool contains = tasksToShow.any((task) => task.id == newTask.id);
    if (!contains) {
      _resetTasks();
      tasksToShow.add(newTask);
      allTasks.add(newTask);
      tasksToShow.sort((task1, task2) {
        return TaskController.sortTask(sortType, task1, task2, taskAndUsersMAP);
      });
      allTasks.sort((task1, task2) {
        return TaskController.sortTask(sortType, task1, task2, taskAndUsersMAP);
      });
      setState(() {});
    }
    //taskAndUsersMAP[newTask.id] = myUser.userName;
  }

  Row buttons(Task task, int index) {
    Color defaultColor = const Color.fromARGB(165, 0, 0, 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: "Editar",
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
          tooltip: "Eliminar",
          onPressed: () async {
            await confirmDelete(index, task);
            setState(() {});
          },
          icon: Icon(Icons.delete),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.red;
              }
              return defaultColor;
            }),
          ),
        ),
        IconButton(
          tooltip: "Canviar estat (dels predeterminats)",
          icon: Icon(Icons.check_circle, color: stateController.getShade600(task.state.color)),
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
            int index = 0;
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

  //FILTER BUTTONS
  Row filterButtons(bool isCompact) {
    return Row(
      children: [
        taskSort(),
        Container(width: 10),
        if (UserRole.isAdmin(myUser.userRole)) userFilter(),
        if (UserRole.isAdmin(myUser.userRole)) Container(width: 10),
        taskFilter(isCompact),
        Container(width: 10),
        showAllTask(),
        Container(width: 10),
        showDoneTask(),
      ],
    );
  }

  Container taskSort() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(bottom: 10),

      child: PopupMenuButton(
        tooltip: "Sobre quin element voleu ordenar",

        itemBuilder: (BuildContext context) => [
          _menuSortItem(Icons.error_outline_rounded, "Prioritat", SortType.NONE),
          _menuSortItem(Icons.calendar_month_rounded, "Data", SortType.DATE),
          _menuSortItem(Icons.text_fields_rounded, "Nom", SortType.NAME),
          _menuSortItem(Icons.supervised_user_circle_rounded, "Usuari", SortType.USER),
        ],
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),

          child: Text("Ordenar", style: TextStyle(fontSize: 17)),
        ),
      ),
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

  Container userFilter() {
    allUserNames.insert(0, AppStrings.SHOWALL);
    allUserNames = allUserNames.toSet().toList();
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(bottom: 10),

      child: PopupMenuButton(
        tooltip: "Filtrar tasques per usuari",

        itemBuilder: (BuildContext context) => [
          for (String userName in allUserNames)
            PopupMenuItem(value: userName, child: Text(userName == myUser.userName ? "Veure les meves" : userName)),
        ],

        onSelected: (userSelected) {
          if (userSelected == AppStrings.SHOWALL) {
            _resetTasks();
          } else {
            tasksToShow = allTasks.where((t) => taskAndUsersMAP[t.id]!.contains(userSelected)).toList();
          }
          setState(() {});
        },

        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),

          child: Text("Usuaris", style: TextStyle(fontSize: 17)),
        ),
      ),
    );
  }

  Container taskFilter(bool isCompact) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(bottom: 10),

      child: Tooltip(
        message: "Filtrar tasques",

        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                isFiltering = true;
                setState(() {});
                isCompact ? openFilterTaskMBS() : openFilterTaskSD();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  //color: Theme.of(context).colorScheme.primaryContainer,
                  color: !isFiltering
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.inversePrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Filtrar", style: TextStyle(fontSize: 17)),
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
        message: "Mostrar totes",
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                sortType = SortType.NONE;
                _resetTasks();
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Treure filtres", style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container showDoneTask() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(bottom: 10),

      child: Tooltip(
        message: "Veure/amagar tasques completades",

        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                showCompleted = !showCompleted;
                _resetTasks();
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: !showCompleted
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.inversePrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Mostrar completades", style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //SHOW DIALOG - MODAL BOTTOM SHEET
  Future<void> openFilterTaskSD() async {
    final filteredTasks = await showDialog<List<Task>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
          //title: Text("Filtrar tasques"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TaskFilterPage(
                    tasks: tasksToShow,
                    allTasks: allTasks,
                    isMBS: false,
                    taskAndUsersMAP: taskAndUsersMAP,
                    allUserNames: allUserNames,
                    teamTask: teamTask,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    _endFilterTask(filteredTasks);
  }

  Future<void> openFilterTaskMBS() async {
    final filteredTasks = await showModalBottomSheet<List<Task>>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 30),

          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
              child: TaskFilterPage(
                tasks: tasksToShow,
                allTasks: allTasks,
                isMBS: true,
                taskAndUsersMAP: taskAndUsersMAP,
                allUserNames: allUserNames,
                teamTask: teamTask,
              ),
            ),
          ),
        );
      },
    );
    _endFilterTask(filteredTasks);
  }

  confirmDelete(int index, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar tasca"),
          content: Text("Estàs segur que vols continuar?"),
          actions: <Widget>[
            /*TextButton(
              onPressed: () async {
                List<String> taskUsers = taskAndUsersMAP.containsKey(taskId)
                    ? taskAndUsersMAP[taskId]!
                          .split(AppStrings.SEPARATOR)
                          .map((u) => u.trim())
                          .where((u) => u != "")
                          .toList()
                    : [];

                List<String> taskTeam = teamTask.any((tt) => tt.task.id == taskId)
                    ? teamTask.where((tt) => tt.task.id == taskId).map((tt) => tt.team.name.trim()).toList()
                    : [];

                if (taskTeam.isEmpty && taskUsers.isNotEmpty) {
                  if (UserRole.isAdmin(myUser.userRole) && taskUsers.length > 1) {
                    bool confirmed = await selectTeamsAndUsersToDeleteTask(taskId, allUsers: taskUsers, allTeams: []);
                    if (confirmed) {
                      await _deleteUsersFromTask(taskId);

                      Navigator.of(context).pop();
                      setState(() {});
                    }
                  } else {
                    await taskController.removeTaskUser(taskId, myUser.userName);
                    //tasksToShow.removeAt(index);
                    //allTasks.removeWhere((task) => task.id == taskId);
                    await _deleteUsersFromTask(taskId);
                    Navigator.of(context).pop();
                    setState(() {});
                  }
                } else if (taskUsers.isEmpty && taskTeam.isNotEmpty) {
                  //SELECCIONAR EQUIPS
                  bool confirmed = await selectTeamsAndUsersToDeleteTask(taskId, allTeams: taskTeam, allUsers: []);
                  if (confirmed) {
                    await _deleteTeamsFromTask(taskId);
                    Navigator.of(context).pop();
                    setState(() {});
                  }
                  if (UserRole.isAdmin(myUser.userRole) && taskTeam.length > 1) {}
                } else if (taskUsers.isNotEmpty && taskTeam.isNotEmpty) {
                  bool confirmed = await selectTeamsAndUsersToDeleteTask(
                    taskId,
                    allTeams: taskTeam,
                    allUsers: taskUsers,
                  );
                  if (confirmed) {
                    await _deleteTeamsFromTask(taskId);
                    await _deleteUsersFromTask(taskId);

                    Navigator.of(context).pop();
                    setState(() {});
                  }
                  //logToDo("triar equip I usuari", "ToDoPage(confirmDelete)");

                  //SELECCIONAR EQUIPS I USUARIS
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
            */
            TextButton(
              onPressed: () async {
                await taskController.disableTask(task);
                await HistoryController.deleteTask(task, myUser);
                Navigator.of(context).pop();
                task = task.copyWith(deleted: true);
                allTasks.removeWhere((tsk) => tsk.id == task.id);
                _resetTasks();
                setState(() {});
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
              child: Text(AppStrings.ACCEPT),
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

  Future<bool> selectTeamsAndUsersToDeleteTask(
    String taskId, {
    required List<String> allTeams,
    required List<String> allUsers,
  }) async {
    bool teams = allTeams.isNotEmpty, users = allUsers.isNotEmpty;
    bool teamsAndUsers = teams && users;
    bool ret = false, loading = false;

    if (teams) {
      teamsSelected.clear();
      teamsToShow = allTeams;
      if (teamsToShow.length > 5) {
        teamsToShow = teamsToShow.getRange(0, 5).toList();
      }
    }
    if (users) {
      usersSelected.clear();
      usersToShow = allUsers;
      if (usersToShow.length > 5) {
        usersToShow = usersToShow.getRange(0, 5).toList();
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(
                teamsAndUsers
                    ? "Equips i Usuaris"
                    : teams
                    ? "Equips"
                    : "Usuaris",
              ),
              content: SingleChildScrollView(
                child: loading
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (users) ...[
                            Text("Seleccioneu els usuaris als que voleu eliminar la tasca"),
                            SizedBox(height: 10),
                            TextField(
                              decoration: InputDecoration(labelText: "Buscar", border: OutlineInputBorder()),
                              onChanged: (value) {
                                //value.toLowerCase();
                                usersToShow = allUsers
                                    .where((u) => u.toLowerCase().contains(value.toLowerCase()))
                                    .toList();
                                if (usersToShow.length > 5) {
                                  usersToShow = usersToShow.getRange(0, 5).toList();
                                }
                                setStateDialog(() {});
                              },
                            ),
                            SizedBox(height: 10),
                            for (String userName in usersToShow)
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
                          if (teamsAndUsers) SizedBox(height: 10),
                          if (teams) ...[
                            Text("Seleccioneu els equips als que voleu eliminar la tasca"),
                            SizedBox(height: 10),
                            TextField(
                              decoration: InputDecoration(labelText: "Buscar", border: OutlineInputBorder()),
                              onChanged: (value) {
                                //value.toLowerCase();
                                teamsToShow = allTeams
                                    .where((u) => u.toLowerCase().contains(value.toLowerCase()))
                                    .toList();
                                if (teamsToShow.length > 5) {
                                  teamsToShow = teamsToShow.getRange(0, 5).toList();
                                }
                                setStateDialog(() {});
                              },
                            ),
                            SizedBox(height: 10),
                            for (String team in teamsToShow)
                              Row(
                                children: [
                                  Checkbox(
                                    value: teamsSelected.contains(team),
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        if (value == true) {
                                          teamsSelected.add(team);
                                        } else {
                                          teamsSelected.remove(team);
                                        }
                                      });
                                    },
                                  ),
                                  Text(team),
                                ],
                              ),
                          ],
                        ],
                      ),
              ),

              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    setStateDialog(() {
                      loading = true;
                    });

                    if (teams && teamsSelected.isNotEmpty) {
                      for (String team in teamsSelected) {
                        //await taskController.removeTeam(taskId, team);
                        if (team == "") {}
                        logToDo("Eliminar team de task", "ToDoPage(slectTeamsAndUsersToDeleteTask)");
                      }
                      ret = true;
                    }
                    if (users && usersSelected.isNotEmpty) {
                      for (String userName in usersSelected) {
                        //await taskController.removeTaskUser(taskId, userName);
                        if (userName == "") {}
                        logToDo("Eliminar user de task", "ToDoPage(slectTeamsAndUsersToDeleteTask)");
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

  Future<void> deleteUsersFromTask(String taskId) async {
    await loadTaskAndUsers();
    bool taskHasTeam = teamTask.any((tt) => tt.task.id == taskId);
    if (!taskHasTeam) {
      //SI NO TE EQUIPS MIRAR SI TÉ USUARIS
      if (taskAndUsersMAP.containsKey(taskId)) {
        if (taskAndUsersMAP[taskId]!.split(AppStrings.SEPARATOR).map((u) => u.trim()).where((u) => u != "").isEmpty) {
          //SI NO TE USUARIS ELIMINAR
          allTasks.removeWhere((task) => task.id == taskId);
          _resetTasks();
          taskAndUsersMAP.remove(taskId);
        }
      }
    }
  }

  Future<void> deleteTeamsFromTask(String taskId) async {
    teamTask = await teamController.loadTeamTask(false);
    await loadTaskAndUsers();
    //MIRAR SI TÉ USUARIS:
    if (taskAndUsersMAP[taskId]!.split(AppStrings.SEPARATOR).map((u) => u.trim()).where((u) => u != "").isEmpty) {
      //SI NO TÉ USUARIS ELIMINAR
      if (!teamTask.any((tt) => tt.task.id == taskId)) {
        //ENTRA NOMES SI *NO* TÉ CAP TEAM LA TASK
        allTasks.removeWhere((task) => task.id == taskId);
        _resetTasks();
      }
    }
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
                tasksToShow[index] = task;
                allTasks[allTasks.indexWhere((t) => t.id == task.id)] = task;
                tasksToShow.sort((task1, task2) {
                  return TaskController.sortTask(sortType, task1, task2, taskAndUsersMAP);
                });
                allTasks.sort((task1, task2) {
                  return TaskController.sortTask(sortType, task1, task2, taskAndUsersMAP);
                });

                await HistoryController.updateTask(taskToEdit, task, myUser);
                setState(() {});
              },
              task: taskToEdit,
            ),
          ),
        );
      },
    );
  }

  void openShowTask(Task task, bool isCompact) {
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
            child: viewTask(task, taskAndUsersMAP[task.id] ?? "", isCompact),
          ),
        );
      },
    );
  }

  Future<bool> enterUserName(Task task) async {
    final TextEditingController userNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    allUserNames.removeWhere((str) => str == AppStrings.SHOWALL);

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Compartir Tasca"),
          actions: <Widget>[
            Row(children: [Text("Nom d'usuari a qui es vol compartir")]),

            Autocomplete<String>(
              displayStringForOption: (user) => user,

              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                return allUserNames.where((u) => u.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },

              onSelected: (String selection) {
                setState(() {
                  userNameController.text = selection;
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

            SizedBox(height: 10),

            Row(children: [Text("Descripció")]),
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

                    User u = await userController.getUserByUserName(userName);

                    final invited = await notController.taskInvitation(
                      u,
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

  Future<bool> selectTeamToShare(Task task, List<Team> teams) async {
    final TextEditingController teamNameController = TextEditingController();
    allUserNames.removeWhere((str) => str == AppStrings.SHOWALL);

    await teamController.loadAllTeamsWithUsers();
    List<String> allTeams = teamController.allTeamsAndUsers.keys.map((t) => t.name).toList();
    allTeams.removeWhere((t) => teams.map((tm) => tm.name).contains(t));

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Compartir Tasca"),
          actions: <Widget>[
            Row(children: [Text("Nom del equip a qui es vol compartir")]),

            Autocomplete<String>(
              displayStringForOption: (team) => team,

              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                return allTeams.where((u) => u.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },

              onSelected: (String selection) {
                setState(() {
                  teamNameController.text = selection;
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

            SizedBox(height: 10),

            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    Team team = teamController.allTeamsAndUsers.keys.firstWhere(
                      (t) => t.name == teamNameController.text,
                    );
                    TeamTask tt = TeamTask(team: team, task: task, id: "", deleted: false);
                    taskController.addTaskToTeam(tt);
                    teamTask.add(tt);
                    setState(() {});
                    Navigator.of(context).pop(true);
                    Navigator.of(context).pop();
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
                onTaskCreated: (task, users, teams) async {
                  String usersToAdd = "";
                  bool created = false;
                  if (UserRole.isAdmin(myUser.userRole)) {
                    if (users.isNotEmpty) {
                      await taskController.addTaskToDataBaseUser(task, users.first, myUser);
                      usersToAdd += users.first.userName;
                      users.remove(users.first);
                      if (users.isNotEmpty) {
                        for (User user in users) {
                          await taskController.createUserTaskRelation(task, user);
                          usersToAdd += "${AppStrings.SEPARATOR}${user.userName}";
                        }
                      }
                      taskAndUsersMAP[task.id] = usersToAdd;
                      created = true;
                    }

                    if (teams.isNotEmpty) {
                      TeamTask tt = TeamTask(team: teams.first, task: task, id: "", deleted: false);
                      if (!created) {
                        await taskController.addTaskToDataBaseTeam(tt);
                      } else {
                        await taskController.addTaskToTeam(tt);
                      }
                      teamTask.add(tt);
                      teams.remove(teams.first);
                      for (Team team in teams) {
                        tt = TeamTask(team: team, task: task, id: "", deleted: false);
                        await taskController.addTaskToTeam(tt);
                        teamTask.add(tt);
                      }
                    }
                  } else {
                    await taskController.addTaskToDataBaseUser(task, myUser, myUser);
                    taskAndUsersMAP[task.id] = myUser.userName;
                  }

                  addTask(task);
                  setState(() {
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

  //STRING - LABELS
  String teamStr(Task tsk) {
    List<Team> teams = teamTask.where((tt) => tt.task == tsk).map((tt) => tt.team).toSet().toList();
    String teamsSTR = "";
    if (teams.isNotEmpty) {
      teamsSTR = teams.first.name;
      teams.removeAt(0);
    }
    if (teams.isNotEmpty) {
      for (var t in teams) {
        teamsSTR += AppStrings.SEPARATOR + t.name;
      }
    }
    return teamsSTR;
  }

  Text shownTasks() {
    return Text(AppStrings.shownTasks(tasksToShow.length));
  }

  //LOAD
  Future<void> loadTaskAndUsers() async {
    taskAndUsersMAP.clear();
    taskAndUsersMAP.addAll(await loadUserTask());
  }

  static Future<Map<String, String>> loadUserTask() async {
    Map<String, String> ret = {};
    TaskController tk = TaskController();
    await tk.loadAllTasksFromDB(false);

    List<Task> allTasks = tk.tasks;
    String users;

    for (Task task in allTasks) {
      users = await tk.getUsersRelatedWithTask(task.id);
      if (ret.containsKey(task.id)) {
        logWarning("ID duplicat ${task.id}");
      } else {
        ret[task.id] = users;
      }
    }

    return ret;
  }

  Future<void> loadInitialData(bool allTask) async {
    setState(() {
      isLoading = true;
    });
    if (allTask) {
      await taskController.loadAllTasksFromDB(false);
      await notController.loadALLNotificationsFromDB();
    } else {
      await taskController.loadTasksFromDB(myUser.id);
      await notController.loadNotificationsFromDB(myUser.id);
    }
    await stateController.loadAllStates();

    teamTask = await teamController.loadTeamTask(false);

    notifications = notController.notifications;

    allTasks = taskController.tasks;
    _resetTasks();

    allUserNames = (await userController.loadAllUsers(false)).map((User user) => user.userName).toSet().toList();
    allUserNames.sort();

    await loadTaskAndUsers();

    setState(() {
      isLoading = false;
    });
  }
}
