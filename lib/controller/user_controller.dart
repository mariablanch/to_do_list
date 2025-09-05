import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/utils/db_constants.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/sort.dart';

class UserController {
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
    return db.docs.length == 1;
  }

  Future<void> deleteUser(User user) async {
    String username = user.userName;
    TaskController taskController = TaskController.empty();
    await taskController.loadTasksFromDB(user.userName, SortType.NONE);

    List<Task> tasks = taskController.tasks;

    try {
      //BORRAR LES TASQUES DEL USUARI
      for (Task task in tasks) {
        //taskController.deleteTask(task.id);
        /*await FirebaseFirestore.instance
            .collection(DbConstants.USERTASK)
            .doc(task.id)
            .delete();*/
        taskController.deleteTaskInDatabase(task.id, user.userName);
      }

      //BORRAR RELACIÓ
      final usertasks = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.USERNAME, isEqualTo: username)
          .get();
      for (var doc in usertasks.docs) {
        await doc.reference.delete();
      }

      //BORRAR USUARI
      final fUser = await FirebaseFirestore.instance
          .collection(DbConstants.USER)
          .where(DbConstants.USERNAME, isEqualTo: username)
          .get();

      if (fUser.docs.isNotEmpty) {
        await fUser.docs.first.reference.delete();
      }

      //NOTIFICACIONS QUE TINGUI EL USUARI
      final notification = await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .where(DbConstants.USERNAME, isEqualTo: username)
          .get();

      for (var doc in notification.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('DELETE USER $e');
    }
  }


}
