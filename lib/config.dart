import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

import 'package:to_do_list/controller/history_controller.dart';
import 'package:to_do_list/controller/state_controller.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/controller/team_controller.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/relation_tables/team_task.dart';
import 'package:to_do_list/model/relation_tables/user_task.dart';
import 'package:to_do_list/model/relation_tables/user_team.dart';
import 'package:to_do_list/model/notification.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/model/history.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/firebase_options.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/interfaces.dart';
import 'package:to_do_list/utils/user_role_team.dart';
import 'package:to_do_list/utils/history_enums.dart';
import 'package:to_do_list/utils/user_role.dart';
import 'package:to_do_list/utils/widgets.dart';
import 'package:to_do_list/utils/sort.dart';
import 'package:to_do_list/view_form/state_form.dart';
import 'package:to_do_list/view_form/team_form.dart';
import 'package:to_do_list/to_do_page.dart';
import 'package:to_do_list/main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /*User userProva = User.parameter(
    "111",
    "111",
    "111",
    "111",
    "f6e0a1e2ac41945a9aa7ff8a8aaa0cebc12a3bcc981a929ad5cf810a090e11ae",
    UserRole.ADMIN,
  );*/
  User userProva = User(
    id: "yycmf4AXVmQ9aXANlZxe",
    name: "111",
    surname: "111",
    userName: "111",
    mail: "111",
    password: "f6e0a1e2ac41945a9aa7ff8a8aaa0cebc12a3bcc981a929ad5cf810a090e11ae",
    userRole: UserRole.ADMIN,
    deleted: false,
    iconName: Icon(User.getRandomIcon()),
  );
  runApp(MyAppConfig(user: userProva));
}

class MyAppConfig extends StatelessWidget {
  final User user;
  const MyAppConfig({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Configuració",
      home: ConfigHP(user: user),
      theme: ThemeData(
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        colorScheme: (!UserRole.isAdmin(user.userRole))
            ? ColorScheme.fromSeed(seedColor: Colors.deepPurple)
            : ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
    );
    //return ConfigHP(user: user);
  }
}

class ConfigHP extends StatefulWidget {
  final User user;
  const ConfigHP({super.key, required this.user});

  @override
  State<ConfigHP> createState() => ConfigPage();
}

class ConfigPage extends State<ConfigHP> {
  int selectedIndex = 0;
  late User myUser;
  bool viewList = true,
      userEdit = false,
      isUserAdmin = false,
      isTeamAdmin = false,
      isViewTeam = true,
      isAddToTeam = true,
      showOnlyDeleted = false;
  late bool isAdmin;
  User editUser = User.empty();
  Team editTeam = Team.empty();

  String iconSelected = "person";

  //List<Widget> get pages => [profilePage(), editAccountPage(), teamsPage(false), deleteAccountPage()];
  List<String> get labels => [
    AppStrings.PROFILE,
    AppStrings.CONFIG,
    if (isAdmin) AppStrings.USERS_LABEL,
    if (isAdmin) AppStrings.TASKSTATES,
    if (isAdmin) AppStrings.TEAMS_LABEL,
    AppStrings.MY_TEAMS,
    if (isAdmin) AppStrings.TASKS,
    if (isAdmin) AppStrings.HISTORY,
    AppStrings.DELETEACC,
  ];
  List<IconData> get icons => [
    Icons.person,
    Icons.settings,
    if (isAdmin) Icons.people,
    if (isAdmin) Icons.style,
    if (isAdmin) Icons.groups_2,
    Icons.group_work,
    if (isAdmin) Icons.task,
    if (isAdmin) Icons.history,
    Icons.delete,
  ];
  List<Widget> get pages => [
    profilePage(),
    editAccountPage(),
    if (isAdmin) usersPage(),
    if (isAdmin) statePage(),
    if (isAdmin) teamsPage(true),
    teamsPage(false),
    if (isAdmin) taskPage(),
    if (isAdmin) historyPage(),
    deleteAccountPage(),
  ];
  List<Widget> get pagess => [
    if (isAdmin) historyPage(),
    profilePage(),
    editAccountPage(),
    if (isAdmin) usersPage(),
    if (isAdmin) statePage(),
    if (isAdmin) teamsPage(true),
    teamsPage(false),
    if (isAdmin) taskPage(),
    deleteAccountPage(),
  ];

  UserController userController = UserController();
  List<User> allUsers = [];
  List<TaskState> states = [];
  StateController stateController = StateController();
  TeamController teamController = TeamController();
  TaskController taskController = TaskController();

  bool addMembers = false;

  Map<String, List<Task>> tasksFromUsers = {};
  Map<Team, List<UserTeam>> teamsAndUsers = {};
  Map<Team, List<UserTeam>> myTeams = {};
  Map<Team, List<Task>> tasksFromTeams = {};
  List<Task> allTasks = [];
  Map<History, BaseEntity> history = {};

  Set<User> usersAdded = {};

  TextEditingController userNameController = TextEditingController(),
      nameController = TextEditingController(),
      surnameController = TextEditingController(),
      mailController = TextEditingController(),
      passwordController = TextEditingController();

  String? stateSTR = "";
  String filter = "";

  late bool isWide, isTall;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    isWide = MediaQuery.of(context).size.width > 800;
    isTall = MediaQuery.of(context).size.height > 600;

    return Scaffold(
      appBar: isWide
          ? AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(AppStrings.CONFIG))
          : AppBar(
              title: Text(AppStrings.CONFIG),
              actions: [
                Builder(
                  builder: (context) =>
                      IconButton(icon: Icon(Icons.menu), onPressed: () => Scaffold.of(context).openEndDrawer()),
                ),
              ],
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
      endDrawer: isWide
          ? null
          : Drawer(
              child: ListView(
                children: labels.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final String label = entry.value;
                  return _drawerItem(label, index);
                }).toList(),
                /*_drawerItem(AppStrings.PROFILE, 0),
                  _drawerItem(AppStrings.CONFIG, 1),
                  if (isAdmin) _drawerItem(AppStrings.USERS_LABEL, 2),
                  if (isAdmin) _drawerItem(AppStrings.TASKSTATES, 3),
                  if (isAdmin) _drawerItem(AppStrings.TEAMS_LABEL, 4),
                  _drawerItem(AppStrings.MY_TEAMS, isAdmin ? 5 : 2),
                  if (isAdmin) _drawerItem(AppStrings.TASKS, 6),
                  _drawerItem(AppStrings.DELETEACC, isAdmin ? 7 : 3),*/
              ),
            ),
      body: Row(
        children: [
          if (isWide)
            LayoutBuilder(
              builder: (context, constraints) {
                final rail = NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (int index) {
                    pageChanged(index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: labels.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final String label = entry.value;
                    return _railItem(icons[index], label);
                  }).toList(),
                  /* [
                    
                    _railItem(Icons.person, AppStrings.PROFILE),
                    _railItem(Icons.settings, AppStrings.CONFIG),
                    _railItem(Icons.people, AppStrings.USERS_LABEL),
                    _railItem(Icons.style, AppStrings.TASKSTATES),
                    _railItem(Icons.groups_2, AppStrings.TEAMS_LABEL),
                    _railItem(Icons.group_work, AppStrings.MY_TEAMS),
                    _railItem(Icons.task, AppStrings.TASKS),
                    _railItem(Icons.history, AppStrings.HISTORY),
                    _railItem(Icons.delete, AppStrings.DELETEACC),
                  ],*/
                );

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(child: rail),
                  ),
                );
              },
            ),
          if (isWide) VerticalDivider(width: 10),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(30), child: pages[selectedIndex]),
          ),
        ],
      ),
    );
  }

  // PROFILE PAGE
  Widget profilePage() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*Text(
              AppStrings.PROFILE.toUpperCase(),
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
            ),*/
            pageLabel(AppStrings.PROFILE.toUpperCase()),
            SizedBox(height: 20),
            Tables.viewUsers(myUser, false),
          ],
        ),
      ),
    );
  }

  // CONFIG PAGE
  Widget editAccountPage() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        //padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Text("EDITAR PERFIL", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20)),
            pageLabel(AppStrings.EDIT_PROFILE.toUpperCase()),

            SizedBox(height: 20),
            editAccount(editUser, false),
          ],
        ),
      ),
    );
  }

  Form editAccount(User editUser, bool isNew) {
    final formKey = GlobalKey<FormState>();

    // false si el usuari es igual (s edita a ell mateix)
    // true si es diferent (edita a algu altre ==> restablir contrasenya)
    bool adminEdit = editUser.userName.compareTo(myUser.userName) != 0;

    String name = editUser.name;
    String surname = editUser.surname;
    String userName = editUser.userName;
    String mail = editUser.mail;
    String password = editUser.password;

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        //padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: TextFormField(
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Nom"),
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Aquest camp és obligatori";
                  }
                  return null;
                },
                onSaved: (value) {
                  name = value!;
                },
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: TextFormField(
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Cognom"),
                controller: surnameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Aquest camp és obligatori";
                  }
                  return null;
                },
                onSaved: (value) {
                  surname = value!;
                },
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: TextFormField(
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Nom d'usuari"),
                controller: userNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Aquest camp és obligatori";
                  }
                  return null;
                },
                onSaved: (value) {
                  userName = value!;
                },
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: TextFormField(
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Correu"),
                controller: mailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Aquest camp és obligatori";
                  } else if (!(value.contains("@") && value.contains("."))) {
                    return "No té el format adequat";
                  }
                  return null;
                },
                onSaved: (value) {
                  mail = value!;
                },
              ),
            ),

            if (!adminEdit && !isNew)
              Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                child: TextFormField(
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Nova contrasenya"),
                  obscureText: true,
                  //controller: paswordController,
                  validator: (value) {
                    if (isNew && (value == null || value.isEmpty)) {
                      return "Aquest camp és obligatori";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    password = value!;
                  },
                ),
              ),
            Container(height: 5),

            if (isNew) Text("La contrasenya és generada automaticament", style: TextStyle(fontSize: 14)),

            Container(height: 5),

            //if (isAdmin && editUser.userName != myUser.userName && !isNew)
            if (adminEdit && !isNew)
              Row(
                children: [
                  Text("Permisos d'administrador"),

                  Container(width: 10),

                  Switch(
                    //value: UserRole.isAdmin(editUser.userRole),
                    value: isUserAdmin,
                    onChanged: (bool value) async {
                      isUserAdmin = value;
                      setState(() {});
                    },
                  ),
                ],
              ),

            if (!isNew)
              Row(
                children: [
                  Text("Icona"),

                  Container(width: 10),

                  DropdownButton<String>(
                    value: iconSelected,
                    hint: Icon(Icons.person),
                    items: User.iconMap.keys.map((String iconName) {
                      return DropdownMenuItem<String>(value: iconName, child: Icon(User.iconMap[iconName]));
                    }).toList(),
                    onChanged: (String? newValue) {
                      iconSelected = newValue!;
                      setState(() {});
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return User.iconMap.keys.map((String iconName) {
                        return Icon(User.iconMap[iconName]);
                      }).toList();
                    },
                    menuMaxHeight: 300,
                  ),
                ],
              ),

            Container(
              margin: EdgeInsets.symmetric(vertical: 20),

              child: ElevatedButton.icon(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    bool usernameExists = await userController.userNameExists(userName);

                    if (userName != editUser.userName && usernameExists) {
                      nameExists("usuari");
                    } else if (isNew) {
                      User user = editUser.copyWith(
                        name: name,
                        surname: surname,
                        userName: userName,
                        mail: mail,
                        password: AppStrings.DEFAULT_PSWRD,
                      );

                      await userController.createAccountDB(user, myUser);
                      await _loadUsers(true);

                      Navigator.pop(context);
                    } else {
                      bool confirmPswrd = await confirmPasword(false);

                      if (confirmPswrd) {
                        bool isEmpty = password.isEmpty;
                        String pswrd = (adminEdit || isEmpty) ? editUser.password : User.hashPassword(password);
                        bool ur = false;
                        if (isAdmin) {
                          if (myUser.userName == editUser.userName) {
                            ur = true;
                          } else {
                            ur = isUserAdmin;
                          }
                        }

                        User updatedUser = editUser.copyWith(
                          name: name,
                          surname: surname,
                          userName: userName,
                          mail: mail,
                          password: pswrd,
                          //userRole: UserRole.getUserRole(isUserAdmin),
                          userRole: UserRole.getUserRole(ur),
                          icon: Icon(User.iconMap[iconSelected]),
                        );

                        await userController.updateProfileDB(updatedUser, editUser, myUser);
                        setState(() {
                          viewList = true;
                          userEdit = false;
                        });

                        if (!adminEdit) {
                          Navigator.pop(context, updatedUser);
                        } else {
                          await _loadUsers(true);
                        }
                      }
                    }
                  }
                },
                label: Text(!isNew ? "Guardar canvis" : "Crear compte"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //USERS PAGE
  Widget usersPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!viewList)
              IconButton(
                onPressed: () {
                  setState(() {
                    viewList = true;
                    filter = "";
                  });
                },
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
              ),

            /*Text(
              viewList ? AppStrings.USERS_LABEL.toUpperCase() : editUser.userName,
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
            ),*/
            pageLabel(viewList ? AppStrings.USERS_LABEL.toUpperCase() : editUser.userName),
          ],
        ),

        SizedBox(height: 20),

        viewList ? userList() : Expanded(child: viewUser(userEdit, editUser)),

        if (viewList)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: FloatingActionButton.extended(
              heroTag: "createUser",
              onPressed: () async {
                await openFormCreateUser(User.empty());
                await _loadUsers(true);
              },
              label: Text("Crear Usuari"),
              icon: Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Expanded userList() {
    return Expanded(
      child: ListView.builder(
        itemCount: allUsers.isEmpty ? 0 : allUsers.length,
        itemBuilder: (context, index) {
          final user = allUsers[index];
          if (user == myUser) {
            return SizedBox();
          }

          return Card(
            color: user.deleted ? Colors.black54 : null,
            child: ListTile(
              textColor: user.deleted ? Colors.white : null,
              iconColor: user.deleted ? Colors.white : null,

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.all(5),

              leading: SizedBox(width: 35, child: user.icon),
              title: Text(user.userName),
              subtitle: Text("${user.name} ${user.surname}"),

              trailing: SizedBox(
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: "Veure dades",
                      onPressed: () async {
                        //await taskController.loadTasksFromDB(allUsers[index].userName);
                        setState(() {
                          viewList = false;
                          userEdit = false;
                          editUser = allUsers[index];
                        });
                      },
                      icon: Icon(Icons.remove_red_eye),
                    ),
                    IconButton(
                      tooltip: "Editar",
                      onPressed: () {
                        setState(() {
                          editUser = allUsers[index];
                          iconSelected = User.iconMap.entries.firstWhere((e) => e.value == editUser.icon.icon).key;
                          viewList = false;
                          userEdit = true;
                          isUserAdmin = UserRole.isAdmin(editUser.userRole);
                          clear();
                          controllersFromUser(editUser);
                        });
                      },
                      icon: Icon(Icons.edit),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget viewUser(bool edit, User user) {
    List<Task> tasks = [];

    if (tasksFromUsers.containsKey(user.userName)) {
      tasks = tasksFromUsers[user.userName]!;
    }

    return edit
        ? editAccount(user, false)
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tables.viewUsers(user, true),

                Container(height: 10),
                //Text("------------------------------------------------", style: TextStyle(fontWeight: FontWeight.bold)),
                //Divider(height: 20, endIndent: 1000),
                SizedBox(height: 30, width: 500, child: Divider(thickness: 2)),

                Container(height: 10),

                Table(
                  columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                  children: [
                    Tables.tableRow2(
                      "Tasques de l'usuari:",
                      tasks.isEmpty ? "Aquest usuari no té tasques assignades." : tasks.first.name,
                    ),
                    for (Task task in tasks.skip(1).toList()) Tables.tableRow2("", task.name),
                  ],
                ),

                Container(height: 30),

                ElevatedButton(
                  onPressed: () async {
                    final isUserName = await confirmUserName(user.userName);
                    if (isUserName) {
                      userController.resetPswrd(user);
                    }
                  },
                  child: Text("Reiniciar contrasenya"),
                ),

                Container(height: 15),

                ElevatedButton(
                  onPressed: () async {
                    if (await confirmPasword(true)) {
                      await userController.deleteUser(user);

                      int pos = allUsers.indexOf((user));

                      setState(() {
                        allUsers.removeAt(pos);
                        viewList = true;
                      });
                    }
                  },
                  child: Text("Eliminar usuari"),
                ),
              ],
            ),
          );
  }

  //STATE PAGE
  Widget statePage() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [pageLabel(AppStrings.TASKSTATES.toUpperCase())]),

              SizedBox(height: 20),
              taskStateList(),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: FloatingActionButton.extended(
                  heroTag: "createState",
                  onPressed: () {
                    openFormCreateState(true, TaskState.empty());
                  },
                  label: Text("Crear nou estat"),
                  icon: Icon(Icons.add),
                ),
              ),
            ],
          );
  }

  Expanded taskStateList() {
    return Expanded(
      child: ListView.builder(
        itemCount: states.length,
        itemBuilder: (context, index) {
          final state = states[index];
          bool canDelete = AppStrings.DEFAULT_STATES.contains(state.name);

          return Card(
            color: stateController.getShade200(state.color),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.all(5),

              title: SizedBox(child: Row(children: [SizedBox(width: 15), Text(state.name)])),
              trailing: SizedBox(
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: canDelete ? "No editable" : "Editar estat",
                      child: MouseRegion(
                        cursor: canDelete ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: !canDelete ? () => openFormCreateState(false, state) : null,
                          child: Icon(Icons.edit, color: !canDelete ? null : Colors.grey),
                        ),
                      ),
                    ),

                    SizedBox(width: 10),

                    Tooltip(
                      message: canDelete ? "No editable" : "Editar estat",
                      child: MouseRegion(
                        cursor: canDelete ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: !canDelete
                              ? () async {
                                  bool contains = tasksFromUsers.values.any((list) {
                                    return list.any((task) => task.state.id == state.id);
                                  });

                                  bool isValid = await deleteState(state);
                                  TaskState tState = TaskState.empty();
                                  if (isValid) {
                                    if (contains) {
                                      tState = await choseState(state);
                                    }
                                    stateController.deleteState(state.id, tState);
                                    states.remove(state);
                                    setState(() {});
                                  }
                                }
                              : null,
                          child: Icon(Icons.delete, color: !canDelete ? null : Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  //TEAMS PAGE
  Widget teamsPage(bool admin) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!viewList)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          viewList = true;
                          filter = "";
                        });
                      },
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
                    ),

                  pageLabel(
                    viewList
                        ? (admin ? AppStrings.TEAMS_LABEL.toUpperCase() : AppStrings.MY_TEAMS.toUpperCase())
                        : editTeam.name,
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (!viewList && isTeamAdmin) editTeamButton(),

              SizedBox(height: 10),

              viewList ? teamList(admin) : Expanded(child: viewTeam(editTeam, admin)),

              if (viewList)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: FloatingActionButton.extended(
                    heroTag: "createTeam",
                    onPressed: () async {
                      openFormCreateTeam(Team.empty(), true);
                    },
                    label: Text("Crear Equip"),
                    icon: Icon(Icons.add),
                  ),
                ),
            ],
          );
  }

  Expanded teamList(bool allteams) {
    return Expanded(
      child: GridView.builder(
        itemCount: allteams ? teamsAndUsers.length : myTeams.length,
        itemBuilder: (context, index) {
          var teamKey = allteams ? teamsAndUsers.keys.elementAt(index) : myTeams.keys.elementAt(index);
          final users = allteams ? teamsAndUsers[teamKey] : myTeams[teamKey];

          return Card(
            child: InkWell(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return Theme.of(context).colorScheme.primaryContainer;
                }
                return null;
              }),
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  viewList = false;
                  isViewTeam = true;
                  editTeam = teamKey;
                  isTeamAdmin = allteams
                      ? true
                      : TeamRole.isAdmin(teamsAndUsers[editTeam]!.firstWhere((u) => u.user == myUser).role);
                  usersAdded.clear();
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(teamKey.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  //if (isWide) SizedBox(height: 4),
                  //if (isWide) Text("data", style: TextStyle(color: Colors.grey.shade800)),
                  const SizedBox(height: 4),
                  Text("${users!.length} membres", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          );
        },
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? (isTall ? 5 : 4) : (isTall ? 2 : 3),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
      ),
    );
  }

  Widget viewTeam(Team team, bool isAdmin) {
    return SingleChildScrollView(child: isViewTeam ? teamMembers(team, isAdmin) : addUsers(team));
  }

  Widget showUsersToSelect(Team team, bool add) {
    List<UserTeam> usersAviable = [];

    if (add) {
      //USUARIS QUE NO ESTAN AL EQUIP
      usersAviable = allUsers
          .where((u) => !teamsAndUsers[team]!.any((ut) => ut.user.userName == u.userName))
          .map((user) => UserTeam(team: team, user: user, role: TeamRole.NONE, id: "", deleted: false))
          .toList();
    } else {
      //USUARIS QUE ESTAN JA AL EQUIP PER A ELIMINAR-LOS
      usersAviable = teamsAndUsers[team]!;
    }

    usersAviable = usersAviable
        .where(
          (ut) =>
              ut.user.userName.toLowerCase().contains(filter) ||
              ut.user.name.toLowerCase().contains(filter) ||
              ut.user.surname.toLowerCase().contains(filter),
        )
        .toList();
    usersAviable = usersAviable.toSet().toList();

    usersAviable.sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: {
            0: IntrinsicColumnWidth(),
            1: IntrinsicColumnWidth(),
            2: IntrinsicColumnWidth(),
            3: IntrinsicColumnWidth(),
            4: IntrinsicColumnWidth(),
          },
          children: [
            for (UserTeam ut in usersAviable)
              tableRowUser(
                Checkbox(
                  value: usersAdded.contains(ut.user),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        usersAdded.add(ut.user);
                      } else {
                        usersAdded.remove(ut.user);
                      }
                    });
                  },
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                ut,
              ),
          ],
        ),
      ],
    );
  }

  Container editTeamButton() {
    return Container(
      alignment: Alignment.centerLeft,

      child: PopupMenuButton(
        tooltip: "Editar equip",

        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            child: Text("Veure equip"),
            onTap: () {
              setState(() {
                viewList = false;
                isViewTeam = true;
                isAddToTeam = true;
              });
            },
          ),
          PopupMenuItem(
            child: Text("Afegir membres"),
            onTap: () {
              setState(() {
                viewList = false;
                isViewTeam = false;
                isAddToTeam = true;
              });
            },
          ),
          PopupMenuItem(
            child: Text("Treure membres"),
            onTap: () {
              setState(() {
                viewList = false;
                isViewTeam = false;
                isAddToTeam = false;
              });
            },
          ),
        ],
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text("Editar", style: TextStyle(fontSize: 17)),
        ),
      ),
    );
  }

  Column teamMembers(Team team, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin || isTeamAdmin)
          TextButton(onPressed: () => openFormCreateTeam(team, false), child: Text("Editar dades")),

        SizedBox(height: 10),
        Text("Tasques del equip: ", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        teamTasks(team),

        Divider(height: 40),

        Text("Membres del equip:", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        SizedBox(height: 15),

        teamsAndUsers[team]!.isEmpty
            ? Text("\t\tNo hi ha usuaris")
            : Table(
                columnWidths: {
                  0: IntrinsicColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: IntrinsicColumnWidth(),
                  3: IntrinsicColumnWidth(),
                  4: IntrinsicColumnWidth(),
                },
                children: [
                  for (UserTeam ut in teamsAndUsers[team]!)
                    tableRowUser(
                      Text("${teamsAndUsers[team]!.indexOf(ut) + 1}", style: TextStyle(fontWeight: FontWeight.bold)),
                      ut,
                    ),
                ],
              ),
      ],
    );
  }

  Column addUsers(Team team) {
    return isAddToTeam
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Afegir membres: ", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  SizedBox(width: 20),

                  ElevatedButton(
                    onPressed: () async {
                      for (var user in usersAdded) {
                        await teamController.addUserToTeam(team, user);
                      }
                      usersAdded.clear();
                      setState(() {});
                    },
                    child: Text("Afegir"),
                  ),
                ],
              ),

              SizedBox(height: 15),
              searchUsers(),
              SizedBox(height: 20),
              Container(child: showUsersToSelect(team, true)),
            ],
          )
        : removeUsers(team);
  }

  Widget searchUsers() {
    return SizedBox(
      width: 300,
      child: TextField(
        decoration: InputDecoration(labelText: "Buscar", border: OutlineInputBorder()),
        onChanged: (value) {
          filter = value.toLowerCase();
          setState(() {});
        },
      ),
    );
  }

  Column removeUsers(Team team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Treure membres: ", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            SizedBox(width: 20),
            if (teamsAndUsers[team]!.isNotEmpty)
              ElevatedButton(
                onPressed: () async {
                  for (var user in usersAdded) {
                    //await teamController.addUserToTeam(team, user);
                    await teamController.deleteUserTeamRelationByUser(team, user.id);
                    teamsAndUsers[team]!.removeWhere((u) => u.user.userName == user.userName);
                  }
                  usersAdded.clear();
                  setState(() {});
                },
                child: Text("Guardar"),
              ),
          ],
        ),
        SizedBox(height: 15),
        searchUsers(),
        SizedBox(height: 15),
        teamsAndUsers[team]!.isEmpty ? Text("\t\tNo hi ha usuaris") : Container(child: showUsersToSelect(team, false)),
      ],
    );
  }

  Widget teamTasks(Team team) {
    List<Task> teamTask = tasksFromTeams[team]!;
    return teamTask.isNotEmpty
        ? Table(
            columnWidths: {0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth()},
            children: [for (Task tsk in teamTask) tableRowTask(tsk)],
          )
        : Text("Aquest equip no té tasques assignades");
  }

  //TASK PAGE
  Widget taskPage() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [pageLabel(AppStrings.TASKS.toUpperCase())]),

              SizedBox(height: 20),
              filterButtons(),
              SizedBox(height: 10),

              taskList(), // --> LLISTA TASQUES + BOTÓ PER VEURE NOMES LES ELIMINADES + FILTRE/BUSCADOR
            ],
          );
  }

  Widget filterButtons() {
    return !isWide
        ? Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [searchTask(), SizedBox(width: 10), showOnlyDeletedBtn()]),
                ),
              ),
            ],
          )
        /*
           * Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchTask(),
              SizedBox(height: 10),
              showOnlyDeletedBtn(),
              //SizedBox(height: 10), shownTasks()
            ],
          )
           */
        : Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [searchTask(), SizedBox(width: 10), showOnlyDeletedBtn()]),
                ),
              ),
              shownTasks(),
            ],
          );
  }

  Widget showOnlyDeletedBtn() {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: () {
          showOnlyDeleted = !showOnlyDeleted;
          setState(() {});
        },
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            showOnlyDeleted
                ? Theme.of(context).colorScheme.inversePrimary
                : Theme.of(context).colorScheme.primaryContainer,
          ),
          foregroundColor: WidgetStatePropertyAll(Colors.black),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        ),
        child: isWide
            ? Text(
                isWide ? "Vreure només les tasques eliminades" : "Veure només eliminades",
                style: TextStyle(fontSize: 17),
              )
            : Icon(Icons.remove_red_eye),
      ),
    );
  }

  Text shownTasks() {
    return Text(
      AppStrings.shownTasks(
        allTasks.where((task) => (task.name.contains(filter) || task.description.contains(filter))).length,
      ),
    );
  }

  Widget searchTask() {
    return SizedBox(
      width: 300,
      child: TextField(
        decoration: InputDecoration(labelText: "Buscar", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
        onChanged: (value) {
          filter = value.toLowerCase();
          setState(() {});
        },
      ),
    );
  }

  Expanded taskList() {
    return Expanded(
      child: ListView.builder(
        itemCount: allTasks.length,
        itemBuilder: (context, index) {
          final task = allTasks[index];
          bool hasPassedDate = task.completedDate != null
              ? task.limitDate.add(Duration(days: 1)).isBefore(task.completedDate!)
              : task.limitDate.add(Duration(days: 1)).isBefore(DateTime.now());

          // filtrar per taskName (si escrit)
          if (!(task.name.contains(filter) || task.description.contains(filter))) {
            return SizedBox();
          }

          if (showOnlyDeleted && !task.deleted) {
            return SizedBox();
          }

          return Card(
            color: taskColor(task, hasPassedDate),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.all(5),

              title: SizedBox(child: Row(children: [SizedBox(width: 15), Text(task.name)])),
              subtitle: SizedBox(child: Row(children: [SizedBox(width: 15), Text(task.description)])),
              onTap: () => openViewTask(task),

              textColor: textColor(task, hasPassedDate),
              trailing: SizedBox(
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    !isWide
                        ? TextButton(
                            onPressed: () async {
                              restoreTask();
                              setState(() {});
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Restaurar",
                                  style: TextStyle(color: textColor(task, hasPassedDate), fontSize: 16),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.restart_alt, color: textColor(task, hasPassedDate), size: 20),
                              ],
                            ),
                          )
                        : IconButton(
                            tooltip: "Restaurar",
                            onPressed: () async {
                              restoreTask();
                              setState(() {});
                            },
                            icon: Icon(Icons.restart_alt),
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                return textColor(task, hasPassedDate);
                              }),
                            ),
                          ),
                    SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void restoreTask() {
    logToDo("restaurar tasca", "ConfigPage(restoreTask)");
  }

  Color? taskColor(Task task, bool hasPassedDate) {
    if (task.deleted) {
      return Colors.black54;
    }
    return ToDoPage.backgroundColor(task, hasPassedDate);
  }

  Color textColor(Task task, bool hasPassedDate) {
    if (task.deleted || hasPassedDate) {
      return Colors.white;
    }
    return Colors.black87;
  }

  //HISTORY PAGE
  Widget historyPage() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [pageLabel(AppStrings.HISTORY.toUpperCase())]),
              SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: Colors.grey.shade300,
                child: Row(
                  children: [
                    Tables.header("Data"),
                    Tables.header("Nom"),
                    Tables.header("Tipus entitat"),
                    if (isWide) ...[Tables.header("Abans"), Tables.header("Desprès")],
                  ],
                ),
              ),
              SizedBox(height: 5),
              historyList(),

              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.circle, color: ChangeType.CREATE.getColor()),
                  SizedBox(width: 5),
                  Text("Crear"),
                  SizedBox(width: 20),
                  Icon(Icons.circle, color: ChangeType.UPDATE.getColor()),
                  SizedBox(width: 5),
                  Text("Editar"),
                  SizedBox(width: 20),
                  Icon(Icons.circle, color: ChangeType.DELETE.getColor()),
                  SizedBox(width: 5),
                  Text("Eliminar"),
                ],
              ),
            ],
          );
  }

  Expanded historyList() {
    final entries = history.entries.toList();
    return Expanded(
      child: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final hist = entries[index].key;
          final obj = entries[index].value;

          // final hist = history[index];

          // FILTRAR
          //if ((hist.time.isBefore(DateTime.now()))) {return SizedBox();}

          return historyRow(hist, obj);
        },
      ),
    );
  }

  Widget historyRow<T extends BaseEntity>(History h, T obj) {
    String nameObj = "", oldValue = "", newValue = "";

    switch (h.entity) {
      case Entity.NONE:
        nameObj = "";
        break;
      case Entity.TASK:
        if (obj is Task) {
          nameObj = obj.name;
          // - ${obj.description.substring(0, obj.description.length < 20 ? obj.description.length : 20)}";
          //ñ
        }
        break;
      case Entity.USER:
        if (obj is User) {
          nameObj = "${obj.name} ${obj.surname} (${obj.userName})";
          // subtitle = "";
        }
        break;
      case Entity.TEAM:
        if (obj is Team) {
          nameObj = obj.name;
          //subtitle = "";
        }
        break;
      case Entity.NOTIFICATION:
        if (obj is Notifications) {
          nameObj = obj.message;
          //subtitle = "";
        }
        break;
      case Entity.TASKSTATE:
        if (obj is TaskState) {
          nameObj = obj.name;
          //subtitle = "";
        }
        break;
      case Entity.TEAM_TASK:
        if (obj is TeamTask) {
          nameObj = "${obj.task.name} - ${obj.team.name}";
          //subtitle = "";
        }
        break;
      case Entity.USER_TASK:
        if (obj is UserTask) {
          nameObj = obj.user.userName;
          //subtitle = "";
        }
        break;
      case Entity.USER_TEAM:
        if (obj is UserTeam) {
          nameObj = obj.user.userName;
          // subtitle = "";
        }
    }
    return Card(
      //ñ
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: h.changeType.getColor(),
      child: InkWell(
        onTap: () => logToDo("Veure detall history", "ConfigPage(historyRow)"),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Tables.cell(DateFormat("dd/MM/yyyy").format(h.time)),
              Tables.cell(nameObj),
              Tables.cell(h.entity.name),
              if (isWide) ...[Tables.cell(oldValue), Tables.cell(newValue)],
              //Tables.cell("${h.user.name} ${h.user.surname} (${h.user.userName})"),
            ],
          ),
        ),
      ),
    );
  }

  Row filterHistButtons() {
    return Row();
  }

  Widget viewHistory<T extends BaseEntity>(History h, T entity) {
    return Column();
  }

  //DELETE ACC
  Widget deleteAccountPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextButton(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.red;
              }
              return Colors.black87;
            }),
          ),
          onPressed: () async {
            //confirmDelete();
            if (await confirmPasword(true)) {
              await userController.deleteUser(widget.user);
              Navigator.push(context, MaterialPageRoute(builder: (context) => MyApp()));
            }
          },
          child: Text(AppStrings.DELETEACC.toUpperCase(), style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }

  //OTHER
  Text pageLabel(String text) {
    return Text(text, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20));
  }

  @override
  void dispose() {
    userNameController.dispose();
    nameController.dispose();
    surnameController.dispose();
    mailController.dispose();
    passwordController.dispose();
    //colorController.dispose();
    super.dispose();
  }

  void clear() {
    userNameController.clear();
    nameController.clear();
    surnameController.clear();
    mailController.clear();
    passwordController.clear();
    //colorController.clear();
  }

  void controllersFromUser(User u) {
    nameController.text = u.name;
    surnameController.text = u.surname;
    userNameController.text = u.userName;
    mailController.text = u.mail;
  }

  //TABLE - DRAWER - RAIL
  ListTile _drawerItem(String title, int index) {
    return ListTile(
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        Navigator.of(context).pop();
        pageChanged(index);
      },
    );
  }

  NavigationRailDestination _railItem(IconData icon, String label) {
    return NavigationRailDestination(icon: Icon(icon), label: Text(label));
  }

  TableRow tableRowUser(Widget label, UserTeam ut) {
    double horizontal = isWide ? 30 : 10;
    double vertical = 8;
    EdgeInsets padding = EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
    String role = ut.role == TeamRole.NONE ? "" : ut.role.name;
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: vertical),
          child: label,
        ),
        Padding(padding: padding, child: Text("${ut.user.name} ${ut.user.surname}")),
        Padding(padding: padding, child: Text(ut.user.userName)),
        Padding(padding: padding, child: Text(role)),
      ],
    );
  }

  TableRow tableRowTask(Task task) {
    double horizontal = isWide ? 30 : 10;
    double vertical = 8;
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
          child: Text(task.name),
        ),

        Padding(
          padding: EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
          child: Text(DateFormat("dd/MM/yyyy").format(task.limitDate)),
        ),
      ],
    );
  }

  void pageChanged(int index) {
    selectedIndex = index;
    filter = "";
    viewList = true;
    if (index == 1) {
      iconSelected = User.iconMap.entries.firstWhere((e) => e.value == myUser.icon.icon).key;
      editUser = myUser;
    }

    clear();
    controllersFromUser(editUser);

    setState(() {});
  }

  // SHOW MODAL BOTTOM SHEET
  openFormCreateState(bool isCreate, TaskState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 30),

          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: isCreate
                ? StateForm(
                    state: state,
                    createTState: (tState) async {
                      bool contains = states.any((TaskState s) => s.name == tState.name);

                      if (contains) {
                        nameExists("estat");
                      } else {
                        await stateController.createState(tState);
                        await HistoryController.createTaskState(tState, myUser);
                        states.add(tState);
                        Navigator.of(context).pop();
                      }

                      setState(() {});
                    },
                  )
                : StateForm(
                    state: state,
                    editTState: (tState) async {
                      bool nameChanged = tState.name != state.name;

                      bool contains = false;

                      if (nameChanged) {
                        contains = states.any((TaskState s) => s.name == tState.name);
                      }

                      if (contains) {
                        nameExists("estat");
                      } else {
                        await stateController.updateState(tState);
                        int num = states.indexWhere((s) => state.id == s.id);
                        states[num] = tState;
                        Navigator.of(context).pop();
                      }
                      setState(() {});
                    },
                  ),
          ),
        );
      },
    );
  }

  openFormCreateUser(User user) {
    clear();
    controllersFromUser(user);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 30),
              child: SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: editAccount(user, true)),
            );
          },
        );
      },
    );
  }

  openFormCreateTeam(Team team, bool isCreate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 30),

          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: isCreate
                ? TeamForm(
                    team: team,
                    allUsers: allUsers,
                    onTeamCreated: (team, users) async {
                      //List<User> filteredUsers = users;
                      //allUsers.where((user) => users.contains(user)).toList();
                      if (teamsAndUsers.keys.any((t) => t.name == team.name)) {
                        nameExists("equip");
                      } else {
                        await teamController.createTeam(team);
                        for (final u in users) {
                          await teamController.addUserToTeam(team, u);
                        }
                        teamsAndUsers = teamController.sortMap(teamsAndUsers);
                        Navigator.of(context).pop();
                      }
                      setState(() {});
                    },
                  )
                : TeamForm(
                    team: team,
                    allUsers: allUsers,
                    usersInTeam: teamsAndUsers[team]!,
                    onTeamEdited: (teamEdited, adminUsers) async {
                      await teamController.updateTeam(teamEdited);
                      var users = await teamController.updateAdmins(adminUsers, teamsAndUsers[team]!, team);

                      Navigator.of(context).pop();

                      team = teamEdited;
                      teamsAndUsers.removeWhere((key, value) => key.id == team.id);
                      teamsAndUsers[teamEdited] = users;
                      teamsAndUsers = teamController.sortMap(teamsAndUsers);
                      viewList = true;
                      setState(() {});
                    },
                  ),
          ),
        );
      },
    );
  }

  openViewTask(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Tables.viewTasks(task, Theme.of(context).colorScheme.inverseSurface),
            ),
          ),
        );
      },
    );
  }

  //LOAD
  Future<void> _loadUsers(bool loadDeleted) async {
    List<User> users = await userController.loadAllUsers(loadDeleted);
    users.sort();
    setState(() {
      allUsers = users;
    });
  }

  Future<void> _loadTaskByUser() async {
    for (User user in allUsers) {
      await taskController.loadTasksFromDB(user.id);
      tasksFromUsers[user.userName] = taskController.tasks;
    }
  }

  Future<void> _loadAllTask() async {
    await taskController.loadAllTasksFromDB(true);
    allTasks = taskController.tasks;
    allTasks.sort((task1, task2) => TaskController.sortTask(SortType.DATE, task1, task2, {}));
  }

  Future<void> _loadHistory() async {
    history = await HistoryController.eventMap();
  }

  Future<void> _loadAdminData() async {
    tasksFromTeams.clear();
    await _loadUsers(true);
    await _loadTaskByUser();
    if (isAdmin) {
      await _loadAllTask();
    }
    await stateController.loadAllStates();
    states = stateController.states;
    await teamController.loadAllTeamsWithUsers();
    teamsAndUsers = teamController.allTeamsAndUsers;
    for (Team team in teamsAndUsers.keys) {
      tasksFromTeams[team] = await taskController.loadTaskByTeam(team);
    }
    await _loadHistory();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadData() async {
    await teamController.loadTeamsbyUser(myUser);
    myTeams = teamController.myTeamsAndUsers;
    setState(() {});
  }

  Future<void> loadInitialData() async {
    setState(() {
      isLoading = true;
    });
    myUser = User.copy(widget.user);
    isAdmin = UserRole.isAdmin(myUser.userRole);
    await _loadAdminData();
    await _loadData();
    iconSelected = User.iconMap.entries.firstWhere((e) => e.value == myUser.icon.icon).key;
    isUserAdmin = isAdmin;
    setState(() {
      isLoading = false;
    });
  }

  // SHOW DIALOG
  void nameExists(String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Aquest $type ja existeix"),
          content: Text("Tria un altre nom"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Tancar"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> deleteState(TaskState tState) async {
    TextEditingController controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar estat"),
          content: Text("Per  continuar, introdueixi el nom del estat: "),
          actions: <Widget>[
            TextField(
              controller: controller,
              //obscureText: false,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),

            SizedBox(height: 10),

            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    final isValid = controller.text == tState.name;
                    Navigator.of(context).pop(isValid);
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
      },
    );
    return result ?? false;
  }

  Future<bool> confirmUserName(String userName) async {
    clear();
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Nom d'usuari"),
          content: Text("Per continuar, introdueixi el nom de l'usuari"),
          actions: <Widget>[
            TextField(
              controller: userNameController,
              //obscureText: true,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),

            Row(
              children: [
                TextButton(
                  onPressed: () {
                    //final isValid = await isUserName(userNameController.text);
                    final isValid = userNameController.text.compareTo(userName) == 0;
                    Navigator.of(context).pop(isValid);
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

  Future<bool> confirmPasword(bool deleteAcc) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(deleteAcc ? "Eliminar compte" : "Contrasenya"),
          content: Text("Per continuar, introdueixi la contrasenya"),
          actions: <Widget>[
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),

            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    final isValid = await userController.isPasword(myUser.userName, passwordController.text);
                    Navigator.of(context).pop(isValid);
                  },
                  style: deleteAcc
                      ? ButtonStyle(
                          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.red;
                            }
                            return Theme.of(context).colorScheme.primary;
                          }),
                        )
                      : null,
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
      },
    );
    return result ?? false;
  }

  Future<TaskState> choseState(TaskState state) async {
    clear();
    final result = await showDialog<TaskState>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Estat"),
          content: Text("Tria el estat que voldrà assignar a les tasques."),
          actions: <Widget>[
            DropdownButtonFormField<String>(
              decoration: InputDecoration(border: OutlineInputBorder()),
              hint: Text("Estat"),
              value: stateSTR!.isNotEmpty ? stateSTR : null,
              items: states
                  .where((s) => s.id != state.id)
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

            Row(
              children: [
                TextButton(
                  onPressed: () {
                    TaskState state = stateController.getStateByName(stateSTR!);

                    Navigator.of(context).pop(state);
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
                  child: Text(AppStrings.CANCEL),
                ),
              ],
            ),
          ],
        );
      },
    );
    return result ?? stateController.defaultState();
  }
}
