// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `SettingsProvider` 负责管理和持久化应用的所有用户设置。
///
/// 它使用 `ChangeNotifier` 来通知UI层设置的变更，并利用 `SharedPreferences`
/// 将设置保存到设备本地存储中，确保用户配置在应用重启后依然有效。
class SettingsProvider extends ChangeNotifier {
  // region 状态变量
  // --- 主题设置 ---
  bool _isDarkMode = false;
  bool _useSystemTheme = true;

  // --- 功能设置 ---
  bool _useChinese = true; // 是否使用中文（保留字段，当前未在UI中使用）
  bool _isShizukuMode = false; // 是否强制使用Shizuku模式
  bool _autoCheckUpdate = true; // 是否自动检查更新

  // endregion

  // region SharedPreferences Keys
  // 使用静态常量来定义键，以避免拼写错误并易于管理。
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyUseSystemTheme = 'use_system_theme';
  static const String _keyUseChinese = 'use_chinese';
  static const String _keyShizukuMode = 'is_shizuku_mode';
  static const String _keyAutoCheckUpdate = 'auto_check_update';
  // endregion

  /// 构造函数，在实例化时立即开始加载设置。
  SettingsProvider() {
    _loadSettings();
  }

  // region Getters
  // --- 公共 Getters，用于让UI层安全地访问状态 ---
  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;
  bool get useChinese => _useChinese;
  bool get isShizukuMode => _isShizukuMode;
  bool get autoCheckUpdate => _autoCheckUpdate;

  /// 根据 `useSystemTheme` 和 `isDarkMode` 的状态，计算并返回当前的 `ThemeMode`。
  ThemeMode get themeMode {
    if (_useSystemTheme) {
      return ThemeMode.system;
    }
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
  // endregion

  // region Setters & 持久化逻辑
  /// 从 `SharedPreferences` 加载所有设置。
  ///
  /// 这是异步操作，会在应用启动时执行。加载完成后会通知所有监听者更新UI。
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载各项设置，如果不存在则使用默认值。
      _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
      _useSystemTheme = prefs.getBool(_keyUseSystemTheme) ?? true;
      _useChinese = prefs.getBool(_keyUseChinese) ?? true;
      _isShizukuMode = prefs.getBool(_keyShizukuMode) ?? false;
      _autoCheckUpdate = prefs.getBool(_keyAutoCheckUpdate) ?? true;

      debugPrint("SettingsProvider: 设置加载完成。");
    } catch (e) {
      debugPrint("SettingsProvider: 加载设置时出错: $e");
    } finally {
      // 无论加载成功与否，都通知UI更新，以反映当前的默认值或已加载的值。
      notifyListeners();
    }
  }

  /// 更新黑暗模式设置。
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  /// 更新是否跟随系统主题的设置。
  Future<void> setUseSystemTheme(bool value) async {
    if (_useSystemTheme == value) return;
    _useSystemTheme = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseSystemTheme, value);
  }

  /// 更新Shizuku模式。
  Future<void> setShizukuMode(bool value) async {
    if (_isShizukuMode == value) return;
    _isShizukuMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShizukuMode, value);
  }

  /// 更新是否自动检查更新的设置。
  Future<void> setAutoCheckUpdate(bool value) async {
    if (_autoCheckUpdate == value) return;
    _autoCheckUpdate = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCheckUpdate, value);
  }
}
