import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:tracely/core/providers/theme_mode_provider.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
      ];
}
