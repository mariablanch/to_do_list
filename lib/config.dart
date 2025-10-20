// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:to_do_list/controller/state_controller.dart';
import 'package:to_do_list/controller/task_controller.dart';

import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/task_state.dart';
import 'package:to_do_list/to_do_page.dart';
//import 'package:to_do_list/to_do_page.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/const/firebase_options.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/user_role.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/main.dart';

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
  bool viewUserList = true;
  bool userEdit = false;
  late bool isAdmin;
  User editUser = User.empty();

  bool isUserAdmin = false;
  String iconSelected = 'person';

  List<Widget> get pages => [profilePage(), editAccountPage(), deleteAccountPage()];
  List<Widget> get adminPages => [profilePage(), editAccountPage(), usersPage(), statePage(), deleteAccountPage()];
  List<Widget> get adminPagess => [statePage(), profilePage(), editAccountPage(), usersPage(), deleteAccountPage()];

  UserController userController = UserController();
  List<User> allUsers = [];
  List<TaskState> states = [];
  StateController stateController = StateController();

  Map<String, List<Task>> tasksFromUsers = {};

  TextEditingController userNameController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController mailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  //TextEditingController colorController = TextEditingController();
  String colorSelected = 'blue';

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
    if (isAdmin) {
      loadAdminData();
    }
    iconSelected = User.iconMap.entries.firstWhere((e) => e.value == myUser.icon.icon).key;
    isUserAdmin = isAdmin;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

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
                  _drawerItem(AppStrings.DELETEACC, isAdmin ? 4 : 2),
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
                    setState(() => selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    _railItem(Icons.person, AppStrings.PROFILE, false),
                    _railItem(Icons.settings, AppStrings.CONFIG, false),
                    if (isAdmin) _railItem(Icons.people, AppStrings.USERS_LABEL, allUsers.isEmpty),
                    if (isAdmin) _railItem(Icons.style, AppStrings.TASKSTATES, states.isEmpty),
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

  ListTile _drawerItem(String title, int index) {
    return ListTile(
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        if (index == 1) iconSelected = User.iconMap.entries.firstWhere((e) => e.value == myUser.icon.icon).key;
        Navigator.of(context).pop();
        setState(() => selectedIndex = index);
      },
    );
  }

  NavigationRailDestination _railItem(IconData icon, String label, bool disabled) {
    return NavigationRailDestination(icon: Icon(icon), label: Text(label), disabled: disabled);
  }

  Widget profilePage() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.PROFILE.toUpperCase(),
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
            ),
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

  Widget editAccountPage() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        //padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EDITAR PERFIL', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20)),
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
                      userNotAviableMessage();
                    } else if (isNew) {
                      User user = editUser.copyWith(
                        name: name,
                        surname: surname,
                        userName: userName,
                        mail: mail,
                        password: AppStrings.DEFAULT_PSWRD,
                      );
                      await userController.createAccountDB(user);
                      await loadUsers();

                      Navigator.pop(context);
                    } else {
                      bool confirmPswrd = await confirmPasword(false);

                      if (confirmPswrd) {
                        bool isEmpty = password.isEmpty;
                        //String pswrd = adminEdit ? editUser.password : (isEmpty ? editUser.password : User.hashPassword(password));
                        String pswrd = (adminEdit || isEmpty) ? editUser.password : User.hashPassword(password);
                        //bool ur = isAdmin ? true : isUserAdmin;
                        //bool ur = isAdmin || isUserAdmin;
                        bool ur = false;
                        if (isAdmin) {
                          if (myUser.userName == editUser.userName) {
                            ur = true;
                          } else {
                            //NO SE EDITA A ELL --> EDITA A UN ALTRE
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
                          await loadUsers();
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

  void userNotAviableMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Aquest usuari ja existeix'),
          content: Text('Prova a fer-ne un altre'),
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
            Text(
              viewUserList ? AppStrings.USERS_LABEL.toUpperCase() : editUser.userName,
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
            ),
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
                await loadUsers();
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
        itemCount: allUsers.length,
        itemBuilder: (context, index) {
          final user = allUsers[index];

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

  Widget statePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.TASKSTATES.toUpperCase(),
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
            ),
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
                              bool exists = await deleteState(state);
                              if (exists) {
                                stateController.deleteState(state.id);
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

  /*Form createState(TaskState state, bool isNew) {
    final formKey = GlobalKey<FormState>();

    // false si el usuari es igual (s edita a ell mateix)
    // true si es diferent (edita a algu altre ==> restablir contrasenya)
    //bool adminEdit = editUser.userName.compareTo(myUser.userName) != 0;

    String name = state.name;
    String id = state.id;
    String color = TaskState.colorName(state.color);

    clear();

    nameController = TextEditingController(text: editUser.name);

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

            Row(
              children: [
                Text('Color'),

                Container(width: 10),

                DropdownButton<String>(
                  value: colorSelected,
                  hint: Row(
                    children: [
                      Container(width: 24, height: 24, color: TaskState.colorMap['blue']),
                      const SizedBox(width: 8),
                      //Text('blue'),
                    ],
                  ),
                  items: TaskState.colorMap.keys.map((String colorName) {
                    return DropdownMenuItem<String>(
                      value: colorName,
                      child: Row(
                        children: [
                          const SizedBox(width: 1),
                          Container(width: 24, height: 24, color: TaskState.colorMap[colorName]),
                          const SizedBox(width: 1),
                          //Text(colorName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      colorSelected = newValue!;
                    });
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return TaskState.colorMap.keys.map((String colorName) {
                      return Container(width: 24, height: 24, color: TaskState.colorMap[colorName]);
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

                    TaskState updatedState = TaskState(id: id, name: name, color: TaskState.colorValue(color));
                    Navigator.pop(context, updatedState);
                  }
                },
                icon: Icon(Icons.abc),
                label: Text(!isNew ? 'Guardar canvis' : 'Crear estat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
*/

  Future<void> loadUsers() async {
    List<User> users = await userController.loadAllUsers();
    users.sort((user1, user2) => user1.userName.compareTo(user2.userName));

    users.removeWhere((user) {
      return user.userName == myUser.userName;
    });

    setState(() {
      allUsers = users;
    });
    await loadTask();
  }

  Future<void> loadTask() async {
    TaskController tk = TaskController();
    for (User user in allUsers) {
      await tk.loadTasksFromDB(user.userName);
      tasksFromUsers[user.userName] = tk.tasks;
    }
  }

  Future<void> loadAdminData() async {
    await loadUsers();
    await stateController.loadAllStates();
    states = stateController.states;
    setState(() {});
  }

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
                        stateNameExists(true);
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
                        stateNameExists(false);
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

  void stateNameExists(bool create) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Aquest estat ja existeix'),
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

  /*bool deleteState(TaskState tState) {
    nameController.clear();
    final result = showDialog<bool>(
      //showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar estat'),
          content: Text('Per  continuar, introdueixi el nom del estat: '),
          actions: <Widget>[
            TextField(
              controller: nameController,
              //obscureText: false,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),

            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tancar'),
            ),
            TextButton(
              onPressed: () {
                bool exists = nameController.text == tState.name;

                /*states.any((state) {
                  bool a = state.name == nameController.text;
                  print(a);
                  return a;
                });*/

                if (exists) {
                  stateController.deleteState(tState.id);
                  states.remove(tState);
                  setState(() {});
                }

                //logToDo('eliminar state', 'ConfigPage(taskStateList)');
                Navigator.of(context).pop();
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }*/

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
}

class StateForm extends StatefulWidget {
  final Function(TaskState)? createTState;
  final Function(TaskState)? editTState;

  final TaskState state;

  const StateForm({super.key, this.createTState, this.editTState, required this.state});

  @override
  StateFormState createState() => StateFormState();
}

class StateFormState extends State<StateForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  String validator = '';

  late String colorSelected;

  late bool isCreating;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.state.name);
    isCreating = widget.createTState != null;
    colorSelected = isCreating ? 'blue' : TaskState.colorName(widget.state.color);
  }

  @override
  Widget build(BuildContext context) {
    TaskState tState = TaskState.copy(widget.state);

    String name = tState.name;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
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

            SizedBox(height: 10),

            Row(
              children: [
                Container(width: 5),

                Text('Color', style: TextStyle(fontSize: 16)),

                Container(width: 10),

                DropdownButton<String>(
                  underline: const SizedBox(),
                  //borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(horizontal: 10),

                  /*hint: Row(
                    children: [
                      Container(width: 24, height: 24, color: TaskState.colorMap['blue']),
                      //const SizedBox(width: 8),
                      //Text('blue'),
                    ],
                  ),*/
                  value: colorSelected,
                  items: TaskState.colorMap.keys.map((String colorName) {
                    return DropdownMenuItem<String>(
                      value: colorName,
                      child: Container(width: 30, height: 30, color: TaskState.colorMap[colorName]),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue == null) {
                      colorSelected = 'null';
                    } else {
                      colorSelected = newValue;
                    }
                    setState(() {});
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return TaskState.colorMap.keys.map((String colorName) {
                      return Center(child: Container(width: 30, height: 30, color: TaskState.colorMap[colorName]));
                    }).toList();
                  },
                  menuMaxHeight: 300,
                ),
              ],
            ),

            SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Color? color;

                  if (colorSelected == 'null') {
                    color = null;
                  } else {
                    color = TaskState.colorValue(colorSelected);
                  }

                  TaskState updatedState = widget.state.copyWith(
                    name: name,
                    //color: TaskState.colorValue(colorSelected),
                    color: color,
                    setColor: true,
                  );

                  if (isCreating) {
                    widget.createTState!(updatedState);
                  } else if (widget.editTState != null) {
                    widget.editTState!(updatedState);
                  }

                  //Navigator.of(context).pop();
                }
              },
              icon: Icon(isCreating ? Icons.add : Icons.save_alt),
              label: Text(isCreating ? 'Crear' : 'Guardar canvis'),

              //icon: Icon(Icons.abc),
              //label: Text(!isNew ? 'Guardar canvis' : 'Crear estat'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
  }
}
