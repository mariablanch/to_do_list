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
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        colorScheme: (user.userRole==UserRole.USER) ? ColorScheme.fromSeed(seedColor: Colors.deepPurple) : ColorScheme.fromSeed(seedColor: Colors.amber),
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
  bool editMode = false;
  late bool isAdmin;

  List<Widget> get pages => [profile(), editAccount(), deleteAccount()];
  List<Widget> get adminPages => [profile(), editAccount(), viewUsers(), deleteAccount()];

  UserController userController = UserController();

  @override
  void initState() {
    super.initState();
    myUser = User.copy(widget.user);
    isAdmin = myUser.userRole == UserRole.ADMIN;
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

                ?isAdmin ? NavigationRailDestination(
                  icon: const Icon(Icons.people),
                  label: const Text('Usuaris'),
                  selectedIcon: Icon(Icons.settings, color: pageColor),
                ) : null,

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
                child: isAdmin ? adminPages[selectedIndex] : pages[selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERFIL',
          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
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

  Widget editAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EDITAR PERFIL',
          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20),
        ),
        SizedBox(height: 20),
        /*editMode
            ? */editProfile()
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

  editProfile() {
    final formKey = GlobalKey<FormState>();

    String name = myUser.name;
    String surname = myUser.surname;
    String userName = myUser.userName;
    String mail = myUser.mail;
    String password = myUser.password;

    TextEditingController nameController = TextEditingController(
      text: myUser.name,
    );
    TextEditingController surnameController = TextEditingController(
      text: surname,
    );
    TextEditingController userNameController = TextEditingController(
      text: myUser.userName,
    );
    TextEditingController mailController = TextEditingController(
      text: myUser.mail,
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

          Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            child: TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nova contrasenya',
              ),
              obscureText: true,
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

                  if (userName != myUser.userName &&
                      await userNameExists(userName)) {
                    userNotAviable();
                  } else {
                    bool confirmPswrd = await confirmPasword(false);

                    if (confirmPswrd) {
                      bool isEmpty = password.isEmpty;

                      User updatedUser = myUser.copyWith(
                        name: name,
                        surname: surname,
                        userName: userName,
                        mail: mail,
                        password: !isEmpty
                            ? User.hashPassword(password)
                            : myUser.password,
                      );
                      try {
                        await updateProfileDB(updatedUser);
                      } catch (e) {
                        print(e);
                      }
                      //user = updatedUser;

                      setState(() {
                        selectedIndex = 0;
                        editMode = false;
                      });

                      Navigator.pop(context, updatedUser);
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

  userNotAviable() {
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

  Future<void> updateProfileDB(User updatedUser) async {
    String doc;
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: myUser.userName)
          .get();
      doc = db.docs.first.id;

      await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .doc(doc)
          .update(updatedUser.toFirestore());

      if (myUser.userName != updatedUser.userName) {
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

  Widget deleteAccount() {
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

  Widget viewUsers(){
    return Column();
  }

  /*Future<List<Task>> loadTasksFromDB() async {
    List<Task> loadedTasks = [];
    Task task;
    try {
      User user = User.copy(widget.user);
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.USERNAME, isEqualTo: user.userName)
          .get();

      List<String> taskIDs = db.docs
          .map((doc) => doc[DbConstants.TASKID] as String)
          .toList();

      for (String id in taskIDs) {
        final doc = await FirebaseFirestore.instance
            .collection(DbConstants.USERTASK)
            .doc(id)
            .get();

        if (doc.exists) {
          task = Task.fromFirestore(doc, null);
          loadedTasks.add(task);
        }
      }

      loadedTasks.sort();

      return loadedTasks;
    } catch (e) {
      print(e);
      return [];
    }
  }
*/
}
