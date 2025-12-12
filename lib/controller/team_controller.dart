import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/controller/task_controller.dart';
import 'package:to_do_list/controller/user_controller.dart';
import 'package:to_do_list/model/relation_tables/team_task.dart';
import 'package:to_do_list/model/relation_tables/user_team.dart';
import 'package:to_do_list/model/task.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/const/messages.dart';
import 'package:to_do_list/utils/user_role_team.dart';

class TeamController {
  Team team;
  Map<Team, List<UserTeam>> allTeamsAndUsers;
  Map<Team, List<UserTeam>> myTeamsAndUsers;

  final UserController _uc;

  TeamController() : team = Team.empty(), allTeamsAndUsers = {}, myTeamsAndUsers = {}, _uc = UserController();

  Future<void> createTeam(Team team) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection(DbConstants.TEAM).add(team.toFirestore());
      team.id = docRef.id;
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
    UserTeam ut = UserTeam(team: team, user: user, role: TeamRole.USER);
    try {
      await FirebaseFirestore.instance.collection(DbConstants.USERTEAM).add(ut.toFirestore());
      allTeamsAndUsers[team]?.add(ut);
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

  /// Elimina un usuari [userName] del equip [team].
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
      Team team;
      User user;

      await _uc.loadAllUsers();
      List<User> allUsers = _uc.users;
      await _loadAllTeams();

      final db = await FirebaseFirestore.instance.collection(DbConstants.USERTEAM).get();

      for (var doc in db.docs) {
        UserTeam ut = UserTeam.fromFirestore(doc, null);
        user = allUsers.firstWhere((u) => u.userName == ut.user.userName);
        team = allTeamsAndUsers.keys.firstWhere((t) => t.id == ut.team.id);

        ut = ut.copyWith(user: user, team: team);
        allTeamsAndUsers[team]?.add(ut);
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
      tt = TeamTask(team: team, task: task);
      list.add(tt);
    }
    return list;
  }
}
