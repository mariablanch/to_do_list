import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:to_do_list/controller/notification_controller.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/utils/error_messages.dart';
import 'package:to_do_list/utils/db_constants.dart';
import 'package:to_do_list/utils/user_role.dart';
import 'package:to_do_list/model/user.dart';

class UserController {
  List<User> users;

  UserController() : users = [];

  Future<int> createAccountDB(User user) async {
    int ret = DbConstants.USEREXISTS;
    User newUser = user.copyWith(password: User.hashPassword(user.password));

    if (!await userNameExists(newUser.userName)) {
      try {
        await FirebaseFirestore.instance.collection(DbConstants.USER).add(newUser.toFirestore());
        ret = DbConstants.USERNOTEXISTS;
      } catch (e) {
        logError('CREATE ACCOUNT', e);
        ret = DbConstants.DATABASEERROR;
      }
    }

    return ret;
  }

  Future<bool> userNameExists(String userName) async {
    final db = await _getUserByUserName(userName);

    //return db.docs.length == 1;
    return db.docs.isNotEmpty;
  }

  Future<void> deleteUser(String userName) async {
    TaskController taskController = TaskController();

    try {
      //await taskController.loadTasksFromDB(userName, SortType.NONE);
      await taskController.deleteUserTaskRelationsByUser(userName);
      await _deleteUser(userName);
      await NotificationController().deleteNotificationByUser(userName);
    } catch (e) {
      logError('DELETE USER', e);
    }
  }

  Future<void> _deleteUser(String userName) async {
    try {
      final db = await _getUserByUserName(userName);

      if (db.docs.isNotEmpty) {
        await db.docs.first.reference.delete();
      }
    } catch (e) {
      logError('DELETE USER', e);
    }
  }

  Future<List<User>> loadAllUsers() async {
    List<User> loadedUsers = [];
    User user;
    try {
      final db = await FirebaseFirestore.instance.collection(DbConstants.USER).get();
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
      final id = await _getUserIdByUserName(user.userName);
      if (id != null) {
        user.password = User.hashPassword('123');
        await _updateUserById(id, user);
      }
    } catch (e) {
      logError('RESET PASSWORD', e);
    }
  }

  Future<void> giveAdmin(User user, UserRole uR) async {
    try {
      final id = await _getUserIdByUserName(user.userName);
      if (id != null) {
        final updated = user.copyWith(userRole: uR);
        await _updateUserById(id, updated);
      }
    } catch (e) {
      logError('GIVE ADMIN', e);
    }
  }

  Future<bool> userHasTask(String userName, String taskId) async {
    bool ret = false;
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      if (db.docs.isNotEmpty) {
        ret = true;
      }
    } catch (e) {
      logError('USER HAS TASK', e);
    }
    return ret;
  }

  Future<void> updateProfileDB(User updatedUser, User oldUser) async {
    try {
      final id = await _getUserIdByUserName(oldUser.userName);
      if (id != null) {
        await _updateUserById(id, updatedUser);
        if (oldUser.userName != updatedUser.userName) {
          await _updateUserTask(oldUser.userName, updatedUser);
        }
      }
    } catch (e) {
      logError('UPDATE PROFILE DB', e);
    }
  }

  Future<void> _updateUserTask(String oldUserName, User updatedUser) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          //.where(DbConstants.USERNAME, isEqualTo: myUser.userName)
          .where(DbConstants.USERNAME, isEqualTo: oldUserName)
          .get();

      final docs = db.docs;

      for (final doc in docs) {
        final taskId = doc[DbConstants.TASKID] as String;

        await FirebaseFirestore.instance.collection(DbConstants.USERTASK).doc(doc.id).update({
          DbConstants.USERNAME: updatedUser.userName,
          DbConstants.TASKID: taskId,
        });
      }
    } catch (e) {
      logError('UPDATE USER', e);
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

  Future<QuerySnapshot> _getUserByUserName(String userName) async {
    return await FirebaseFirestore.instance
        .collection(DbConstants.USER)
        .where(DbConstants.USERNAME, isEqualTo: userName)
        .get();
  }

  Future<void> _updateUserById(String id, User user) async {
    await FirebaseFirestore.instance.collection(DbConstants.USER).doc(id).update(user.toFirestore());
  }

  Future<String?> _getUserIdByUserName(String userName) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
    } catch (e) {
      logError('GET USER ID BY USERNAME', e);
    }
    return null;
  }
}
