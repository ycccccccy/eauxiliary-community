// lib/utils/simple_storage.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// 存储服务
class SimpleStorage {
  static const String _cachePrefix = 'answer_cache_';

  // 生成缓存键
  static String _generateKey(List<File> group) {
    try {
      if (group.isEmpty) {
        return _cachePrefix + "empty_group";
      }

      final folderPath = group.firstOrNull?.path ?? "";
      // 哈希
      return _cachePrefix + folderPath.hashCode.toString();
    } catch (e) {
      debugPrint("SimpleStorage: 生成密钥时出错: $e");
      return _cachePrefix + DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// 获取缓存的答案
  static Future<String?> getCachedAnswers(List<File> group) async {
    try {
      if (group.isEmpty) {
        debugPrint("SimpleStorage: 获取缓存时组为空");
        return null;
      }

      final key = _generateKey(group);
      final prefs = await SharedPreferences.getInstance();
      final result = prefs.getString(key);

      if (result != null) {
        debugPrint("SimpleStorage: 成功获取缓存答案，键: $key");
      } else {
        debugPrint("SimpleStorage: 缓存中无此键: $key");
      }
      return result;
    } catch (e) {
      debugPrint("SimpleStorage: 获取缓存答案时出错: $e");
      return null;
    }
  }

  /// 缓存答案
  static Future<void> cacheAnswers(List<File> group, String answers) async {
    try {
      if (group.isEmpty) {
        debugPrint("SimpleStorage: 缓存答案时组为空");
        return;
      }

      if (answers.isEmpty) {
        debugPrint("SimpleStorage: 缓存答案时答案为空");
        return;
      }

      final key = _generateKey(group);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, answers);

      debugPrint("SimpleStorage: 成功缓存答案，键: $key");
    } catch (e) {
      debugPrint("SimpleStorage: 缓存答案时出错: $e");
    }
  }

  /// 获取白名单用户列表
  static Future<List<String>> getWhitelist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('whitelist');
      return value?.split(',') ?? [];
    } catch (e) {
      debugPrint("SimpleStorage: 获取白名单时出错: $e");
      return [];
    }
  }

  /// 设置白名单用户列表
  static Future<void> setWhitelist(List<String> whitelist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('whitelist', whitelist.join(','));
    } catch (e) {
      debugPrint("SimpleStorage: 设置白名单时出错: $e");
    }
  }

  /// 获取黑名单用户列表
  static Future<List<String>> getBlacklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('blacklist');
      return value?.split(',') ?? [];
    } catch (e) {
      debugPrint("SimpleStorage: 获取黑名单时出错: $e");
      return [];
    }
  }

  /// 设置黑名单用户列表
  static Future<void> setBlacklist(List<String> blacklist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('blacklist', blacklist.join(','));
    } catch (e) {
      debugPrint("SimpleStorage: 设置黑名单时出错: $e");
    }
  }

  /// 清除所有答案缓存
  static Future<void> clearAllAnswerCache() async {
    debugPrint('SimpleStorage: 开始清除所有答案缓存');
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // 查找所有缓存相关的键
      final cacheKeys = allKeys
          .where((key) =>
              key.contains('answer') ||
              key.contains('cache') ||
              key.contains('file_') ||
              key.startsWith('folder_') ||
              key.contains('data_'))
          .toList();

      debugPrint('SimpleStorage: 找到 ${cacheKeys.length} 个缓存项');

      int removedCount = 0;
      for (final key in cacheKeys) {
        try {
          final success = await prefs.remove(key);
          if (success) {
            removedCount++;
            debugPrint('SimpleStorage: 成功删除缓存: $key');
          }
        } catch (e) {
          debugPrint('SimpleStorage: 删除缓存时出错: $key, 错误: $e');
        }
      }

      // 强制保存更改
      await prefs.commit();

      debugPrint('SimpleStorage: 已删除 $removedCount/${cacheKeys.length} 个缓存项');

      // 清除临时文件目录
      try {
        final tempDir = await getTemporaryDirectory();
        final cacheDir = Directory('${tempDir.path}/cache');

        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
          debugPrint('SimpleStorage: 已删除缓存文件夹');

          // 重新创建空文件夹
          await cacheDir.create();
        }
      } catch (e) {
        debugPrint('SimpleStorage: 清除缓存文件夹时出错: $e');
      }

      debugPrint('SimpleStorage: 所有答案缓存已清除');
    } catch (e) {
      debugPrint('SimpleStorage: 清除缓存时出错: $e');
      rethrow;
    }
  }

  /// 清除所有数据
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('SimpleStorage: 已清除所有数据');
    } catch (e) {
      debugPrint('SimpleStorage: 清除所有数据时出错: $e');
    }
  }

  /// 通用的读取方法
  static Future<String?> read({required String key}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint("SimpleStorage: 读取数据时出错: $e");
      return null;
    }
  }

  /// 通用的写入方法
  static Future<void> write(
      {required String key, required String value}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint("SimpleStorage: 写入数据时出错: $e");
    }
  }

  /// 通用的删除方法
  static Future<void> delete({required String key}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint("SimpleStorage: 删除数据时出错: $e");
    }
  }

  /// 检查键是否存在
  static Future<bool> containsKey({required String key}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      debugPrint("SimpleStorage: 检查键时出错: $e");
      return false;
    }
  }

  /// 删除所有数据
  static Future<void> deleteAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint("SimpleStorage: 删除所有数据时出错: $e");
    }
  }
}
