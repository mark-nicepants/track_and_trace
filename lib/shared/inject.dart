import 'package:get_it/get_it.dart';

GetIt get injector => GetIt.I;

T inject<T extends Object>({String? instanceName}) => injector<T>(instanceName: instanceName);
