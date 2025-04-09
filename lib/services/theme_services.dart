import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

class ThemeServices {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  _saveTheme(bool isDarkMode) => _box.write(_key, isDarkMode);

  bool isDarkMode() => _box.read(_key) ?? false;

  ThemeMode get theme => isDarkMode() ? ThemeMode.dark : ThemeMode.light;

  void switchTheme() {
    Get.changeThemeMode(isDarkMode() ? ThemeMode.light : ThemeMode.dark);
    _saveTheme(!isDarkMode());
  }
}
