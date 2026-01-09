enum TeamRole {
  NONE,
  USER,
  ADMIN;

  static bool isAdmin(TeamRole ur) {
    return ur == ADMIN;
  }
  static TeamRole getUserRole(bool isAdmin){
    return isAdmin ? TeamRole.ADMIN : TeamRole.USER;
  }
}

enum UserRole {
  USER,
  ADMIN;

  static bool isAdmin(UserRole ur) {
    return ur == ADMIN;
  }
  static UserRole getUserRole(bool isAdmin){
    return isAdmin ? UserRole.ADMIN : UserRole.USER;
  }
}
