void logError(String context, dynamic e) {
  String str = '~~~~~~~~~~~~~~~~~~~~~~~~~~';
  print('$str\n$context \nERROR: $e \n$str');
}

void logInfo(String message) {
  print('INFO: $message');
}

void logWarning(String warning) {
  print('WARNING: $warning');
}
