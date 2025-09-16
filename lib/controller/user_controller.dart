import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:to_do_list/controller/notification_controller.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/utils/db_constants.dart';
import 'package:to_do_list/utils/user_role.dart';
import 'package:to_do_list/utils/sort.dart';
import 'package:to_do_list/model/user.dart';

class UserController {
  List<User> users;

  UserController() : users = [];

  Future<int> createAccountDB(User user) async {
    int ret = DbConstants.USEREXISTS;
    User newUser = user.copyWith(password: User.hashPassword(user.password));

    if (!await userNameExists(newUser.userName)) {
      try {
        await FirebaseFirestore.instance
            .collection(DbConstants.USER)
            .add(newUser.toFirestore());
        ret = DbConstants.USERNOTEXISTS;
      } catch (e) {
        print('CREATE ACCOUNT: $e');
        ret = DbConstants.DATABASEERROR;
      }
    }

    return ret;
  }

  Future<bool> userNameExists(String userName) async {
    final db = await FirebaseFirestore.instance
        .collection(DbConstants.USER)
        .where(DbConstants.USERNAME, isEqualTo: userName)
        .get();
    //return db.docs.length == 1;
    return db.docs.isNotEmpty;
  }

  Future<void> deleteUser(String userName) async {
    TaskController taskController = TaskController();
    await taskController.loadTasksFromDB(userName, SortType.NONE);

    try {
      await taskController.deleteUserTaskRelationsByUser(userName);
      await _deleteUser(userName);
      await NotificationController().deleteNotificationByUser(userName);
    } catch (e) {
      print('DELETE USER $e');
    }
  }

  Future<void> _deleteUser(String userName) async {
    try {
      final fUser = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      if (fUser.docs.isNotEmpty) {
        await fUser.docs.first.reference.delete();
      }
    } catch (e) {
      print('DELETE USER');
    }
  }

  Future<List<User>> loadAllUsers() async {
    List<User> loadedUsers = [];
    User user;

    final db = await FirebaseFirestore.instance
        .collection(DbConstants.USER)
        .get();
    final docs = db.docs;

    for (var doc in docs) {
      if (doc.exists) {
        user = User.fromFirestore(doc, null);
        loadedUsers.add(user);
      }
    }

    users = loadedUsers;

    return loadedUsers;
  }

  Future<void> resetPswrd(User user) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: user.userName)
          .get();
      if (db.docs.isNotEmpty) {
        String id = db.docs.first.id;

        user.password = User.hashPassword('123');

        await FirebaseFirestore.instance
            .collection(DbConstants.USER)
            .doc(id)
            .update(user.toFirestore());
      }
    } catch (e) {
      print('RESET PSWRD $e');
    }
  }

  Future<void> giveAdmin(User user, UserRole uR) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: user.userName)
          .get();
      if (db.docs.isNotEmpty) {
        String id = db.docs.first.id;

        user = user.copyWith(userRole: uR);

        await FirebaseFirestore.instance
            .collection(DbConstants.USER)
            .doc(id)
            .update(user.toFirestore());
      }
    } catch (e) {
      print('GIVE ADMIN $e');
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
      print('USER HAS TASK $e');
    }
    return ret;
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
        await _updateUserTask(oldUser.userName, updatedUser);
      }
    } catch (e) {
      print('UPDATE PROFILE DB $e');
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

        await FirebaseFirestore.instance
            .collection(DbConstants.USERTASK)
            .doc(doc.id)
            .update({
              DbConstants.USERNAME: updatedUser.userName,
              DbConstants.TASKID: taskId,
            });
      }
    } catch (e) {
      print('UPDATE USER-TASK $e');
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
      print('IS PASSWORD $e');
      ret = false;
    }

    return ret;
  }
}
