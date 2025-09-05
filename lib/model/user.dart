import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String _name;
  String _surname;
  String _userName;
  String _mail;
  String _password;

  User.empty()
    : this._name = '',
      this._surname = '',
      this._userName = '',
      this._mail = '',
      this._password = '';
  User.parameter(
    String name,
    String surname,
    String userName,
    String mail,
    String password,
  ) : this._name = name,
      this._surname = surname,
      this._userName = userName,
      this._mail = mail,
      this._password = password;
  User.copy(User user)
    : this._name = user._name,
      this._surname = user._surname,
      this._userName = user._userName,
      this._mail = user._mail,
      this._password = user._password;

  User copyWith({
    String? name,
    String? surname,
    String? userName,
    String? mail,
    String? password,
  }) {
    return User(
      name: name ?? this.name,
      surname: surname ?? this.surname,
      userName: userName ?? this.userName,
      mail: mail ?? this.mail,
      password: password ?? this.password,
    );
  }

  String get name => this._name;
  String get surname => this._surname;
  String get userName => this._userName;
  String get mail => this._mail;
  String get password => this._password;

  @override
  String toString() {
    String str = '';
    str += 'Nom: $_name $_surname \n';
    str += 'Nom d\'usuari: $_userName \n';
    str += 'Correu: $_mail \n';
    str += 'Contrasenya: $_password \n';
    return str;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': _name,
      'surname': _surname,
      'userName': _userName,
      'mail': _mail,
      'password': _password,
    };
  }

  User({
    required String name,
    required String surname,
    required String userName,
    required String mail,
    required String password,
  }) : _password = password,
       _mail = mail,
       _userName = userName,
       _surname = surname,
       _name = name;

  factory User.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return User(
      name: data?['name'] ?? '',
      surname: data?['surname'] ?? '',
      userName: data?['userName'] ?? '',
      mail: data?['mail'] ?? '',
      password: data?['password'] ?? '',
    );
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
