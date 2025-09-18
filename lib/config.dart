import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/utils/error_messages.dart';
import 'package:to_do_list/utils/firebase_options.dart';
import 'package:to_do_list/utils/app_strings.dart';
import 'package:to_do_list/utils/user_role.dart';
import 'package:to_do_list/model/user.dart';
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
    UserRole.ADMIN,
  );

  runApp(MyAppConfig(user: userProva));
}

class MyAppConfig extends StatelessWidget {
  final User user;
  const MyAppConfig({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDoList',
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
  List<Widget> get adminPages => [profilePage(), editAccountPage(), usersPage(), deleteAccountPage()];

  UserController userController = UserController();
  List<User> allUsers = [];

  @override
  void initState() {
    super.initState();
    myUser = User.copy(widget.user);
    isAdmin = UserRole.isAdmin(myUser.userRole);
    if (isAdmin) loadUsers();
  }

  Future<void> loadUsers() async {
    List<User> users = await userController.loadAllUsers();
    users.sort((user1, user2) => user1.userName.compareTo(user2.userName));

    users.removeWhere((user) {
      return user.userName == myUser.userName;
    });

    setState(() {
      allUsers = users;
      iconSelected = User.iconMap.entries.firstWhere((e) => e.value == myUser.icon.icon).key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: isWide
          ? AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text('Configuració'))
          : AppBar(
              title: Text('Configuració'),
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
                  _drawerItem('Perfil', 0),
                  _drawerItem('Configuració', 1),
                  if (isAdmin) _drawerItem('Usuaris', 2),
                  _drawerItem('Eliminar compte', isAdmin ? 3 : 2),
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
                    setState(() => selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    _railItem(Icons.person, 'Perfil'),
                    _railItem(Icons.settings, 'Configuració'),
                    if(isAdmin) _railItem(Icons.people, 'Usuaris'),
                    _railItem(Icons.delete, 'Eliminar\ncompte'),
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
        Navigator.of(context).pop(); // Cierra el drawer
        setState(() => selectedIndex = index);
      },
    );
  }

  NavigationRailDestination _railItem (IconData icon, String label){
    return NavigationRailDestination(icon: Icon(icon), label: Text(label));
  }

  Widget profilePage() {
    return Align(alignment: Alignment.topCenter, child: SingleChildScrollView(child:  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PERFIL', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20)),
        SizedBox(height: 20),
        Table(
          columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          children: [
            buildTableRow('Nom:', myUser.name),
            buildTableRow('Cognom:', myUser.surname),
            buildTableRow('Nom d\'usuari:', myUser.userName),
            buildTableRow('Correu:', myUser.mail),
          ],
        ),
      ],
    )));
  }

  TableRow buildTableRow(String label, String value) {
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

  editAccount(User editUser, bool isNew) {
    final formKey = GlobalKey<FormState>();

    // false si el usuari es igual (s edita a ell mateix)
    // true si es diferent (edita a algu altre ==> restablir contrasenya)
    bool adminEdit = editUser.userName.compareTo(myUser.userName) != 0;

    bool roleChanged = false;

    String name = editUser.name;
    String surname = editUser.surname;
    String userName = editUser.userName;
    String mail = editUser.mail;
    String password = editUser.password;

    TextEditingController nameController = TextEditingController(text: editUser.name);
    TextEditingController surnameController = TextEditingController(text: surname);
    TextEditingController userNameController = TextEditingController(text: editUser.userName);
    TextEditingController mailController = TextEditingController(text: editUser.mail);

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
                  }
                  return null;
                },
                onSaved: (value) {
                  mail = value!;
                },
              ),
            ),

            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: isNew ? 'Contrasenya' : 'Nova contrasenya',
                ),
                obscureText: true,
                readOnly: adminEdit,
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

            if (isAdmin && editUser.userName != myUser.userName)
              Row(
                children: [
                  Text('Permisos d\'administrador'),

                  Container(width: 10),

                  Switch(
                    //value: isUserAdmin,
                    value: UserRole.isAdmin(editUser.userRole),
                    onChanged: (bool value) async {
                      setState(() {
                        if (value) {
                          editUser.userRole = UserRole.ADMIN;
                        } else {
                          editUser.userRole = UserRole.USER;
                        }
                        roleChanged = !roleChanged;
                      });
                    },
                  ),
                ],
              ),

            //if (isAdmin)
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

                    if (isNew) {
                      if (!usernameExists) {
                        User user = editUser.copyWith(
                          name: name,
                          surname: surname,
                          userName: userName,
                          mail: mail,
                          password: User.hashPassword(password),
                        );
                        await userController.createAccountDB(user);
                        await loadUsers();

                        Navigator.pop(context, user);
                      }
                    } else {
                      if (userName != editUser.userName && usernameExists) {
                        userNotAviableMessage();
                      } else {
                        bool confirmPswrd = await confirmPasword(false);

                        if (confirmPswrd) {
                          bool isEmpty = password.isEmpty;

                          User updatedUser = editUser.copyWith(
                            name: name,
                            surname: surname,
                            userName: userName,
                            mail: mail,
                            password: !isEmpty ? User.hashPassword(password) : editUser.password,
                            icon: Icon(User.iconMap[iconSelected]),
                          );
                          try {
                            await userController.updateProfileDB(updatedUser, editUser);
                          } catch (e) {
                            logError('EDIT ACCOUNT configPage', e);
                          }
                          //user = updatedUser;

                          setState(() {
                            //selectedIndex = 0;
                            viewUserList = true;
                            userEdit = false;
                            //editMode = false;
                          });

                          if (roleChanged) {
                            final uR = !UserRole.isAdmin(editUser.userRole) ? UserRole.USER : UserRole.ADMIN;
                            await userController.giveAdmin(editUser, uR);
                          }

                          if (!adminEdit) {
                            Navigator.pop(context, updatedUser);
                          } else {
                            await loadUsers();
                          }
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

  userNotAviableMessage() {
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
    final TextEditingController passwordController = TextEditingController();

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
          child: Text('ELIMINAR COMPTE', style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }

  Widget usersPage() {
    //loadUsers();
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
              viewUserList ? 'USUARIS' : editUser.userName,
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

  userList() {
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
                      onPressed: () {
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
                          viewUserList = false;
                          userEdit = true;
                          editUser = allUsers[index];
                          //iconSelected = editUser.icon;
                          iconSelected = User.iconMap.entries.firstWhere((e) => e.value == editUser.icon.icon).key;
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

  viewUser(bool edit, User user) {
    return edit
        ? editAccount(user, false)
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Table(
                  columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                  children: [
                    buildTableRow('Nom:', user.name),
                    buildTableRow('Cognom:', user.surname),
                    buildTableRow('Nom d\'usuari:', user.userName),
                    buildTableRow('Correu:', user.mail),
                    buildTableRow('Rol:', (UserRole.isAdmin(user.userRole)) ? 'Administrador' : 'Usuari'),
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
    final TextEditingController userNameController = TextEditingController();

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
