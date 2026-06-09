import 'package:app/shared/contracts/i_logger.dart';
import 'package:app/shared/inject.dart';

ILogger get log => inject<ILogger>();
