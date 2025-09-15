enum UserRole{
  USER, 
  ADMIN;

  static bool isAdmin(UserRole ur){
    return ur == ADMIN;
  }
}