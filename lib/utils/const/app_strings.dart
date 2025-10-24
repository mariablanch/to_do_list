import 'package:intl/intl.dart';
import 'package:to_do_list/model/task.dart';

class AppStrings {
  static const String USER_SEPARATOR = ' | ';
  static const String DEFAULT_PSWRD = '123';

  static const String SHOWALL = 'Mostrar totes';
  static const String ALREADY_SHARED = 'Aquesta tasca ja ha estat compartida';
  static const String NOTEXISTS_MESSAGE = 'Aquest usuari no existeix';

  static const String CONFIRM = 'Confirmar';
  static const String ACCEPT = 'Acceptar';
  static const String CANCEL = 'Cancel·lar';

  static const String USERS = '\u2794 Usuaris:';

  //static const String COMPLETED = 'Completada';
  //static const String PENDING = 'Pendent';

  static const String CONFIG = 'Configuració';
  static const String PROFILE = 'Perfil';
  static const String EDIT_PROFILE = 'Editar perfil';
  static const String USERS_LABEL = 'Usuaris';
  static const String TASKSTATES = 'Estat de les tasques';
  static const String TEAMS = 'Equips';
  static const String DELETEACC = 'Eliminar compte';

  static const String PR_HIGH = 'Alt';
  static const String PR_MEDIUM = 'Mitjà';
  static const String PR_LOW = 'Baix';
  static const List<String> PRIORITIES_STR = [PR_HIGH, PR_MEDIUM, PR_LOW];

  static const List<String> DEFAULT_STATES = ['Pendent','En procés', 'Completada'];

  static String subtitleText(String description, String ids) {
    return '$description\n${AppStrings.USERS} $ids';
  }

  static String titleText(Task task) {
    return '${task.name}   -   ${DateFormat('dd/MMM').format(task.limitDate)}';
  }
}
