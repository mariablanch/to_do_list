import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/model/notification.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/utils/db_constants.dart';

class NotificationController {
  List<Notifications> notifications;

  NotificationController.empty() : this.notifications = [];
  NotificationController(List<Notifications> notifications)
    : this.notifications = notifications;

  Future<void> loadNotificationsFromDB(String userName) async {
    Notifications notification;
    try {
      List<Notifications> loadedNotifications = [];

      //AGAFAR TASQUES DE LA RELACIÓ
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      //AGAFAR LES NOTIFICACIONS
      for (var idoc in db.docs) {
        final doc = await FirebaseFirestore.instance
            .collection(DbConstants.NOTIFICATION)
            .doc(idoc.id)
            .get();

        if (doc.exists) {
          notification = Notifications.fromFirestore(doc, null);
          loadedNotifications.add(notification);
        }
      }
      loadedNotifications.sort();
      this.notifications = loadedNotifications;
    } catch (e) {
      print(e);
    }
  }

  /*Future<void> updateNotoficationInDatabase(  
    Notifications not,
    String id,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .doc(id)
          .update(not.toFirestore());
    } catch (e) {
      print(e);
    }
  }*/

  Future<List<Notifications>> loadALLNotificationsFromDB() async {
    Notifications notification;
    List<Notifications> loadedNotifications = [];
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .get();

      for (var doc in db.docs) {
        notification = Notifications.fromFirestore(doc, null);
        loadedNotifications.add(notification);
      }
      loadedNotifications.sort();
      this.notifications = loadedNotifications;
    } catch (e) {
      print(e);
    }

    return loadedNotifications;
  }

  Future<void> deleteNotificationInDatabase(int index) async {
    try {
      String id = notifications[index].id;
      await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .doc(id)
          .delete();

      notifications.removeAt(index);
    } catch (e) {
      print(e);
    }
  }

  Future<bool> taskInvitation(String destinationUserName, Task task, String userName) async {
    String description =
        'L\'usuari $userName t\'ha compartit una tasca';
    Notifications notification = Notifications(
      id: '',
      userName: destinationUserName,
      description: description,
      name: task.name,
      taskID: task.id,
    );

    final db = await FirebaseFirestore.instance
        .collection(DbConstants.NOTIFICATION)
        .where(DbConstants.TASKID, isEqualTo: task.id)
        .where(DbConstants.USERNAME, isEqualTo: destinationUserName)
        .get();

    final db2 = await FirebaseFirestore.instance
        .collection(DbConstants.USERTASK)
        .where(DbConstants.TASKID, isEqualTo: task.id)
        .where(DbConstants.USERNAME, isEqualTo: destinationUserName)
        .get();

    if (db.docs.isNotEmpty && db2.docs.isNotEmpty) {
      return false;
    } else {
      await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .add(notification.toFirestore());
      return true;
    }
  }

}
