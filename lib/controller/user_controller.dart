import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/controller/history_controller.dart';

import 'package:to_do_list/controller/notification_controller.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/utils/const/app_strings.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/model/user.dart';

class UserController {
  List<User> users;

  UserController() : users = [];

  Future<int> createAccountDB(User user, User creator) async {
    int ret = DbConstants.USEREXISTS;
    User newUser = user.copyWith(password: User.hashPassword(user.password));

    if (!await userNameExists(newUser.userName)) {
      try {
        final docRef = await FirebaseFirestore.instance.collection(DbConstants.USER).add(newUser.toFirestore());
        user.id = docRef.id;
        newUser.id = docRef.id;
        ret = DbConstants.USERNOTEXISTS;

        await HistoryController.createUser(newUser, creator);
      } catch (e) {
        logError('CREATE ACCOUNT', e);
        ret = DbConstants.DATABASEERROR;
      }
    }

    return ret;
  }

  Future<bool> userNameExists(String userName) async {
    if (users.isNotEmpty) {
      return users.any((u) => u.userName.trim().toLowerCase() == userName.trim().toLowerCase());
    } else {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      //return db.docs.length == 1;
      return db.docs.isNotEmpty;
    }
  }

  Future<void> deleteUser(User user) async {
    TaskController taskController = TaskController();
    try {
      await taskController.deleteUserTaskRelationsByUser(user);
      await _deleteUser(user);
      await NotificationController().deleteNotificationByUser(user);
    } catch (e) {
      logError('DELETE USER', e); 
    }
  }

  Future<void> _deleteUser(User user) async {
    try {
      final db = await _getUserByUserName(user.userName);
      user.deleted = true;
      if (db.docs.isNotEmpty) {
        await db.docs.first.reference.update(user.toFirestore());
      }
    } catch (e) {
      logError('_DELETE USER', e);
    }
  }

  Future<User> getUserByUserName(String userName) async {
    try {
      final db = await _getUserByUserName(userName);
      if (db.docs.isNotEmpty) {
        return User.fromFirestore(db.docs.first, null);
      }
    } catch (e) {
      logError("GET USER BY USER NAME", e);
    }
    return User.empty();
  }

  Future<List<User>> loadAllUsers(bool loadDeletd) async {
    List<User> loadedUsers = [];
    User user;

    try {
      final db = await FirebaseFirestore.instance.collection(DbConstants.USER).where(DbConstants.DELETED, isEqualTo: loadDeletd).get();
      final docs = db.docs;

      for (var doc in docs) {
        if (doc.exists) {
          user = User.fromFirestore(doc, null);
          loadedUsers.add(user);
        }
      }
    } catch (e) {
      logError('LOAD ALL USERS', e);
    }

    users = loadedUsers;

    return loadedUsers;
  }

  Future<void> resetPswrd(User user) async {
    try {
      user.setPassword(User.hashPassword(AppStrings.DEFAULT_PSWRD));
      await _updateUserById(user);
    } catch (e) {
      logError('RESET PASSWORD', e);
    }
  }

  Future<bool> userHasTask(User user, String taskId) async {
    bool ret = false;
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .where(DbConstants.USERID, isEqualTo: user.id)
          .get();

      if (db.docs.isNotEmpty) {
        ret = true;
      }
    } catch (e) {
      logError('USER HAS TASK', e);
    }
    return ret;
  }

  Future<void> updateProfileDB(User updatedUser, User oldUser, User creator) async {
    try {
      await _updateUserById(updatedUser);
      await HistoryController.updateUser(oldUser, updatedUser, creator);
    } catch (e) {
      logError('UPDATE PROFILE DB', e);
    }
  }

  Future<bool> isPasword(String userName, String pswrd) async {
    bool ret = false;

    try {
      final lines = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .where(DbConstants.PASSWORD, isEqualTo: User.hashPassword(pswrd))
          .get();
      ret = lines.docs.length == 1;
    } catch (e) {
      logError('IS PASSWORD', e);
      ret = false;
    }

    return ret;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getUserByUserName(String userName) async {
    return await FirebaseFirestore.instance
        .collection(DbConstants.USER)
        .where(DbConstants.USERNAME, isEqualTo: userName)
        .get();
  }

  Future<User> getUserById(String userId) async {
    try {
      final db = await FirebaseFirestore.instance.collection(DbConstants.USER).doc(userId).get();
      return User.fromFirestore(db, null);
    } catch (e) {
      logError("GET USER BY ID", e);
    }
    return User.empty();
  }

  Future<void> _updateUserById(User user) async {
    await FirebaseFirestore.instance.collection(DbConstants.USER).doc(user.id).update(user.toFirestore());
  }

  Future<bool> logIn(String userName, String password) async {
    bool ret = false;
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .where(DbConstants.PASSWORD, isEqualTo: User.hashPassword(password))
          .where(DbConstants.DELETED, isEqualTo: false)
          .get();

      if (db.docs.isNotEmpty) {
        ret = true;
      }
    } catch (e) {
      logError("LOG IN", e);
    }
    return ret;
  }
}
