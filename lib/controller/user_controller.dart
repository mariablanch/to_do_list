import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do_list/utils/db_constants.dart';
import 'package:to_do_list/model/user.dart';

class UserController {
  Future<int> createAccountDB(User user) async {
    int ret = DbConstants.USEREXISTS;
    User newUser = user.copyWith(password: User.hashPassword(user.password));

    if (!await userNameExists(user.userName)) {
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

}
