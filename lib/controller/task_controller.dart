import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/utils/db_constants.dart';
import 'package:to_do_list/utils/sort.dart';

class TaskController {
  List<Task> tasks;

  TaskController.empty() : tasks = [];
  TaskController(List<Task> tasks) : this.tasks = tasks;

  Future<void> loadTasksFromDB(String userName, SortType sortType) async {
    Task task;
    try {
      List<Task> loadedTasks = [];

      //AGAFAR TASQUES DE LA RELACIÓ
      //print(myUser.toString());
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      List<String> taskIDs = db.docs
          .map((doc) => doc[DbConstants.TASKID] as String)
          .toList();

      //AGAFAR LES TASQUES A LA TAULA TASK A PARTIR DEL ID
      for (String id in taskIDs) {
        final doc = await FirebaseFirestore.instance
            .collection(DbConstants.TASK)
            .doc(id)
            .get();

        if (doc.exists) {
          task = Task.fromFirestore(doc, null);
          loadedTasks.add(task);
        }
      }

      loadedTasks.sort((task1, task2) {
        return Task.sortTask(sortType, task1, task2);
      });

      this.tasks = loadedTasks;
    } catch (e) {
      print(e);
    }
  }

  Future<Task> getTaskByID(String taskID) async {
    Task task = Task.empty();
    final doc = await FirebaseFirestore.instance
        .collection(DbConstants.TASK)
        .doc(taskID)
        .get();

    if (doc.exists) {
      task = Task.fromFirestore(doc, null);
    }
    //this.tasks.add(task);
    return task;
  }

  Future<void> updateTaskInDatabase(Task task, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection(DbConstants.TASK)
          .doc(id)
          .update(task.toFirestore());
    } catch (e) {
      print(e);
    }
  }

  Future<void> addTaskToDataBase(Task newTask, String userName) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection(DbConstants.TASK)
          .add(newTask.toFirestore());

      String taskId = docRef.id;
      newTask.id = taskId;

      await FirebaseFirestore.instance.collection(DbConstants.USERTASK).add({
        DbConstants.USERNAME: userName,
        DbConstants.TASKID: taskId,
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteTaskInDatabase(String id, String userName) async {
    String str = await getUsersRelatedWithTask(id);
    List<String> usernames = str.split('\n');

    try {
      if (usernames.length == 1) {
        deleteTask(id);
      }

      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: id)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      db.docs.first.reference.delete();
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection(DbConstants.TASK)
          .doc(id)
          .delete();

      //BORRAR NOTIS Q ESTIGUIN RELACIONADES AMB LA TASCA
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .where(DbConstants.TASKID, isEqualTo: id)
          .get();
      if (db.docs.isNotEmpty) {
        await db.docs.first.reference.delete();
      }
    } catch (e) {
      print(e);
    }
  }

  /*Future<void> deleteTaskInDatabase(int index, String id) async {
    NotificationController notController = NotificationController.empty();
    
    try {
      await FirebaseFirestore.instance
          .collection(DbConstants.TASK)
          .doc(id)
          .delete();
      final tableId = await FirebaseFirestore.instance
          .collection(DbConstants.USERTASK)
          .where(DbConstants.TASKID, isEqualTo: id)
          .get();

      for (var doc in tableId.docs) {
        await doc.reference.delete();
      }

      List<Notifications> allNotifications = await notController
          .loadALLNotificationsFromDB();

      for (int pos = 0; pos < allNotifications.length; pos++) {
        if (allNotifications[pos].taskID == id) {
          await notController.deleteNotificationInDatabase(pos);
        }
      }
    } catch (e) {
      print(e);
    }
  }*/

  Future<String> getUsersRelatedWithTask(String taskID) async {
    List<String> userNames = [];
    String str = '';

    final db = await FirebaseFirestore.instance
        .collection(DbConstants.USERTASK)
        .where(DbConstants.TASKID, isEqualTo: taskID)
        .get();

    for (var doc in db.docs) {
      if (doc.data().containsKey(DbConstants.USERNAME)) {
        final userName = doc.get(DbConstants.USERNAME);
        if (userName is String) {
          userNames.add(userName);
        }
      }
    }

    str = userNames.join('\n');

    return str;
  }
}
