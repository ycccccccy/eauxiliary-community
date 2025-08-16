// lib/models/folder_item.dart

import 'package:flutter/foundation.dart';
import '../services/shizuku_file_service.dart';

/// 表示文件系统中的一个文件夹项目。
///
/// 此类封装了文件夹的核心属性，如名称、最后修改日期、标签和路径。
/// 它还包含一个可选的 `numericId`，用于存储电脑端的纯数字ID。
class FolderItem {
  /// 文件夹的名称。
  final String name;

  /// 文件夹的最后修改日期和时间。
  final DateTime lastModified;

  /// 与文件夹关联的标签，可用于分类或过滤。
  final String tag;

  /// 文件夹的完整路径。
  final String path;

  /// 电脑端使用的纯数字ID，可选。
  final String? numericId;

  FolderItem({
    required this.name,
    required this.lastModified,
    required this.tag,
    this.path = '',
    this.numericId,
  });

  /// 从 Map 对象创建 [FolderItem] 实例的工厂构造函数。
  factory FolderItem.fromMap(Map<String, dynamic> map) {
    return FolderItem(
      name: map['name'],
      lastModified: DateTime.parse(map['lastModified']),
      tag: map['tag'],
      path: map['path'] ?? map['name'],
    );
  }

  /// 将 [FolderItem] 实例转换为 Map 对象。
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastModified': lastModified.toIso8601String(),
      'tag': tag,
      'path': path,
    };
  }

  /// 创建当前 [FolderItem] 对象的副本，并可以替换指定的属性。
  FolderItem copyWith({
    String? name,
    DateTime? lastModified,
    String? tag,
    String? path,
    String? numericId,
  }) {
    return FolderItem(
      name: name ?? this.name,
      lastModified: lastModified ?? this.lastModified,
      tag: tag ?? this.tag,
      path: path ?? this.path,
      numericId: numericId ?? this.numericId,
    );
  }

  /// 异步更新文件夹的最后修改时间。
  ///
  /// 在某些情况下（例如，从特定平台读取时），初始的 `lastModified` 时间
  /// 可能是默认值（如1970年或1971年）。此方法会通过 `ShizukuFileService`
  /// 强制获取真实的最后修改时间来纠正这个问题。
  ///
  /// [item] 需要更新的 `FolderItem` 对象。
  /// 返回一个新的 `FolderItem` 实例，其中包含更新后的时间；如果更新失败或无需更新，则返回原始对象。
  static Future<FolderItem> withUpdatedModifiedTime(FolderItem item) async {
    try {
      // 如果年份看起来像一个默认的Unix纪元时间戳，则尝试获取真实时间。
      if (item.lastModified.year <= 1971) {
        final time = await ShizukuFileService.getModifiedTime(item.name,
            forceShizuku: true);
        debugPrint(
            "FolderItem: 更新文件夹时间 - 原时间: ${item.lastModified}, 新时间: $time");
        return item.copyWith(lastModified: time);
      }
    } catch (e) {
      debugPrint("FolderItem: 获取文件夹时间失败: $e");
    }
    // 如果没有检测到需要更新或更新过程中发生错误，则返回原始项目。
    return item;
  }
}
