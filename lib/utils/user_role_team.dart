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
