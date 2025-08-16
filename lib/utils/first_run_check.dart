// lib/utils/first_run_check.dart

import 'package:shared_preferences/shared_preferences.dart';

class FirstRunCheck {
  static const _keyIsFirstTimeLaunch = 'isFirstTimeLaunch';

  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsFirstTimeLaunch) ?? true;
  }

  static Future<void> setNotFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstTimeLaunch, false);
  }
  
  // 设置为首次运行（用于重置应用）
  static Future<void> setFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstTimeLaunch, true);
  }
}