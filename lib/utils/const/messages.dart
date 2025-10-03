const String RED = '\x1B[31m';
const String GREEN = '\x1B[32m';
const String YELLOW = '\x1B[33m';
const String BLUE = '\x1B[34m';
const String MAGENTA = '\x1B[35m';
const String CYAN = '\x1B[36m';
const String WHITE = '\x1B[37m';
const String CLEAR = '\x1B[0m';

void logError(String context, dynamic e) {
  String str = '~~~~~~~~~~~~~~~~~~~~~~~~~~';
  print('$context \nERROR: $e \n$str');
}

void logInfo(String message) {
  print('${GREEN}INFO: $message $CLEAR');
  //print('INFO: $message');
}

void logWarning(String warning) {
  print('WARNING: $warning');
}
