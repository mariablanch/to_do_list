class DbConstants {
  //COLLECTION
  static const String TASK = "task";
  static const String USER = "user";
  static const String USERTASK = "usertask";
  static const String NOTIFICATION = "notification";
  static const String TASKSTATE = "taskState";
  static const String TEAM = "team";
  static const String USERTEAM = "userteam";
  static const String TEAMTASK = "teamtask";


  //FIELD
  static const String USERNAME = "userName";
  static const String PASSWORD = "password";
  static const String USERROLE = "userRole";
  static const String TASKID = "taskId";
  static const String ICON = "iconName";
  static const String STATE = "state";
  static const String TEAMID = "teamId";
  static const String DELETED = "deleted";

  static const String LIMIT_DATE = "limitDate";
  static const String OPEN_DATE = "openDate";
  static const String COMPLETED_DATE = "completedDate";

  //COMPROVACIÓ ERROR BASE DE DADES
  static const int USEREXISTS = 0;
  static const int USERNOTEXISTS = 1;
  static const int DATABASEERROR = 2;
}
