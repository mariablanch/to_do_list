// ignore_for_file: avoid_print

const String RED = '\x1B[31m';
const String GREEN = '\x1B[32m';
const String YELLOW = '\x1B[33m';
const String BLUE = '\x1B[34m';
const String MAGENTA = '\x1B[35m';
const String CYAN = '\x1B[36m';
const String WHITE = '\x1B[37m';
const String CLEAR = '\x1B[0m';

void logError(String context, dynamic e) {
  print('$RED$context \n${RED}ERROR: $e');
}

void logInfo(String message) {
  print('${GREEN}INFO: $message $CLEAR');
  //print('INFO: $message');
}

void logWarning(String warning) {
  print('${WHITE}WARNING: $warning');
}

void logPrintClass(String toStr) {
  for (final line in toStr.split('\n')) {
    print(MAGENTA + line + CLEAR);
  }
}

void logToDo(String str, String document) {
  print(
    '${YELLOW}PER IMPLEMENTAR: $str\n'
    '\t$YELLOW$document',
  );
}
