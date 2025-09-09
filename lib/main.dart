import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/utils/firebase_options.dart';
import 'package:to_do_list/utils/db_constants.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/to_do_page.dart';
import 'package:to_do_list/utils/user_role.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDoList',
      home: MyHomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => LogInPage();
}

class LogInPage extends State<MyHomePage> {
  String _userName = '', _pasword = '';
  bool _hasAccount = true;
  final _formKey = GlobalKey<FormState>();
  User retUser = User.empty();

  UserController userController = UserController();

  String control = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_hasAccount ? 'Iniciar sessió' : 'Crear compte'),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 50.0, vertical: 30.0),
        child: Column(
          children: [
            _hasAccount ? logInForm() : createAccountForm(),
            //Text(control),
            TextButton(
              onPressed: () {
                setState(() {
                  _hasAccount = !_hasAccount;
                  control = '';
                });
              },
              child: Text(
                _hasAccount
                    ? 'No tens compte? Registra\'t'
                    : 'Ja tens compte? Inicia sessió',
              ),
            ),
          ],
        ),
      ),
    );
  }

  logInForm() {
    TextEditingController nameController = TextEditingController();
    TextEditingController pswrdController = TextEditingController();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nom usuari',
              ),
              controller: nameController,

              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Es requereix del nom d\'usuari';
                }
                return null;
              },
              onSaved: (value) {
                _userName = value!;
              },
            ),
          ),

          TextFormField(
            controller: pswrdController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Contrasenya',
            ),

            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Es requereix de la contrasenya';
              }
              return null;
            },
            onSaved: (value) {
              _pasword = value!;
            },
          ),

          Container(
            margin: EdgeInsets.symmetric(vertical: 20),

            child: ElevatedButton.icon(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  pswrdController.clear();
                  nameController.clear();

                  try {
                    //createUser(_userName, _pasword);
                    if (await logIn(_userName, _pasword)) {
                      setState(() {
                        //control = 'Entrant a la pàgina';
                        control = '';
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyAppToDo(user: retUser),
                        ),
                      );
                    } else {
                      setState(() {
                        control =
                            'L\'usuari no s\'ha trobat, reviseu les dades';
                      });
                    }
                  } catch (e) {
                    print(e);
                  }
                }
              },
              label: Text('Inicia sessió'),
              //icon: Icon(Icons.login),
            ),
          ),
          Text(control),
        ],
      ),
    );
  }

  createAccountForm() {
    String name = '';
    String surname = '';
    String userName = '';
    String mail = '';
    String password = '';
    User user;

    TextEditingController nameController = TextEditingController();
    TextEditingController surnameController = TextEditingController();
    TextEditingController userNameController = TextEditingController();
    TextEditingController mailController = TextEditingController();
    TextEditingController paswordController = TextEditingController();

    return Form(
      key: _formKey,
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
                labelText: 'Contrasenya',
              ),
              controller: paswordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Aquest camp és obligatori';
                }
                return null;
              },
              onSaved: (value) {
                password = value!;
              },
            ),
          ),

          Container(
            margin: EdgeInsets.symmetric(vertical: 20),

            child: ElevatedButton.icon(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  user = User.parameter(
                    name,
                    surname,
                    userName,
                    mail,
                    password,
                    UserRole.USER,
                    User.getRandomIcon()
                  );
                  nameController.clear();
                  surnameController.clear();
                  userNameController.clear();
                  mailController.clear();
                  paswordController.clear();

                  int accountError = await userController.createAccountDB(user);

                  try {
                    if (accountError == DbConstants.USERNOTEXISTS) {
                      setState(() {
                        control = 'Usuari creat, inicia sessió';
                        _hasAccount = true;
                      });
                    } else if (accountError == DbConstants.USEREXISTS) {
                      setState(() {
                        control =
                            'El nom d\'usuari ja existeix, prova a fer-ne un altre';
                      });
                    } else {
                      setState(() {
                        control =
                            'Ha hagut un problema amb la base de dades, torna-ho a provar més tard';
                      });
                    }
                  } catch (e) {
                    print(e);
                  }
                }
              },
              label: Text('Crear compte'),
            ),
          ),
          Text(control),
        ],
      ),
    );
  }

  Future<bool> logIn(String username, String pswrd) async {
    bool ret = false;
    
    //User user = await getUser(username, pswrd);
    User user = User.empty();
    try {
      final lines = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: username)
          .where(DbConstants.PASSWORD, isEqualTo: User.hashPassword(pswrd))
          .get();

      if (lines.docs.isNotEmpty) {
        final doc = lines.docs.first;
        user = User.fromFirestore(doc, null);
      }

      ret = lines.docs.length == 1;
    } catch (e) {
      print('LOG IN $e');
      ret = false;
    }
    
    setState(() {
      retUser = user;
    });

    return ret;
  }

  /*Future<User> getUser(String username, String pswrd) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where('userName', isEqualTo: username)
          .where('password', isEqualTo: User.hashPassword(pswrd))
          .get();

      if (!db.docs.isEmpty) {
        final doc = db.docs.first;
        return User.fromFirestore(doc, null);
      }
    } catch (e) {
      print(e);
    }
    return User.empty();
  }*/

  //CODI PER A AFEGIR USUARI PROVA
  /*Future<bool> createAccount(User user) async {
    bool ret = false;

    try {
      await FirebaseFirestore.instance.collection(DbConstants.USER).doc('prova').set({
        'name': user.getName(),
        'surname': user.getSurname(),
        'userName': user.getUserName(),
        'mail': user.getMail(),
        'password': user.getPassword(),
      });
      ret = true;
    } catch (e) {
      print('CREATE ACCOUNT: $e');
      ret = false;
    }

    return ret;
  }*/
}
