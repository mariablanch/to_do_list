// ignore_for_file: non_constant_identifier_names

class AppStrings {
  static final String SHOWALL = 'Mostrar totes';
  static final String ALREADY_SHARED = 'Aquesta tasca ja ha estat compartida';
  static final String NOTEXISTS_MESSAGE = 'Aquest usuari no existeix';

  static final String CONFIRM = 'Confirmar';
  static final String ACCEPT = 'Acceptar';
  static final String CANCEL = 'Cancel·lar';

  static final String USERS = '\u2794 Usuaris:';
  static final String USER_SEPARATOR = ' | ';
  static final String DEFAULT_PSWRD = '123';

  static final String COMPLETED = 'Completada';
  static final String PENDING = 'Pendent';

  static final String CONFIG = 'Configuració';
  static final String PROFILE = 'Perfil';
  static final String USERS_LABEL = 'Usuaris';
  static final String DELETEACC = 'Eliminar compte';

  static String subtitleText(String description, String ids) {
    return '$description\n${AppStrings.USERS} $ids';
  }
}
