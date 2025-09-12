import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/controller/user_controller.dart';
//import 'package:flutter/material.dart';
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
      print('LOAD NOTIFICATIONS FROM DATABASE $e');
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
      print('LOAD ALL NOTIFICATIONS FROM DB $e');
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
      print('DELETE NOTIFICATION IN DB $e');
    }
  }

  Future<bool> taskInvitation(String destinationUserName,Task task,String userName,String userDescription,) async {
    String message =
        'L\'usuari $userName t\'ha compartit una tasca (${task.name})';
    Notifications notification = Notifications(
      id: '',
      userName: destinationUserName,
      message: message,
      description: userDescription,
      taskId: task.id,
    );

    /*final db = await FirebaseFirestore.instance
        .collection(DbConstants.NOTIFICATION)
        .where(DbConstants.TASKID, isEqualTo: task.id)
        .where(DbConstants.USERNAME, isEqualTo: destinationUserName)
        .get();

    final db2 = await FirebaseFirestore.instance
        .collection(DbConstants.USERTASK)
        .where(DbConstants.TASKID, isEqualTo: task.id)
        .where(DbConstants.USERNAME, isEqualTo: destinationUserName)
        .get();*/
    UserController uController = UserController();
    bool notExists = await notificationExists(task.id, destinationUserName);
    bool userHasTask = await uController.userHasTask(destinationUserName, task.id);

    //if (db.docs.isNotEmpty && db2.docs.isNotEmpty) {
    if(notExists || userHasTask){
      return false;
    } else {
      await FirebaseFirestore.instance
          .collection(DbConstants.NOTIFICATION)
          .add(notification.toFirestore());
      return true;
    }
  }

  Future<bool> notificationExists(String taskId, String userName) async {
    bool ret = false;
    final db = await FirebaseFirestore.instance
        .collection(DbConstants.NOTIFICATION)
        .where(DbConstants.TASKID, isEqualTo: taskId)
        .where(DbConstants.USERNAME, isEqualTo: userName).get();

    if(db.docs.isNotEmpty){
      ret = true;
    } 
    return ret;
  }
}
