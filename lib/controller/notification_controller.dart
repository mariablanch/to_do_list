import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/model/notification.dart';
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
      //AGAFAR TASQUES DE LA RELACIÓ
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
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

}
