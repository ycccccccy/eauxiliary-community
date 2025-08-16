// lib/providers/answer_provider.dart

import 'dart:io';
import 'package:eauxiliary/models/folder_item.dart';
import 'package:eauxiliary/services/file_service.dart';
import 'package:eauxiliary/utils/simple_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `AnswerProvider` 是一个核心的状态管理器 (ChangeNotifier)。
///
/// 它负责管理应用的多个关键状态和业务逻辑，包括：
/// - 从文件系统加载、分组和过滤资源文件夹。
/// - 根据用户选择的文件夹组提取和处理答案。
/// - 管理用户的激活状态、个人信息（如姓名和类型）和隐私策略同意状态。
/// - 提供刷新、清除缓存等操作，以确保数据的实时性和准确性。
///
/// 此 Provider 与 `SettingsProvider` 紧密协作，以响应用户在设置页面中所做的更改。
class AnswerProvider with ChangeNotifier {
  // region 状态变量
  String _currentAnswers = '';
  String get currentAnswers => _currentAnswers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _userType = 'normal';
  String get userType => _userType;

  String? _studentName;
  String? get studentName => _studentName;
  bool get isActivated => true;

  List<({List<FolderItem> group, String tag})> _groupedFolders = [];
  List<({List<FolderItem> group, String tag})> get groupedFolders =>
      _groupedFolders;

  bool _hasReadPrivacyPolicy = false;
  bool get hasReadPrivacyPolicy => _hasReadPrivacyPolicy;

  // region 加载与刷新控制
  DateTime _lastLoadTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _retryInProgress = false;
  static const double _timeThreshold = 3.0;
  // endregion

  AnswerProvider();

  Future<void> initialize() async {
    await loadStudentData();
    await loadGroupedFolders();
    await loadHasReadPrivacyPolicy();
  }

  bool _shouldSkipRefresh(bool forceRefresh) {
    final now = DateTime.now();
    if (forceRefresh) return false;

    if (_retryInProgress) {
      debugPrint("AnswerProvider: 跳过刷新 - 已有正在进行的加载操作。");
      return true;
    }

    if (_isLoading) {
      debugPrint("AnswerProvider: 跳过刷新 - 正在加载中。");
      return true;
    }

    final secondsSinceLastLoad = now.difference(_lastLoadTime).inSeconds;
    if (_groupedFolders.isNotEmpty && secondsSinceLastLoad < 1) {
      debugPrint("AnswerProvider: 跳过刷新 - 距离上次加载仅 $secondsSinceLastLoad 秒。");
      return true;
    }

    return false;
  }

  Future<void> loadGroupedFolders({
    bool forceRefresh = false,
    bool deepScan = false,
  }) async {
    if (_shouldSkipRefresh(forceRefresh)) {
      return;
    }

    _isLoading = true;
    _retryInProgress = true;
    if (_groupedFolders.isEmpty) {
      notifyListeners();
    }

    try {
      final logMessage = "开始加载分组文件夹" +
          (forceRefresh ? ' (强制刷新)' : '') +
          (deepScan ? ' (深度扫描)' : '');
      debugPrint("AnswerProvider: $logMessage");

      await _performFolderLoading(deepScan);
    } catch (e) {
      debugPrint("AnswerProvider: 加载分组文件夹时发生严重错误: $e");
      _groupedFolders = [];
    } finally {
      _isLoading = false;
      _retryInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _performFolderLoading(bool deepScan) async {
    List<FolderItem> folders =
        await FileService.getSortedResourceFolders(deepScan: deepScan);

    if (folders.isEmpty) {
      debugPrint("AnswerProvider: 未找到任何资源文件夹。");
      _groupedFolders = [];
      return;
    }

    debugPrint("AnswerProvider: 获取到 ${folders.length} 个文件夹，开始处理...");
    _processLoadedFolders(folders);
    _lastLoadTime = DateTime.now();
  }

  void _processLoadedFolders(List<FolderItem> folders) {
    var groupedByTime = FileService.groupResourceFoldersByTime(folders,
        timeThresholdSeconds: _timeThreshold);

    var filteredGroups =
        FileService.filterFolderGroups(groupedByTime, true, _userType);

    var markedGroups = FileService.markAndFilterGroups(filteredGroups);

    if (markedGroups.isNotEmpty) {
      _groupedFolders = [markedGroups.first];
      debugPrint("AnswerProvider: 社区版本限制，只显示最近的1个试题组");
    } else {
      _groupedFolders = [];
    }

    debugPrint("AnswerProvider: 文件夹处理完成，社区版本显示 ${_groupedFolders.length} 组。");
  }

  Future<void> fetchAnswers(List<File> group) async {
    _isLoading = true;
    _currentAnswers = '';
    notifyListeners();

    try {
      await _prepareForAnswerFetching();

      if (group.isEmpty) {
        _currentAnswers = '加载答案失败: 文件组为空。';
        debugPrint("AnswerProvider: 文件组为空，无法获取答案。");
        return;
      }

      debugPrint("AnswerProvider: 开始获取答案，文件数: ${group.length}");

      final folderItems = _prepareFolderItemsForAnswerFetching(group);
      if (folderItems.isEmpty) {
        _currentAnswers = '加载答案失败: 未能处理任何有效的文件夹。';
        return;
      }

      final rawAnswers =
          await FileService.getAnswersFromFolderGroup(folderItems);
      _handleFetchedAnswers(rawAnswers);
    } catch (e) {
      _currentAnswers = '加载答案失败: $e';
      debugPrint("AnswerProvider: 获取答案时发生严重错误: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _prepareForAnswerFetching() async {
    debugPrint("AnswerProvider: 准备获取答案");
  }

  List<FolderItem> _prepareFolderItemsForAnswerFetching(List<File> group) {
    final folderItems = <FolderItem>[];
    final isWindows = Platform.isWindows;

    for (var file in group) {
      try {
        DateTime modifiedTime;
        try {
          modifiedTime = file.statSync().modified;
        } catch (e) {
          modifiedTime = DateTime.now();
          debugPrint(
              "AnswerProvider: 无法获取文件修改时间 for ${file.path}, 使用当前时间。错误: $e");
        }

        folderItems.add(FolderItem(
          name: file.path,
          path: file.path,
          lastModified: modifiedTime,
          tag: isWindows ? 'windows' : '',
        ));
      } catch (e) {
        debugPrint("AnswerProvider: 处理文件夹路径时出错: ${file.path}, 错误: $e");
      }
    }
    return folderItems;
  }

  void _handleFetchedAnswers(String rawAnswers) {
    debugPrint("AnswerProvider: 已获取原始答案，长度: ${rawAnswers.length}");
    if (rawAnswers.isEmpty) {
      _currentAnswers = '未能获取答案，请确保文件路径正确且内容有效。';
    } else {
      _currentAnswers = rawAnswers;
    }
  }

  /// 加载学生数据（姓名、用户类型）
  Future<void> loadStudentData() async {
    _studentName = await FileService.getStudentName();
    _userType = await getUserType(_studentName);
    notifyListeners();
  }

  /// 根据用户名从黑白名单中确定用户类型。
  Future<String> getUserType(String? username) async {
    if (username == null) return 'normal';
    final whitelistedUsers = await SimpleStorage.getWhitelist();
    if (whitelistedUsers.contains(username)) return 'whitelist';
    final blacklistedUsers = await SimpleStorage.getBlacklist();
    if (blacklistedUsers.contains(username)) return 'blacklist';
    return 'normal';
  }

  /// 从 `SharedPreferences` 加载用户是否已阅读隐私协议的状态。
  Future<void> loadHasReadPrivacyPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasReadPrivacyPolicy = prefs.getBool('has_read_privacy_policy') ?? false;
    } catch (e) {
      _hasReadPrivacyPolicy = false;
    } finally {
      notifyListeners();
    }
  }

  /// 将用户是否已阅读隐私协议的状态保存到 `SharedPreferences`。
  /// [value] 是否已阅读。
  Future<bool> setPrivacyPolicyRead(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setBool('has_read_privacy_policy', value);
      _hasReadPrivacyPolicy = value;
      notifyListeners();
      return result;
    } catch (e) {
      return false;
    }
  }

  /// 清除所有与答案相关的本地缓存。
  Future<void> clearAnswerCache() async {
    _isLoading = true;
    notifyListeners();
    try {
      await SimpleStorage.clearAllAnswerCache();
      _groupedFolders.clear();
      _lastLoadTime = DateTime.fromMillisecondsSinceEpoch(0);
      await loadGroupedFolders();
    } catch (e) {
      debugPrint("AnswerProvider: 清除缓存时出错: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 撤销隐私协议同意，并将应用重置到首次运行状态。
  Future<bool> revokePrivacyConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_read_privacy_policy', false);
      _hasReadPrivacyPolicy = false;
      await prefs.setBool('isFirstRun', true);
      _groupedFolders.clear();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("AnswerProvider: 撤销隐私协议同意时出错: $e");
      return false;
    }
  }
}
