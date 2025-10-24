import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/const/messages.dart';

class TeamController {
  Team team;
  Map<Team, List<User>> allTeamsAndUsers;
  Map<Team, List<User>> myTeamsAndUsers;

  TeamController() : team = Team.empty(), allTeamsAndUsers = {}, myTeamsAndUsers = {};

  Future<void> createTeam(Team team) async {
    try {
      await FirebaseFirestore.instance.collection(DbConstants.TEAM).add(team.toFirestore());
      allTeamsAndUsers[team] = [];
    } catch (e) {
      logError('CREATE TEAM', e);
    }
  }

  Future<void> updateTeam(Team team) async {
    try {
      await FirebaseFirestore.instance.collection(DbConstants.TEAM).doc(team.id).update(team.toFirestore());
    } catch (e) {
      logError('UPDATE TEAM', e);
    }
  }

  Future<void> addUserToTeam(Team team, User user) async {
    try {
      await FirebaseFirestore.instance.collection(DbConstants.USERTEAM).add({
        DbConstants.USERNAME: user.userName,
        DbConstants.TEAMID: team.id,
      });
      allTeamsAndUsers[team]?.add(user);
    } catch (e) {
      logError('ADD USER TO TEAM', e);
    }
  }

  Future<void> deleteTeamWithRelation(Team team) async {
    try {
      _deleteTeam(team); //ELIMINA EL EQUIP
      _deleteUserTeamRelationByTeam(team); // ELIMINA LES RELACIONS AMB EL ID DEL EQUIP ELIMINAT
    } catch (e) {
      logError('DELETE TEAM WITH RELATION', e);
    }
  }

  Future<void> _deleteTeam(Team team) async {
    try {
      await FirebaseFirestore.instance.collection(DbConstants.TEAM).doc(team.id).delete();
    } catch (e) {
      logError('DELETE TEAM', e);
    }
  }

  Future<void> _deleteUserTeamRelationByTeam(Team team) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTEAM)
          .where(DbConstants.TEAMID, isEqualTo: team.id)
          .get();

      for (var doc in db.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      logError('DELETE USER-TEAM BY TEAM', e);
    }
  }

  Future<void> deleteUserTeamRelationByUser(Team team, String userName) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTEAM)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .where(DbConstants.TEAMID, isEqualTo: team.id)
          .get();
      for (var doc in db.docs) {
        doc.reference.delete();
      }
    } catch (e) {
      logError('DELETE USER TEAM RELATION BY USER', e);
    }
  }

  Future<void> removeUserFromAllTeams(String userName) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTEAM)
          .where(DbConstants.USERNAME, isEqualTo: userName)
          .get();

      for (var doc in db.docs) {
        doc.reference.delete();
      }
    } catch (e) {
      logError('REMOVE USER FROM ALL TEAMS', e);
    }
  }

  Future<void> loadAllTeamsWithUsers() async {
    try {
      String userName;
      String teamId;
      Team team;
      List<User> users = [];
      User user;

      UserController uc = UserController();
      await uc.loadAllUsers();
      List<User> allUsers = uc.users;
      await _loadAllTeams();

      final db = await FirebaseFirestore.instance.collection(DbConstants.USERTEAM).get();

      for (var doc in db.docs) {
        users.clear();
        userName = doc.get(DbConstants.USERNAME);
        teamId = doc.get(DbConstants.TEAMID);

        user = allUsers.firstWhere((u) => u.userName == userName);
        team = allTeamsAndUsers.keys.firstWhere((t) => t.id == teamId);

        allTeamsAndUsers[team]?.add(user);
      }
      allTeamsAndUsers = Map.fromEntries(allTeamsAndUsers.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    } catch (e) {
      logError('LOAD ALL TEAMS WTH USERS', e);
    }
  }

  Future<void> _loadAllTeams() async {
    Team team;
    allTeamsAndUsers.clear();
    try {
      final db = await FirebaseFirestore.instance.collection(DbConstants.TEAM).get();
      for (var doc in db.docs) {
        team = Team.fromFirestore(doc, null);
        allTeamsAndUsers.addAll({team: []});
      }
    } catch (e) {
      logError('LOAD ALL TEAMS', e);
    }
  }

  Future<void> loadTeamsbyUser(User user) async {
    if (allTeamsAndUsers.isEmpty) {
      await loadAllTeamsWithUsers();
    }
    myTeamsAndUsers.clear();
    allTeamsAndUsers.forEach((team, users) {
      if (users.any((u) => u.userName == user.userName)) {
        myTeamsAndUsers[team] = users;
      }
    });
  }

  Future<Team?> loadTeambyId(String teamId) async {
    final db = await FirebaseFirestore.instance.collection(DbConstants.TEAM).doc(teamId).get();
    if (db.exists) {
      return Team.fromFirestore(db, null);
    }
    return null;
  }
}
