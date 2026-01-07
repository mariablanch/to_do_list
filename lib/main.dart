// ignore_for_file: use_build_context_synchronously

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/utils/const/firebase_options.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/user_role.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/to_do_page.dart';

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
      title: "Iniciar Sessió",
      home: MyHomePage(),
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale("en"), // English
        Locale("es"), // Spanish
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => LogInPage();
}

class LogInPage extends State<MyHomePage> {
  String _userName = "", _pasword = "";
  bool _hasAccount = true;
  final _formKey = GlobalKey<FormState>();
  User retUser = User.empty();

  UserController userController = UserController();

  String control = "";
  bool showPassword = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController pswrdController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController mailController = TextEditingController();
  final TextEditingController paswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    pswrdController.dispose();
    surnameController.dispose();
    userNameController.dispose();
    mailController.dispose();
    paswordController.dispose();
    super.dispose();
  }

  void clear() {
    nameController.clear();
    pswrdController.clear();
    surnameController.clear();
    userNameController.clear();
    mailController.clear();
    paswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_hasAccount ? "Iniciar sessió" : "Crear compte"),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 50, vertical: 30),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _hasAccount ? logInForm() : createAccountForm(),
              //Text(control),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasAccount = !_hasAccount;
                    control = "";
                    showPassword = false;
                    clear();
                  });
                },
                child: Text(_hasAccount ? "No tens compte? Registra't" : "Ja tens compte? Inicia sessió"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Form logInForm() {
    //TextEditingController nameController = TextEditingController();
    //TextEditingController pswrdController = TextEditingController();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: TextFormField(
              decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Nom usuari"),
              controller: nameController,

              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Es requereix del nom d'usuari";
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
            decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Contrasenya"),

            obscureText: !showPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Es requereix de la contrasenya";
              }
              return null;
            },
            onFieldSubmitted: (value) => logIn(),
            onSaved: (value) {
              _pasword = value!;
            },
          ),

          Container(
            margin: EdgeInsets.symmetric(vertical: 20),

            child: ElevatedButton.icon(
              onPressed: () async => logIn(),
              label: Text("Iniciar sessió"),
              //icon: Icon(Icons.login),
            ),
          ),
          Text(control),
        ],
      ),
    );
  }

  Form createAccountForm() {
    String name = "";
    String surname = "";
    String userName = "";
    String mail = "";
    String password = "";
    User user;

    return Form(
      key: _formKey,
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
              keyboardType: TextInputType.emailAddress,
              controller: mailController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Aquest camp és obligatori";
                } else if (!value.contains("@")) {
                  return "No té el format adequat";
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
              decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Contrasenya"),
              controller: paswordController,
              obscureText: !showPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Aquest camp és obligatori";
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
                  //user = User.parameter(name, surname, userName, mail, password, UserRole.USER);
                  user = User(
                    id: "",
                    name: name,
                    surname: surname,
                    userName: userName,
                    mail: mail,
                    password: password,
                    userRole: UserRole.USER,
                    deleted: false,
                    iconName: Icon(User.getRandomIcon()),
                  );

                  clear();

                  int accountError = await userController.createAccountDB(user, user);

                  try {
                    if (accountError == DbConstants.USERNOTEXISTS) {
                      control = "Usuari creat, inicia sessió";
                      _hasAccount = true;
                      setState(() {});
                    } else if (accountError == DbConstants.USEREXISTS) {
                      setState(() {
                        control = "El nom d'usuari ja existeix, prova a fer-ne un altre";
                      });
                    } else {
                      setState(() {
                        control = "Ha hagut un problema amb la base de dades, torna-ho a provar més tard";
                      });
                    }
                  } catch (e) {
                    logError("CREATE ACCOUNT FORM", e);
                  }
                }
              },
              label: Text("Crear compte"),
            ),
          ),
          Text(control),
        ],
      ),
    );
  }

  Future<void> logIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        if (await userController.logIn(_userName, _pasword)) {
          setState(() {
            control = "";
          });

          retUser = await userController.getUserByUserName(_userName);

          clear();
          Navigator.push(context, MaterialPageRoute(builder: (context) => MyAppToDo(user: retUser)));
        } else {
          setState(() {
            control = "L'usuari no s'ha trobat, reviseu les dades";
          });
        }
      } catch (e) {
        logError("LOG IN FORM", e);
      }
    }
  }
}
