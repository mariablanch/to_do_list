// ignore_for_file: unnecessary_this

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/model/notification.dart';
import 'package:to_do_list/model/task.dart';

class NotificationController {
  List<Notifications> notifications;

  NotificationController({List<Notifications>? notifications}) : this.notifications = notifications ?? [];

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
        final doc = await FirebaseFirestore.instance.collection(DbConstants.NOTIFICATION).doc(idoc.id).get();

        if (doc.exists) {
          notification = Notifications.fromFirestore(doc, null);
          loadedNotifications.add(notification);
        }
      }
      loadedNotifications.sort();
      this.notifications = loadedNotifications;
    } catch (e) {
      logError('LOAD NOTIFICATIONS FROM DATABASE', e);
    }
  }

  Future<List<Notifications>> loadALLNotificationsFromDB() async {
    Notifications notification;
    List<Notifications> loadedNotifications = [];
    try {
      final db = await FirebaseFirestore.instance.collection(DbConstants.NOTIFICATION).get();

      for (var doc in db.docs) {
        notification = Notifications.fromFirestore(doc, null);
        loadedNotifications.add(notification);
      }
      loadedNotifications.sort();
      this.notifications = loadedNotifications;
    } catch (e) {
      logError('LOAD ALL NOTIFICATIONS FROM DB', e);
    }

    return loadedNotifications;
  }

  Future<void> deleteNotificationByID(String notId) async {
    try {
      //String id = notifications[index].id;
      await FirebaseFirestore.instance.collection(DbConstants.NOTIFICATION).doc(notId).delete();

      //notifications.removeAt(index);
    } catch (e) {
      logError('DELETE NOTIFICATION BY ID', e);
    }
  }

  Future<void> deleteNotificationByUser(String userName) async {
    try {
      final notification = await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      for (var doc in notification.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      logError('DELETE NOTIFICATION BY USER', e);
    }
  }

  Future<void> deleteNotificationByTask(String taskId) async {
    try {
      final notification = await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .get();

      for (var doc in notification.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      logError('DELETE NOTIFICATION BY TASK', e);
    }
  }

  Future<void> _notificationToDb(Notifications not) async {
    await FirebaseFirestore.instance.collection(DbConstants.NOTIFICATION).add(not.toFirestore());
  }

  Future<bool> taskInvitation(String destinationUserName, Task task, String userName, String userDescription) async {
    String message = 'L\'usuari $userName t\'ha compartit una tasca (${task.name})';
    Notifications notification = Notifications(
      id: '',
      userName: destinationUserName,
      message: message,
      description: userDescription,
      taskId: task.id,
    );

    bool ret = false;
    try {
      bool notExists = await notificationExists(task.id, destinationUserName);
      bool userHasTask = await UserController().userHasTask(destinationUserName, task.id);

      if (!(notExists || userHasTask)) {
        //await FirebaseFirestore.instance.collection(DbConstants.NOTIFICATION).add(notification.toFirestore());
        _notificationToDb(notification);
        ret = true;
      }
    } catch (e) {
      logError('TASK INVITATION', e);
    }
    return ret;
  }

  Future<bool> notificationExists(String taskId, String userName) async {
    bool ret = false;
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .where(DbConstants.TASKID, isEqualTo: taskId)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      if (db.docs.isNotEmpty) {
        ret = true;
      }
    } catch (e) {
      logError('NOTIFICATION EXISTS', e);
    }
    return ret;
  }
}
