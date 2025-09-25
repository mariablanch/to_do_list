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
