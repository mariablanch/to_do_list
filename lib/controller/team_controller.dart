import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/controller/history_controller.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/relation_tables/team_task.dart';
import 'package:to_do_list/model/relation_tables/user_team.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/roles.dart';

class TeamController {
  Team team;
  Map<Team, List<UserTeam>> allTeamsAndUsers;
  Map<Team, List<UserTeam>> myTeamsAndUsers;

  final UserController _uc;

  TeamController() : team = Team.empty(), allTeamsAndUsers = {}, myTeamsAndUsers = {}, _uc = UserController();

  Future<void> createTeam(Team team, User creator) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection(DbConstants.TEAM).add(team.toFirestore());
      team.id = docRef.id;
      allTeamsAndUsers[team] = [];
      await HistoryController.createTeam(team, creator);
    } catch (e) {
      logError('CREATE TEAM', e);
    }
  }

  Future<void> updateTeam(Team team, Team oldTeam, User creator) async {
    try {
      await FirebaseFirestore.instance.collection(DbConstants.TEAM).doc(team.id).update(team.toFirestore());
      await HistoryController.updateTeam(oldTeam, team, creator);
    } catch (e) {
      logError('UPDATE TEAM', e);
    }
  }

  Future<void> addUserToTeam(Team team, User user) async {
    UserTeam ut = UserTeam(team: team, user: user, role: TeamRole.USER, id: "", deleted: false);
    try {
      await FirebaseFirestore.instance.collection(DbConstants.USERTEAM).add(ut.toFirestore());
      allTeamsAndUsers[team]?.add(ut);
    } catch (e) {
      logError('ADD USER TO TEAM', e);
    }
  }

  Future<void> deleteTeamWithRelation(Team team, User creator) async {
    try {
      _deleteTeam(team, creator); //ELIMINA EL EQUIP
      _deleteUserTeamRelationByTeam(team); // ELIMINA LES RELACIONS AMB EL ID DEL EQUIP ELIMINAT
    } catch (e) {
      logError('DELETE TEAM WITH RELATION', e);
    }
  }

  Future<void> _deleteTeam(Team team, User creator) async {
    try {
      team = team.copyWith(deleted: true);
      await FirebaseFirestore.instance.collection(DbConstants.TEAM).doc(team.id).update(team.toFirestore());
      HistoryController.deleteTeam(team, creator);
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
        UserTeam ut = UserTeam.fromFirestore(doc, null);
        ut = ut.copyWith(deleted: true);
        await doc.reference.update(ut.toFirestore());
      }
    } catch (e) {
      logError('DELETE USER-TEAM BY TEAM', e);
    }
  }

  /// Elimina un usuari [userName] del equip [team].
  Future<void> deleteUserTeamRelationByUser(Team team, String userId) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTEAM)
          .where(DbConstants.USERID, isEqualTo: userId)
          .where(DbConstants.TEAMID, isEqualTo: team.id)
          .get();
      for (var doc in db.docs) {
        doc.reference.delete();
      }
    } catch (e) {
      logError('DELETE USER TEAM RELATION BY USER', e);
    }
  }

  Future<void> removeUserFromAllTeams(String userId) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTEAM)
          .where(DbConstants.USERID, isEqualTo: userId)
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
      Team team;
      User user;

      await _uc.loadAllUsers(false);
      List<User> allUsers = _uc.users;
      await _loadAllTeams();

      final db = await FirebaseFirestore.instance.collection(DbConstants.USERTEAM).get();
      if (db.docs.isNotEmpty) {
        for (var doc in db.docs) {
          UserTeam ut = UserTeam.fromFirestore(doc, null);

          user = allUsers.firstWhere((u) => u.id == ut.user.id);
          team = allTeamsAndUsers.keys.firstWhere((t) => t.id == ut.team.id);

          ut = ut.copyWith(user: user, team: team);
          allTeamsAndUsers[team]?.add(ut);
        }
        allTeamsAndUsers = sortMap(allTeamsAndUsers);
      }
    } catch (e) {
      logError('LOAD ALL TEAMS WITH USERS', e);
    }
  }

  Map<Team, List<UserTeam>> sortMap(Map<Team, List<UserTeam>> map) {
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
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
    try {
      if (allTeamsAndUsers.isEmpty) {
        await loadAllTeamsWithUsers();
      }
      myTeamsAndUsers.clear();
      allTeamsAndUsers.forEach((team, ut) {
        if (ut.any((u) => u.user.userName == user.userName)) {
          myTeamsAndUsers[team] = ut;
        }
      });
      myTeamsAndUsers = sortMap(myTeamsAndUsers);
    } catch (e) {
      logError('LOAD TEAMS BY USER', e);
    }
  }

  Future<Team?> loadTeambyId(String teamId) async {
    final db = await FirebaseFirestore.instance.collection(DbConstants.TEAM).doc(teamId).get();
    if (db.exists) {
      return Team.fromFirestore(db, null);
    }
    return null;
  }

  Future<List<TeamTask>> loadTeamTask(bool configPage) async {
    final db = await FirebaseFirestore.instance.collection(DbConstants.TEAMTASK).get();
    TeamTask tt;
    List<TeamTask> list = [];
    TaskController tc = TaskController();
    await tc.loadAllTasksFromDB(configPage);

    for (var doc in db.docs) {
      Team team;
      Task task;
      tt = TeamTask.fromFirestore(doc, null);
      team = await TeamController().loadTeambyId(tt.team.id) ?? tt.team;
      task = tc.tasks.firstWhere((tsk) => tsk.id == tt.task.id);
      tt = TeamTask(team: team, task: task, deleted: false, id: "");
      list.add(tt);
    }
    return list;
  }

  Future<List<UserTeam>> updateAdmins(List<User> adminUsersSelected, List<UserTeam> teamUsers, Team team) async {
    try {
      List<User> users = teamUsers.where((ut) => ut.role == TeamRole.ADMIN).map((ut) => ut.user).toList();
      UserTeam ut;

      if (!adminUsersSelected.every((u) => users.contains(u))) {}

      for (var user in users) {
        if (!adminUsersSelected.contains(user)) {
          users.remove(user);
          ut = UserTeam(team: team, user: user, role: TeamRole.USER, id: "", deleted: false);
          await _upadateRelation(ut);
        }
      }
      users.addAll(adminUsersSelected);
      users = users.toSet().toList();

      for (var user in users) {
        ut = UserTeam(team: team, user: user, role: TeamRole.ADMIN, id: "", deleted: false);
        await _upadateRelation(ut);
      }

      List<UserTeam> ret = [];
      for (var userTeam in teamUsers) {
        if (users.contains(userTeam.user)) {
          ret.add(userTeam.copyWith(role: TeamRole.ADMIN));
        } else {
          ret.add(userTeam.copyWith(role: TeamRole.USER));
        }
      }

      return ret;
    } catch (e) {
      logError('MAKE ADMIN', e);
      return [];
    }
  }

  /// Entra un UserTeam amb el TeamRole ya canviat.
  Future<void> _upadateRelation(UserTeam ut) async {
    try {
      final db = await FirebaseFirestore.instance
          .collection(DbConstants.USERTEAM)
          .where(DbConstants.USERID, isEqualTo: ut.user.id)
          .where(DbConstants.TEAMID, isEqualTo: ut.team.id)
          .get();

      if (db.docs.isNotEmpty) {
        db.docs.first.reference.update(ut.toFirestore());
      }
    } catch (e) {
      logError('UPDATE RELATION', e);
    }
  }
}
