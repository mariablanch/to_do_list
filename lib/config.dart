import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:to_do_list/controller/state_controller.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/controller/team_controller.dart';

import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/relation_tables/user_team.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/to_do_page.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/const/firebase_options.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/user_role.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/main.dart';
import 'package:to_do_list/utils/user_role_team.dart';
import 'package:to_do_list/view_form/state_form.dart';
import 'package:to_do_list/view_form/team_form.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /*User userProva = User.parameter(
    '111',
    '111',
    '111',
    '111',
    'f6e0a1e2ac41945a9aa7ff8a8aaa0cebc12a3bcc981a929ad5cf810a090e11ae',
    UserRole.ADMIN,
  );*/
  User userProva = User(
    name: '111',
    surname: '111',
    userName: '111',
    mail: '111',
    password: 'f6e0a1e2ac41945a9aa7ff8a8aaa0cebc12a3bcc981a929ad5cf810a090e11ae',
    userRole: UserRole.ADMIN,
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
      title: 'Configuració',
      home: ConfigHP(user: user),
      theme: ThemeData(
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        colorScheme: (!UserRole.isAdmin(user.userRole))
            ? ColorScheme.fromSeed(seedColor: Colors.deepPurple)
            : ColorScheme.fromSeed(seedColor: Colors.amber),
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
  bool viewUserList = true,
      viewTeamList = true,
      userEdit = false,
      isUserAdmin = false,
      isTeamAdmin = false,
      isViewTeam = true,
      isAddToTeam = true;
  late bool isAdmin;
  User editUser = User.empty();
  Team editTeam = Team.empty();

  String iconSelected = 'person';

  List<Widget> get pages => [profilePage(), editAccountPage(), teamsPage(false), deleteAccountPage()];
  List<Widget> get adminPages => [
    profilePage(),
    editAccountPage(),
    usersPage(),
    statePage(),
    teamsPage(true),
    teamsPage(false),
    deleteAccountPage(),
  ];
  List<Widget> get adminPagess => [
    teamsPage(false),
    profilePage(),
    editAccountPage(),
    usersPage(),
    statePage(),
    teamsPage(true),
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

  Set<User> usersAdded = {};

  TextEditingController userNameController = TextEditingController(),
      nameController = TextEditingController(),
      surnameController = TextEditingController(),
      mailController = TextEditingController(),
      passwordController = TextEditingController();

  String? stateSTR = '';
  String nameFilter = '';

  late bool isWide, isTall;

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

  @override
  void initState() {
    super.initState();
    myUser = User.copy(widget.user);
    isAdmin = UserRole.isAdmin(myUser.userRole);
    if (isAdmin) {}
    loadAdminData();
    loadData();
    iconSelected = User.iconMap.entries.firstWhere((e) => e.value == myUser.icon.icon).key;
    isUserAdmin = isAdmin;
    setState(() {});
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
                children: [
                  _drawerItem(AppStrings.PROFILE, 0),
                  _drawerItem(AppStrings.CONFIG, 1),
                  if (isAdmin) _drawerItem(AppStrings.USERS_LABEL, 2),
                  if (isAdmin) _drawerItem(AppStrings.TASKSTATES, 3),
                  if (isAdmin) _drawerItem(AppStrings.TEAMS, 4),
                  _drawerItem(AppStrings.MY_TEAMS, isAdmin ? 5 : 2),
                  _drawerItem(AppStrings.DELETEACC, isAdmin ? 6 : 3),
                ],
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
                    if (index == 1) {
                      iconSelected = User.iconMap.entries.firstWhere((e) => e.value == myUser.icon.icon).key;
                    }
                    viewTeamList = true;
                    setState(() => selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    _railItem(Icons.person, AppStrings.PROFILE, false),
                    _railItem(Icons.settings, AppStrings.CONFIG, false),
                    if (isAdmin) _railItem(Icons.people, AppStrings.USERS_LABEL, allUsers.isEmpty),
                    if (isAdmin) _railItem(Icons.style, AppStrings.TASKSTATES, states.isEmpty),
                    if (isAdmin) _railItem(Icons.groups_2, AppStrings.TEAMS, teamsAndUsers.isEmpty),
                    _railItem(Icons.group_work, AppStrings.MY_TEAMS, teamsAndUsers.isEmpty),
                    _railItem(Icons.delete, AppStrings.DELETEACC, false),
                  ],
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
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: isAdmin ? adminPages[selectedIndex] : pages[selectedIndex],
            ),
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
            Table(
              columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
              children: [
                ToDoPage.tableRow('Nom:', myUser.name),
                ToDoPage.tableRow('Cognom:', myUser.surname),
                ToDoPage.tableRow('Nom d\'usuari:', myUser.userName),
                ToDoPage.tableRow('Correu:', myUser.mail),
              ],
            ),
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
            //Text('EDITAR PERFIL', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20)),
            pageLabel(AppStrings.EDIT_PROFILE.toUpperCase()),

            SizedBox(height: 20),
            editAccount(myUser, false),
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

    clear();

    nameController = TextEditingController(text: editUser.name);
    surnameController = TextEditingController(text: surname);
    userNameController = TextEditingController(text: editUser.userName);
    mailController = TextEditingController(text: editUser.mail);

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
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Nom'),
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Aquest camp és obligatori';
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
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Cognom'),
                controller: surnameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Aquest camp és obligatori';
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
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Nom d\'usuari'),
                controller: userNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Aquest camp és obligatori';
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
                decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Correu'),
                controller: mailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Aquest camp és obligatori';
                  } else if (!(value.contains('@') && value.contains('.'))) {
                    return 'No té el format adequat';
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
                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Nova contrasenya'),
                  obscureText: true,
                  //controller: paswordController,
                  validator: (value) {
                    if (isNew && (value == null || value.isEmpty)) {
                      return 'Aquest camp és obligatori';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    password = value!;
                  },
                ),
              ),
            Container(height: 5),

            if (isNew) Text('La contrasenya és generada automaticament', style: TextStyle(fontSize: 14)),

            Container(height: 5),

            //if (isAdmin && editUser.userName != myUser.userName && !isNew)
            if (adminEdit && !isNew)
              Row(
                children: [
                  Text('Permisos d\'administrador'),

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
                  Text('Icona'),

                  Container(width: 10),

                  DropdownButton<String>(
                    value: iconSelected,
                    hint: Icon(Icons.person),
                    items: User.iconMap.keys.map((String iconName) {
                      return DropdownMenuItem<String>(value: iconName, child: Icon(User.iconMap[iconName]));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        iconSelected = newValue!;
                      });
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
                      nameExists('usuari');
                    } else if (isNew) {
                      User user = editUser.copyWith(
                        name: name,
                        surname: surname,
                        userName: userName,
                        mail: mail,
                        password: AppStrings.DEFAULT_PSWRD,
                      );
                      await userController.createAccountDB(user);
                      await _loadUsers();

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

                        try {
                          await userController.updateProfileDB(updatedUser, editUser);
                        } catch (e) {
                          logError('EDIT ACCOUNT configPage', e);
                        }
                        //user = updatedUser;

                        setState(() {
                          viewUserList = true;
                          userEdit = false;
                        });

                        if (!adminEdit) {
                          Navigator.pop(context, updatedUser);
                        } else {
                          await _loadUsers();
                        }
                      }
                    }
                  }
                },
                label: Text(!isNew ? 'Guardar canvis' : 'Crear compte'),
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
            if (!viewUserList)
              IconButton(
                onPressed: () {
                  setState(() {
                    viewUserList = true;
                  });
                },
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
              ),

            /*Text(
              viewUserList ? AppStrings.USERS_LABEL.toUpperCase() : editUser.userName,
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
            ),*/
            pageLabel(viewUserList ? AppStrings.USERS_LABEL.toUpperCase() : editUser.userName),
          ],
        ),

        SizedBox(height: 20),

        viewUserList ? userList() : Expanded(child: viewUser(userEdit, editUser)),

        if (viewUserList)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: FloatingActionButton.extended(
              heroTag: 'createUser',
              onPressed: () async {
                await openFormCreateUser();
                await _loadUsers();
              },
              label: Text('Crear Usuari'),
              icon: Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Expanded userList() {
    return Expanded(
      child: ListView.builder(
        itemCount: allUsers.isEmpty ? 0 : allUsers.length - 1,
        itemBuilder: (context, index) {
          final user = allUsers.where((u) => u.userName != myUser.userName).toList()[index];

          return Card(
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.all(5),

              leading: SizedBox(width: 35, child: user.icon),
              title: Text(user.userName),
              subtitle: Text('${user.name} ${user.surname}'),

              trailing: SizedBox(
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Veure dades',
                      onPressed: () async {
                        //await taskController.loadTasksFromDB(allUsers[index].userName);
                        setState(() {
                          viewUserList = false;
                          userEdit = false;
                          editUser = allUsers[index];
                        });
                      },
                      icon: Icon(Icons.remove_red_eye),
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: () {
                        setState(() {
                          editUser = allUsers[index];
                          iconSelected = User.iconMap.entries.firstWhere((e) => e.value == editUser.icon.icon).key;
                          viewUserList = false;
                          userEdit = true;
                          isUserAdmin = UserRole.isAdmin(editUser.userRole);
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
    List<Task> tasks = tasksFromUsers[user.userName]!;
    return edit
        ? editAccount(user, false)
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Table(
                  columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                  children: [
                    ToDoPage.tableRow('Nom:', user.name),
                    ToDoPage.tableRow('Cognom:', user.surname),
                    ToDoPage.tableRow('Nom d\'usuari:', user.userName),
                    ToDoPage.tableRow('Correu:', user.mail),
                    ToDoPage.tableRow('Rol:', (UserRole.isAdmin(user.userRole)) ? 'Administrador' : 'Usuari'),
                  ],
                ),

                Container(height: 10),
                //Text('------------------------------------------------', style: TextStyle(fontWeight: FontWeight.bold)),
                //Divider(height: 20, endIndent: 1000),
                SizedBox(height: 30, width: 500, child: Divider(thickness: 2)),

                Container(height: 10),

                Table(
                  columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                  children: [
                    ToDoPage.tableRow(
                      'Tasques de l\'usuari:',
                      tasks.isEmpty ? 'Aquest usuari no té tasques assignades.' : tasks.first.name,
                    ),
                    for (Task task in tasks.skip(1).toList()) ToDoPage.tableRow('', task.name),
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
                  child: Text('Reiniciar contrasenya'),
                ),

                Container(height: 15),

                ElevatedButton(
                  onPressed: () async {
                    if (await confirmPasword(true)) {
                      await userController.deleteUser(user.userName);

                      int pos = allUsers.indexOf((user));

                      setState(() {
                        allUsers.removeAt(pos);
                        viewUserList = true;
                      });
                    }
                  },
                  child: Text('Eliminar usuari'),
                ),
              ],
            ),
          );
  }

  //STATE PAGE
  Widget statePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            /*Text(
              AppStrings.TASKSTATES.toUpperCase(),
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
            ),*/
            pageLabel(AppStrings.TASKSTATES.toUpperCase()),
          ],
        ),

        SizedBox(height: 20),
        taskStateList(),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: FloatingActionButton.extended(
            heroTag: 'createState',
            onPressed: () {
              openFormCreateState(true, TaskState.empty());
            },
            label: Text('Crear nou estat'),
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
          //canDelete = false;

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
                    IconButton(
                      tooltip: !canDelete ? 'Editar' : 'Opció per defecte (no editable)',
                      onPressed: !canDelete
                          ? () {
                              openFormCreateState(false, state);
                            }
                          : null,
                      icon: Icon(Icons.edit),
                    ),

                    IconButton(
                      tooltip: !canDelete ? 'Eliminar' : 'Opció per defecte (no es pot eliminar)',
                      onPressed: !canDelete
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
                      icon: Icon(Icons.delete),
                    ),
                    SizedBox(width: 15),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!viewTeamList)
              IconButton(
                onPressed: () {
                  setState(() {
                    viewTeamList = true;
                  });
                },
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
              ),
            /*Text(
              viewTeamList ? AppStrings.TEAMS.toUpperCase() : editTeam.name,
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
            ),*/
            pageLabel(
              viewTeamList
                  ? (admin ? AppStrings.TEAMS.toUpperCase() : AppStrings.MY_TEAMS.toUpperCase())
                  : editTeam.name,
            ),
          ],
        ),
        SizedBox(height: 20),
        // if (!viewTeamList && TeamRole.isAdmin(teamsAndUsers[editTeam]!.firstWhere((u) => u.user == myUser).role))
        if (!viewTeamList && isTeamAdmin) editTeamButton(),

        SizedBox(height: 10),

        viewTeamList ? teamList(admin) : Expanded(child: viewTeam(editTeam, admin)),

        if (viewTeamList)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: FloatingActionButton.extended(
              heroTag: 'createTeam',
              onPressed: () async {
                openFormCreateTeam(Team.empty(), true);
                //logToDo('crear equip', 'ConfigPage(teamsPage)');
              },
              label: Text('Crear Equip'),
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
                  viewTeamList = false;
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
                  //if (isWide) Text('data', style: TextStyle(color: Colors.grey.shade800)),
                  const SizedBox(height: 4),
                  Text('${users!.length} membres', style: TextStyle(color: Colors.grey[600])),
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
          .map((user) => UserTeam(team: team, user: user, role: TeamRole.USER))
          .toList();
    } else {
      //USUARIS QUE ESTAN JA AL EQUIP PER A ELIMINAR-LOS
      usersAviable = teamsAndUsers[team]!;
    }

    usersAviable = usersAviable
        .where(
          (ut) =>
              ut.user.userName.toLowerCase().contains(nameFilter) ||
              ut.user.name.toLowerCase().contains(nameFilter) ||
              ut.user.surname.toLowerCase().contains(nameFilter),
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
        tooltip: 'Editar equip',

        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            child: Text('Veure equip'),
            onTap: () {
              setState(() {
                viewTeamList = false;
                isViewTeam = true;
                isAddToTeam = true;
              });
            },
          ),
          /*PopupMenuItem(
            child: Text('Editar equip'),
            onTap: () {
              setState(() {
                logToDo('Editar equip', 'ToDoPage(editTeamButton)');
              });
            },
          ),*/
          PopupMenuItem(
            child: Text('Afegir membres'),
            onTap: () {
              setState(() {
                viewTeamList = false;
                isViewTeam = false;
                isAddToTeam = true;
              });
            },
          ),
          PopupMenuItem(
            child: Text('Treure membres'),
            onTap: () {
              setState(() {
                viewTeamList = false;
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
          child: Text('Editar', style: TextStyle(fontSize: 17)),
        ),
      ),
    );
  }

  Column teamMembers(Team team, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin || isTeamAdmin)
          TextButton(onPressed: () => openFormCreateTeam(team, false), child: Text('Editar dades')),
        SizedBox(height: 10),
        Text('Tasques del equip: ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        teamTasks(team, isAdmin),

        Divider(height: 40),

        Text('Membres del equip:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        SizedBox(height: 15),

        teamsAndUsers[team]!.isEmpty
            ? Text('\t\tNo hi ha usuaris')
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
                      Text('${teamsAndUsers[team]!.indexOf(ut) + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Text('Afegir membres: ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  SizedBox(width: 20),

                  ElevatedButton(
                    onPressed: () async {
                      for (var user in usersAdded) {
                        await teamController.addUserToTeam(team, user);
                      }
                      usersAdded.clear();
                      setState(() {});
                    },
                    child: Text('Afegir'),
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
        decoration: InputDecoration(labelText: 'Buscar', border: OutlineInputBorder()),
        onChanged: (value) {
          nameFilter = value.toLowerCase();
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
            Text('Treure membres: ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            SizedBox(width: 20),
            if (teamsAndUsers[team]!.isNotEmpty)
              ElevatedButton(
                onPressed: () async {
                  for (var user in usersAdded) {
                    //await teamController.addUserToTeam(team, user);
                    await teamController.deleteUserTeamRelationByUser(team, user.userName);
                    teamsAndUsers[team]!.removeWhere((u) => u.user.userName == user.userName);
                  }
                  usersAdded.clear();
                  setState(() {});
                },
                child: Text('Guardar'),
              ),
          ],
        ),
        SizedBox(height: 15),
        searchUsers(),
        SizedBox(height: 15),
        teamsAndUsers[team]!.isEmpty
            ? Text('\t\tNo hi ha usuaris')
            : Container(child: showUsersToSelect(team, false)),
      ],
    );
  }

  Table teamTasks(Team team, bool isAdmin) {
    List<Task>? teamTask = tasksFromTeams[team];
    return Table(
      columnWidths: {0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth()},
      children: [
        if (teamTask != null)
          for (Task tsk in teamTask) tableRowTask(tsk),
      ],
    );
  }

  // MY TEAMS
  /* Widget myTeamsPage() {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pageLabel(AppStrings.MY_TEAMS.toUpperCase()),
          SizedBox(height: 20),
          viewTeamList
              ? teamList(false)
              : Expanded(
                  child: viewTeam(
                    editTeam,
                    teamsAndUsers[editTeam]!.any(
                      (ut) => ut.user.userName == myUser.userName && TeamRole.isAdmin(ut.role),
                    ),
                  ),
                ),

          //          teamList(false),
        ],
      ),
    );
  }*/

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
              await userController.deleteUser(widget.user.userName);
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

  //TABLE - DRAWER - RAIL
  ListTile _drawerItem(String title, int index) {
    return ListTile(
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        if (index == 1) iconSelected = User.iconMap.entries.firstWhere((e) => e.value == myUser.icon.icon).key;
        Navigator.of(context).pop();
        setState(() {
          viewTeamList = true;
          selectedIndex = index;
        });
      },
    );
  }

  NavigationRailDestination _railItem(IconData icon, String label, bool disabled) {
    return NavigationRailDestination(icon: Icon(icon), label: Text(label), disabled: disabled);
  }

  TableRow tableRowUser(Widget label, UserTeam ut) {
    double horizontal = isWide ? 30 : 10;
    double vertical = 8;
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: vertical),
          child: label,
          //Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
          child: Text("${ut.user.name} ${ut.user.surname}"),
        ),

        Padding(
          padding: EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
          child: Text(ut.user.userName),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
          child: Text(ut.role.name),
        ),
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
          child: Text(DateFormat('dd/MM/yyyy').format(task.limitDate)),
        ),
      ],
    );
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
                        nameExists('estat');
                      } else {
                        await stateController.createState(tState);
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
                        nameExists('estat');
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

  openFormCreateUser() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 30),

          child: SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: editAccount(User.empty(), true)),
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
                        nameExists('equip');
                      } else {
                        await teamController.createTeam(team);
                        for (final u in users) {
                          await teamController.addUserToTeam(team, u);
                        }
                        Navigator.of(context).pop();
                      }
                      setState(() {});
                    },
                  )
                : TeamForm(
                    team: team,
                    allUsers: allUsers,
                    onTeamEdited: (team) {
                      logToDo('Editar equip (funció)', 'ConfigPage(openFormCreateTeam)');
                    },
                  ),
          ),
        );
      },
    );
  }

  //LOAD
  Future<void> _loadUsers() async {
    List<User> users = await userController.loadAllUsers();
    users.sort((user1, user2) => user1.userName.compareTo(user2.userName));
    setState(() {
      allUsers = users;
    });
    await _loadTask();
  }

  Future<void> _loadTask() async {
    for (User user in allUsers) {
      await taskController.loadTasksFromDB(user.userName);
      tasksFromUsers[user.userName] = taskController.tasks;
    }
  }

  Future<void> loadAdminData() async {
    tasksFromTeams.clear();

    await _loadUsers();
    await stateController.loadAllStates();
    states = stateController.states;
    await teamController.loadAllTeamsWithUsers();
    teamsAndUsers = teamController.allTeamsAndUsers;
    for (Team team in teamsAndUsers.keys) {
      tasksFromTeams[team] = await taskController.loadTaskByTeam(team);
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> loadData() async {
    await teamController.loadTeamsbyUser(myUser);
    myTeams = teamController.myTeamsAndUsers;
    setState(() {});
  }

  // SHOW DIALOG:
  void nameExists(String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Aquest $type ja existeix'),
          content: Text('Tria un altre nom'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tancar'),
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
          title: Text('Eliminar estat'),
          content: Text('Per  continuar, introdueixi el nom del estat: '),
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
          title: Text('Nom d\'usuari'),
          content: Text('Per continuar, introdueixi el nom de l\'usuari'),
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
          title: Text(deleteAcc ? 'Eliminar compte' : 'Contrasenya'),
          content: Text('Per continuar, introdueixi la contrasenya'),
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
          title: Text('Estat'),
          content: Text('Tria el estat que voldrà assignar a les tasques.'),
          actions: <Widget>[
            DropdownButtonFormField<String>(
              decoration: InputDecoration(border: OutlineInputBorder()),
              hint: Text('Estat'),
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
              validator: (value) => value == null ? 'Siusplau, seleccioneu un estat' : null,
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
