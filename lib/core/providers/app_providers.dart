import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:tracely/core/providers/auth_provider.dart';
import 'package:tracely/core/providers/theme_mode_provider.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ];
}
