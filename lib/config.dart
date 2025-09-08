import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/utils/db_constants.dart';

import 'package:to_do_list/utils/firebase_options.dart';
//import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/main.dart';
import 'package:to_do_list/utils/user_role.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        //colorScheme: (user.userRole==UserRole.USER) ? ColorScheme.fromSeed(seedColor: Colors.deepPurple) : ColorScheme.fromSeed(seedColor: Colors.amber),
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
  //bool editMode = false;
  bool viewUserList = true;
  bool userEdit = false;
  late bool isAdmin;
  User editUser = User.empty();

  List<Widget> get pages => [
    profilePage(),
    editAccountPage(),
    deleteAccountPage(),
  ];
  List<Widget> get adminPages => [
    profilePage(),
    editAccountPage(),
    usersPage(),
    deleteAccountPage(),
  ];

  UserController userController = UserController();
  List<User> allUsers = [];

  @override
  void initState() {
    super.initState();
    myUser = User.copy(widget.user);
    isAdmin = myUser.userRole == UserRole.ADMIN;
    loadUsers();
  }

  Future<void> loadUsers() async {
    List<User> users = await UserController.loadAllUsers();
    users.sort((user1, user2) => user1.userName.compareTo(user2.userName));

    users.removeWhere((user) {
      return user.userName == myUser.userName;
    });

    setState(() {
      allUsers = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color pageColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Configuració'),
      ),

      body: Container(
        margin: const EdgeInsets.all(15),
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.person),
                  label: const Text('Perfil'),
                  selectedIcon: Icon(Icons.person, color: pageColor),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings),
                  label: const Text('Configuració'),
                  selectedIcon: Icon(Icons.settings, color: pageColor),
                ),

                if (isAdmin)
                  NavigationRailDestination(
                    icon: const Icon(Icons.people),
                    label: const Text('Usuaris'),
                    selectedIcon: Icon(Icons.people, color: pageColor),
                  ),

                const NavigationRailDestination(
                  icon: Icon(Icons.delete),
                  label: Text('Eliminar\ncompte'),
                  selectedIcon: Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            VerticalDivider(width: 30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isAdmin
                    ? adminPages[selectedIndex]
                    : pages[selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profilePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERFIL',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 20,
          ),
        ),
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
    );
  }

  TableRow buildTableRow(String label, String value) {
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

  Widget editAccountPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EDITAR PERFIL',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 20,
          ),
        ),
        SizedBox(height: 20),
        /*editMode
            ? */
        editAccount(myUser),
        /*: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        editMode = true;
                      });
                    },
                    label: Text('Editar perfil'),
                    icon: Icon(Icons.edit),
                  ),
                  /*TextButton.icon(
                    onPressed: () {
                      setState(() {
                        editPswrd = true;
                      });
                    },
                    label: Text('Editar contrasenya'),
                    icon: Icon(Icons.password),
                  ),*/
                ],
              ),*/
      ],
    );
  }

  editAccount(User editUser) {
    final formKey = GlobalKey<FormState>();

    // false si el usuari es igual (s edita a ell mateix)
    // true si es diferent (edita a algu altre ==> restablir contrasenya)
    bool adminEdit = editUser.userName.compareTo(myUser.userName) != 0;

    String name = editUser.name;
    String surname = editUser.surname;
    String userName = editUser.userName;
    String mail = editUser.mail;
    String password = editUser.password;

    TextEditingController nameController = TextEditingController(
      text: editUser.name,
    );
    TextEditingController surnameController = TextEditingController(
      text: surname,
    );
    TextEditingController userNameController = TextEditingController(
      text: editUser.userName,
    );
    TextEditingController mailController = TextEditingController(
      text: editUser.mail,
    );
    //TextEditingController paswordController = TextEditingController();

    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            child: TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nom',
              ),
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
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Cognom',
              ),
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
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nom d\'usuari',
              ),
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
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Correu',
              ),
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

          /*?adminEdit
              ? null
              : */
          Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            child: TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nova contrasenya',
              ),
              obscureText: true,
              //readOnly: adminEdit,
              //controller: paswordController,
              /*validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Aquest camp és obligatori';
                }
                return null;
              },*/
              onSaved: (value) {
                password = value!;
              },
            ),
          ),

          Container(
            margin: EdgeInsets.symmetric(vertical: 20),

            child: ElevatedButton.icon(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  if (userName != editUser.userName &&
                      await userNameExists(userName)) {
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
                        password: !isEmpty
                            ? User.hashPassword(password)
                            : editUser.password,
                      );
                      try {
                        await updateProfileDB(updatedUser, editUser);
                      } catch (e) {
                        print(e);
                      }
                      //user = updatedUser;

                      setState(() {
                        selectedIndex = 0;
                        viewUserList = true;
                        userEdit = false;
                        //editMode = false;
                      });

                      if (!adminEdit) {
                        Navigator.pop(context, updatedUser);
                      }
                    }

                    /*nameController.clear();
                    surnameController.clear();
                    userNameController.clear();
                    mailController.clear();
                    paswordController.clear();*/
                  }
                }
              },
              label: Text('Guardar canvis'),
            ),
          ),
        ],
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
                    final isValid = await isPasword(passwordController.text);
                    Navigator.of(context).pop(isValid);
                  },
                  style: deleteAcc
                      ? ButtonStyle(
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return Colors.red;
                                }
                                return Theme.of(context).colorScheme.primary;
                              }),
                        )
                      : null,
                  child: Text('Confirmar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
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

  Future<bool> isPasword(String pswrd) async {
    bool ret = false;

    try {
      final lines = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: myUser.userName)
          .where(DbConstants.PASSWORD, isEqualTo: User.hashPassword(pswrd))
          .get();
      ret = lines.docs.length == 1;
    } catch (e) {
      print(e);
      ret = false;
    }

    return ret;
  }

  Future<bool> userNameExists(String userName) async {
    final db = await FirebaseFirestore.instance
        .collection(DbConstants.USER)
        .where(DbConstants.USERNAME, isEqualTo: userName)
        .get();
    return db.docs.length == 1;
  }

  Future<void> updateProfileDB(User updatedUser, User oldUser) async {
    String doc;
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: oldUser.userName)
          .get();
      doc = db.docs.first.id;

      await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .doc(doc)
          .update(updatedUser.toFirestore());

      if (oldUser.userName != updatedUser.userName) {
        await updateUserTask(updatedUser);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateUserTask(User updatedUser) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.USERNAME, isEqualTo: myUser.userName)
          .get();

      final docs = db.docs;

      for (final doc in docs) {
        final taskId = doc[DbConstants.TASKID] as String;

        await FirebaseFirestore.instance
            .collection(DbConstants.USERTASK)
            .doc(doc.id)
            .update({
              DbConstants.USERNAME: updatedUser.userName,
              DbConstants.TASKID: taskId,
            });
      }
    } catch (e) {
      print(e);
    }
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
              await userController.deleteUser(widget.user);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyApp()),
              );
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
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary,
                ),

                //icon: Icon(Icons.arrow_back, color: Colors.red),
              ),
            Text(
              viewUserList ? 'USUARIS' : '${editUser.userName}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 20,
              ),
            ),
          ],
        ),

        SizedBox(height: 20),

        viewUserList ? userList() : viewUser(userEdit, editUser),
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
            //color: Theme.of(context).colorScheme.inversePrimary,
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.all(5),

              leading: Text('    ${index + 1}'),
              title: Text(user.userName),
              subtitle: Text(''),

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
                        });
                      },
                      icon: Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () {
                        userController.resetPswrd(allUsers[index]);
                      },
                      icon: Icon(Icons.password),
                      tooltip: 'Reiniciar contrasenya',
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
    UserRole uR = user.userRole == UserRole.ADMIN ? UserRole.USER : UserRole.ADMIN;
    return edit
        ? editAccount(user)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Table(
                columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
                children: [
                  buildTableRow('Nom:', user.name),
                  buildTableRow('Cognom:', user.surname),
                  buildTableRow('Nom d\'usuari:', user.userName),
                  buildTableRow('Correu:', user.mail),
                  buildTableRow(
                    'Rol:',
                    (user.userRole == UserRole.ADMIN)
                        ? 'Administrador'
                        : 'Usuari',
                  ),
                ],
              ),
              Container(height: 10),
              //if (user.userRole == UserRole.USER)
              ElevatedButton(
                onPressed: () {
                  userController.giveAdmin(user, uR);
                  setState(() {
                    selectedIndex = 2;
                    viewUserList = true;
                    //userEdit = false;
                    user = user.copyWith(userRole: uR);
                    loadUsers();
                  });
                },
                child: Text(
                  (user.userRole == UserRole.ADMIN)
                      ? 'Treure permís d\'administrador'
                      : 'Donar permís d\'administrador',
                ),
                //child: Text('Donar permís d\'administrador'),
              ),
            ],
          );
  }
}
