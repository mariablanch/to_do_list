// ignore_for_file: unnecessary_this

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/user_role.dart';

class User implements Comparable<User> {
  String _name;
  String _surname;
  String _userName;
  String _mail;
  String _password;
  UserRole _userRole;
  Icon _icon;

  static final Map<String, IconData> iconMap = {
    'home': Icons.home,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'person': Icons.person,
    'cake': Icons.cake,
    'pets': Icons.pets,
    'alarm': Icons.alarm,
    'settings': Icons.settings,
    'phone': Icons.phone,
    'music_note': Icons.music_note,
    'school': Icons.school,
    'snowshoeing_sharp': Icons.snowshoeing_sharp,
    'ramen_dining': Icons.ramen_dining,
    'ac_unit': Icons.ac_unit,
    'filter_vintage': Icons.filter_vintage,
    'currency_bitcoin': Icons.currency_bitcoin,
    'park': Icons.park,
    'local_play_sharp': Icons.local_play_sharp,
    'theater_comedy': Icons.theater_comedy,
    'check': Icons.check,
    'mood_rounded': Icons.mood_rounded,
    'nightlight_round': Icons.nightlight_round,
  };

  static IconData getRandomIcon() {
    Random random = Random();

    final icons = <IconData>[
      Icons.home,
      Icons.star,
      Icons.favorite,
      Icons.person,
      Icons.cake,
      Icons.pets,
      Icons.alarm,
      Icons.settings,
      Icons.phone,
      Icons.music_note,
      Icons.school,
      Icons.snowshoeing_sharp,
      Icons.ramen_dining,
      Icons.ac_unit,
      Icons.filter_vintage,
      Icons.currency_bitcoin,
      Icons.park,
      Icons.local_play_sharp,
      Icons.theater_comedy,
      Icons.check,
      Icons.mood_rounded,
      Icons.nightlight_round,
    ];

    final randomIconData = icons[random.nextInt(icons.length)];

    return randomIconData;
  }

  User.empty()
    : this._name = '',
      this._surname = '',
      this._userName = '',
      this._mail = '',
      this._password = '',
      this._userRole = UserRole.USER,
      this._icon = Icon(getRandomIcon());
  /*User.parameter(
    String name,
    String surname,
    String userName,
    String mail,
    String password,
    UserRole role
  ) : this._name = name,
      this._surname = surname,
      this._userName = userName,
      this._mail = mail,
      this._password = password,
      this._userRole = role,
      this._icon = Icon(getRandomIcon());*/
  User.copy(User user)
    : this._name = user.name,
      this._surname = user.surname,
      this._userName = user.userName,
      this._mail = user.mail,
      this._password = user.password,
      this._userRole = user.userRole,
      this._icon = user.icon;

  User copyWith({
    String? name,
    String? surname,
    String? userName,
    String? mail,
    String? password,
    UserRole? userRole,
    Icon? icon,
  }) {
    return User(
      name: name ?? this.name,
      surname: surname ?? this.surname,
      userName: userName ?? this.userName,
      mail: mail ?? this.mail,
      password: password ?? this.password,
      userRole: userRole ?? this.userRole,
      iconName: icon ?? this.icon,
    );
  }

  String get name => this._name;
  String get surname => this._surname;
  String get userName => this._userName;
  String get mail => this._mail;
  String get password => this._password;
  UserRole get userRole => this._userRole;
  Icon get icon => this._icon;

  void setPassword(String password) => _password = password;

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
      DbConstants.PASSWORD: _password,
      DbConstants.USERROLE: _userRole.name,
      DbConstants.ICON: iconMap.entries.firstWhere((line) => line.value == _icon.icon).key,
    };
  }

  User({
    required String name,
    required String surname,
    required String userName,
    required String mail,
    required String password,
    required UserRole userRole,
    required Icon iconName,
  }) : _password = password,
       _mail = mail,
       _userName = userName,
       _surname = surname,
       _name = name,
       _userRole = userRole,
       _icon = iconName;

  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    final iconName = data?[DbConstants.ICON] ?? 'person';

    return User(
      name: data?['name'] ?? '',
      surname: data?['surname'] ?? '',
      userName: data?['userName'] ?? '',
      mail: data?['mail'] ?? '',
      password: data?['password'] ?? '',
      userRole: UserRole.values.firstWhere(
        (uR) => uR.name.toLowerCase() == (data?[DbConstants.USERROLE] ?? '').toString().toLowerCase(),
      ),
      iconName: Icon(iconMap[iconName] ?? Icons.person),
    );
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  int compareTo(User other) {
    int comp = this.name.compareTo(other.name);
    if (comp == 0) {
      comp = this.surname.compareTo(other.surname);
      if (comp == 0) comp = this.userRole.index - other.userRole.index;
    }
    return comp;
  }

  @override
  int get hashCode => userName.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.userName == userName;
  }
}
