import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/model/team.dart';
import 'package:to_do_list/model/user.dart';
import 'package:to_do_list/utils/const/db_constants.dart';
import 'package:to_do_list/utils/interfaces.dart';
import 'package:to_do_list/utils/user_role_team.dart';

class UserTeam implements Comparable<UserTeam>, BaseEntity {
  String _id;
  Team _team;
  User _user;
  TeamRole _role;
  bool _deleted;

  UserTeam.empty() : _team = Team.empty(), _user = User.empty(), _role = TeamRole.USER, _id = "", _deleted = false;

  UserTeam({required Team team, required User user, required TeamRole role, required String id, required bool deleted})
    : _team = team,
      _user = user,
      _role = role,
      _deleted = deleted,
      _id = id;

  UserTeam.copy(UserTeam uTeam)
    : _team = uTeam.team,
      _user = uTeam.user,
      _role = uTeam.role,
      _deleted = uTeam.deleted,
      _id = uTeam.id;

  UserTeam copyWith({Team? team, User? user, TeamRole? role, bool? deleted, String? id}) {
    return UserTeam(
      team: team ?? _team,
      user: user ?? _user,
      role: role ?? _role,
      id: id ?? _id,
      deleted: deleted ?? _deleted,
    );
  }

  Team get team => _team;
  User get user => _user;
  TeamRole get role => _role;
  @override
  bool get deleted => _deleted;
  @override
  String get id => _id;

  Map<String, dynamic> toFirestore() {
    return {
      DbConstants.USERID: user.id,
      DbConstants.TEAMID: team.id,
      DbConstants.USERROLE: role.name,
      DbConstants.DELETED: deleted,
    };
  }

  factory UserTeam.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    final role = TeamRole.values.firstWhere(
      (p) => p.name.toLowerCase() == data?[DbConstants.USERROLE]?.toString().toLowerCase(),
      orElse: () => TeamRole.USER,
    );
    Team team = Team.empty().copyWith(id: data?[DbConstants.TEAMID] ?? '');
    User user = User.empty().copyWith(id: data?[DbConstants.USERID] ?? '');

    return UserTeam(team: team, user: user, role: role, deleted: data?[DbConstants.DELETED] ?? false, id: snapshot.id);
  }

  @override
  int compareTo(UserTeam ut) {
    int comp = role.index - ut.role.index;
    if (comp == 0) {
      comp = user.compareTo(ut.user);
    }
    return comp;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserTeam && other.team == team && other.user == user;
  }

  @override
  int get hashCode => Object.hash(team, user);
}
