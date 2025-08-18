import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

String getRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 365) return '${(difference.inDays / 365).floor()}年前';
  if (difference.inDays > 30) return '${(difference.inDays / 30).floor()}个月前';
  if (difference.inDays > 0) return '${difference.inDays}天前';
  if (difference.inHours > 0) return '${difference.inHours}小时前';
  if (difference.inMinutes > 0) return '${difference.inMinutes}分钟前';
  return '刚刚';
}

Future<bool> checkIsFirstJsonLoad() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final jsonCachePath = '${directory.path}/json_cache';
    final dir = Directory(jsonCachePath);

    // 目录不存在，说明是首次加载
    if (!await dir.exists()) {
      debugPrint("JSON缓存目录不存在，视为首次加载");
      return true;
    }

    // 检查是否存在以resource_cache或beijing开头的JSON文件
    final List<FileSystemEntity> files = await dir.list().toList();
    bool hasValidCache = false;

    for (var entity in files) {
      if (entity is File &&
          entity.path.endsWith('.json') &&
          (path.basename(entity.path).startsWith('resource_cache_') ||
              path.basename(entity.path).contains('beijing'))) {
        // 检查文件大小是否大于100字节（避免空文件）
        final fileSize = await entity.length();
        if (fileSize > 100) {
          debugPrint(
              "找到有效的JSON缓存文件: ${path.basename(entity.path)}, 大小: ${fileSize}字节");
          hasValidCache = true;
          break;
        }
      }
    }

    if (!hasValidCache) {
      debugPrint("JSON缓存目录存在但无有效的缓存文件，视为首次加载");
      return true;
    }

    debugPrint("JSON缓存已存在且有效，非首次加载");
    return false;
  } catch (e) {
    debugPrint("检查JSON缓存状态出错: $e");
    // 出错时保守处理为首次加载
    return true;
  }
}
