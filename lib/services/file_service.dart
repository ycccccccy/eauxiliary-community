// lib/services/file_service.dart

import 'package:eauxiliary/utils/simple_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eauxiliary/models/folder_item.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import '../utils/utils.dart';
import 'shizuku_file_service.dart';

class FileService {
  // ignore: constant_identifier_names
  static const ZERO_WIDTH_SPACE = "\u200B";

  // 是否使用Shizuku
  static bool _useShizuku = false;

  // 获取是否使用Shizuku
  static bool get useShizuku => _useShizuku;

  // 设置是否使用Shizuku
  static Future<bool> setUseShizuku(bool value) async {
    if (value) {
      // 如果要启用Shizuku，先检查是否可用
      final available = await ShizukuFileService.isAvailable();
      if (!available) {
        // 如果Shizuku不可用，尝试初始化
        final initialized = await ShizukuFileService.initialize();
        if (!initialized) {
          debugPrint("FileService: Shizuku初始化失败，无法启用");
          return false;
        }
      }

      // 启用强制Shizuku模式
      await ShizukuFileService.setForceShizukuMode(true);
    } else {
      // 禁用强制Shizuku模式
      await ShizukuFileService.setForceShizukuMode(false);
    }

    _useShizuku = value;
    // 保存设置
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_shizuku', value);
    debugPrint("FileService: ${value ? '启用' : '禁用'}Shizuku访问");
    return true;
  }

  // 初始化设置
  static Future<void> initSettings() async {
    try {
      // 检查平台类型
      final isWindowsPlatform = Platform.isWindows;
      debugPrint("FileService: 当前平台是Windows: $isWindowsPlatform");

      // Windows平台下不使用Shizuku
      if (isWindowsPlatform) {
        _useShizuku = false;
        debugPrint("FileService: Windows平台，禁用Shizuku");
      }

      // 首先加载Shizuku设置
      if (!isWindowsPlatform) {
        await ShizukuFileService.loadShizukuModeSetting();
      }

      final prefs = await SharedPreferences.getInstance();

      // 非Windows平台时，初始化Shizuku
      if (!isWindowsPlatform) {
        // 首先从Shizuku服务获取设置，如果已启用强制模式，则无条件使用Shizuku
        _useShizuku = ShizukuFileService.isForceShizukuMode;

        // 如果Shizuku服务未启用强制模式，则检查应用自身的设置
        if (!_useShizuku) {
          _useShizuku = prefs.getBool('use_shizuku') ?? false;
        }

        debugPrint(
            "FileService: 初始化设置，使用Shizuku: $_useShizuku，强制模式: ${ShizukuFileService.isForceShizukuMode}");

        if (_useShizuku) {
          // 如果设置了使用Shizuku，尝试初始化
          await ShizukuFileService.initialize();
        }
      }
    } catch (e) {
      debugPrint("FileService: 初始化设置时出错: $e");
    }
  }

  // 获取根目录路径
  Future<String?> getRootDirectoryPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedPath = prefs.getString('directory_uri');

      // Windows平台处理
      if (Platform.isWindows) {
        // 如果已保存路径，优先使用保存的路径
        if (savedPath != null && savedPath.isNotEmpty) {
          bool exists = false;
          try {
            final directory = Directory(savedPath);
            exists = await directory.exists();
          } catch (e) {
            debugPrint("FileService: 检查Windows保存路径时出错: $e");
          }

          if (exists) {
            debugPrint("FileService: 使用Windows已保存路径: $savedPath");
            return savedPath;
          } else {
            debugPrint("FileService: Windows已保存路径无效: $savedPath");
          }
        }

        // 如果没有保存路径或路径无效，使用默认的%appdata%\ETS目录
        try {
          final appDataPath = Platform.environment['APPDATA'];
          if (appDataPath != null && appDataPath.isNotEmpty) {
            // 明确使用path库的join方法
            final defaultPath = path.join(appDataPath, 'ETS');
            debugPrint("FileService: 使用Windows默认路径: $defaultPath");
            return defaultPath;
          } else {
            debugPrint("FileService: 无法获取Windows APPDATA环境变量");
          }
        } catch (e) {
          debugPrint("FileService: 获取Windows默认路径时出错: $e");
        }

        return null;
      }

      // 非Windows平台的处理（原有逻辑）
      if (savedPath != null && savedPath.isNotEmpty) {
        bool exists = false;

        if (_useShizuku) {
          // 使用Shizuku检查路径是否存在
          exists = await ShizukuFileService.exists(savedPath);
        } else {
          // 使用常规方法检查路径是否存在
          final directory = Directory(savedPath);
          exists = await directory.exists();
        }

        if (exists) {
          debugPrint("FileService: 从SharedPreferences获取到有效路径: $savedPath");
          return savedPath;
        } else {
          debugPrint("FileService: SharedPreferences中的路径无效: $savedPath");
        }
      } else {
        debugPrint("FileService: SharedPreferences中没有保存的路径");
      }

      // 如果没有保存路径或路径无效，尝试获取默认路径
      try {
        bool storageExists = false;

        if (_useShizuku) {
          // 使用Shizuku检查存储是否存在
          storageExists =
              await ShizukuFileService.exists('/storage/emulated/0');
        } else {
          // 使用常规方法检查存储是否存在
          final storageDir = Directory('/storage/emulated/0');
          storageExists = await storageDir.exists();
        }

        if (storageExists) {
          final defaultPath =
              '/storage/emulated/0/A\u200Bndroid/data/com.ets100.secondary';
          debugPrint("FileService: 尝试使用默认路径: $defaultPath");
          return defaultPath;
        }
      } catch (e) {
        debugPrint("FileService: 获取默认存储路径时出错: $e");
      }

      return null;
    } catch (e) {
      debugPrint("FileService: 获取根目录路径时出错: $e");
      return null;
    }
  }

// 获取排序后的资源文件夹列表 (修改为使用 File)
  static Future<List<FolderItem>> getSortedResourceFolders(
      {bool deepScan = false}) async {
    // 检查平台类型
    final isWindowsPlatform = Platform.isWindows;

    // 深度扫描时添加日志
    if (deepScan) {
      debugPrint("FileService: 以深度扫描模式获取资源文件夹");
    }

    // Windows平台特殊处理
    if (isWindowsPlatform) {
      return await _getWindowsResourceFolders(deepScan: deepScan);
    }

    try {
      String? rootDirectoryPath =
          await FileService().getRootDirectoryPath(); // 获取根目录路径
      debugPrint("FileService: 获取到根目录路径: $rootDirectoryPath");

      if (rootDirectoryPath == null) {
        debugPrint("FileService: 根目录路径为空");
        return [];
      }

      // 确保路径使用正确的分隔符
      rootDirectoryPath = rootDirectoryPath.replaceAll('\\', '/');
      debugPrint(
          "FileService: 规范化路径: $rootDirectoryPath，当前使用Shizuku: $_useShizuku");

      // 检查目录是否存在
      bool directoryExists = false;

      if (_useShizuku) {
        // 使用Shizuku检查目录是否存在
        directoryExists = await ShizukuFileService.exists(rootDirectoryPath);
        debugPrint("FileService: Shizuku模式检查路径存在性: $directoryExists");
      } else {
        // 使用常规方法检查目录是否存在
        try {
          var currentDirectory = Directory(rootDirectoryPath);
          directoryExists = await currentDirectory.exists();
          debugPrint("FileService: 普通模式检查路径存在性: $directoryExists");
        } catch (e) {
          debugPrint("FileService: 普通模式检查路径时出错: $e");
          // 如果普通模式出错，尝试使用Shizuku
          final shizukuAvailable = await ShizukuFileService.isAvailable();
          if (shizukuAvailable) {
            directoryExists =
                await ShizukuFileService.exists(rootDirectoryPath);
            debugPrint("FileService: 普通模式失败后使用Shizuku检查路径: $directoryExists");

            // 如果Shizuku能访问，建议使用Shizuku模式
            if (directoryExists) {
              _useShizuku = true;
              debugPrint("FileService: 自动切换到Shizuku模式");
              // 保存设置但不强制开启Shizuku
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('use_shizuku', true);
            }
          }
        }
      }

      if (!directoryExists) {
        debugPrint("FileService: 根目录不存在或无法访问: $rootDirectoryPath");

        // 如果常规方法失败，尝试使用Shizuku（如果尚未使用）
        if (!_useShizuku) {
          debugPrint("FileService: 尝试使用Shizuku访问");
          final shizukuAvailable = await ShizukuFileService.initialize();
          if (shizukuAvailable) {
            _useShizuku = true;
            // 保存设置
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('use_shizuku', true);

            // 使用Shizuku重新检查目录是否存在
            directoryExists =
                await ShizukuFileService.exists(rootDirectoryPath);
            debugPrint("FileService: Shizuku初始化后检查路径: $directoryExists");
            if (!directoryExists) {
              debugPrint("FileService: 使用Shizuku仍无法访问目录");
              return [];
            }

            debugPrint("FileService: 使用Shizuku成功访问目录");
          } else {
            debugPrint("FileService: Shizuku不可用");
            return [];
          }
        } else {
          return [];
        }
      }

      // 检查根目录是否已经包含正确的结构
      String resourcePath;

      // 检查是否已经包含/files部分
      if (rootDirectoryPath.endsWith('/com.ets100.secondary') ||
          rootDirectoryPath.contains('/com.ets100.secondary/')) {
        if (rootDirectoryPath
            .contains('/files/Download/ETS_SECONDARY/resource')) {
          // 路径已经包含完整结构，直接使用
          resourcePath = rootDirectoryPath;
          debugPrint("FileService: 路径已包含resource目录: $resourcePath");
        } else if (rootDirectoryPath.contains('/files/')) {
          // 路径包含files但没有完整路径，添加剩余部分
          resourcePath =
              '$rootDirectoryPath${rootDirectoryPath.endsWith('/') ? '' : '/'}'
              'Download/ETS_SECONDARY/resource';
          debugPrint("FileService: 路径已包含files目录，补充后续路径: $resourcePath");
        } else {
          // 只有包名，添加完整子路径
          resourcePath =
              '$rootDirectoryPath${rootDirectoryPath.endsWith('/') ? '' : '/'}'
              'files/Download/ETS_SECONDARY/resource';
          debugPrint("FileService: 路径已包含包名，补充后续路径: $resourcePath");
        }
      } else {
        // 完全不包含期望结构，使用完整路径
        resourcePath =
            '$rootDirectoryPath/A${ZERO_WIDTH_SPACE}ndroid/data/com.ets100.secondary/'
            'files/Download/ETS_SECONDARY/resource';
        debugPrint("FileService: 使用完整路径: $resourcePath");
      }

      debugPrint("FileService: 尝试直接访问资源目录: $resourcePath");

      // 检查资源目录是否存在
      bool resourceDirExists = false;
      List<FileSystemEntity> contents = [];

      // 尝试三种不同的方式访问资源目录
      // 1. 首先使用当前模式（Shizuku或普通）
      if (_useShizuku) {
        // 使用Shizuku检查资源目录是否存在
        resourceDirExists = await ShizukuFileService.exists(resourcePath);
        debugPrint("FileService: Shizuku模式检查资源目录存在性: $resourceDirExists");
        if (resourceDirExists) {
          // 使用Shizuku列出目录内容
          contents = await ShizukuFileService.listDirectory(resourcePath);
          debugPrint("FileService: Shizuku模式列出目录内容，文件数: ${contents.length}");
        }
      } else {
        try {
          // 使用常规方法检查资源目录是否存在
          final resourceDir = Directory(resourcePath);
          resourceDirExists = await resourceDir.exists();
          debugPrint("FileService: 普通模式检查资源目录存在性: $resourceDirExists");
          if (resourceDirExists) {
            // 使用常规方法列出目录内容
            contents = await resourceDir.list().toList();
            debugPrint("FileService: 普通模式列出目录内容，文件数: ${contents.length}");
          }
        } catch (e) {
          debugPrint("FileService: 普通模式访问资源目录出错: $e");

          // 2. 如果当前模式失败，尝试切换模式
          if (!_useShizuku) {
            final shizukuAvailable = await ShizukuFileService.isAvailable();
            if (shizukuAvailable) {
              resourceDirExists = await ShizukuFileService.exists(resourcePath);
              debugPrint(
                  "FileService: 在普通模式失败后使用Shizuku检查资源目录: $resourceDirExists");

              if (resourceDirExists) {
                contents = await ShizukuFileService.listDirectory(resourcePath);
                debugPrint(
                    "FileService: 切换到Shizuku成功获取内容，文件数: ${contents.length}");

                // 自动切换模式
                _useShizuku = true;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('use_shizuku', true);
              }
            }
          }
        }
      }

      if (!resourceDirExists) {
        debugPrint("FileService: 资源目录不存在或无法访问: $resourcePath");

        // 尝试构造可能的路径
        List<String> alternativePaths = [
          // 尝试移除零宽字符
          resourcePath.replaceAll(ZERO_WIDTH_SPACE, ''),
          // 尝试添加零宽字符
          resourcePath.replaceAll('/Android/', '/A${ZERO_WIDTH_SPACE}ndroid/'),
          // 尝试不使用Android文件夹
          '$rootDirectoryPath/data/com.ets100.secondary/files/Download/ETS_SECONDARY/resource',
        ];

        debugPrint("FileService: 尝试备用路径");
        for (var path in alternativePaths) {
          debugPrint("FileService: 尝试路径: $path");

          if (_useShizuku) {
            resourceDirExists = await ShizukuFileService.exists(path);
            if (resourceDirExists) {
              contents = await ShizukuFileService.listDirectory(path);
              resourcePath = path;
              debugPrint(
                  "FileService: Shizuku成功访问备用路径: $path，文件数: ${contents.length}");
              break;
            }
          } else {
            try {
              final dir = Directory(path);
              resourceDirExists = await dir.exists();
              if (resourceDirExists) {
                // 使用常规方法列出目录内容
                contents = await dir.list().toList();
                resourcePath = path;
                debugPrint(
                    "FileService: 普通模式成功访问备用路径: $path，文件数: ${contents.length}");
                break;
              }
            } catch (e) {
              debugPrint("FileService: 普通模式访问备用路径失败: $e");

              // 尝试使用Shizuku作为最后手段
              if (!_useShizuku) {
                final shizukuAvailable = await ShizukuFileService.isAvailable();
                if (shizukuAvailable) {
                  resourceDirExists = await ShizukuFileService.exists(path);
                  if (resourceDirExists) {
                    contents = await ShizukuFileService.listDirectory(path);
                    resourcePath = path;
                    _useShizuku = true;
                    debugPrint(
                        "FileService: 切换至Shizuku成功访问备用路径: $path，文件数: ${contents.length}");

                    // 保存设置
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('use_shizuku', true);
                    break;
                  }
                }
              }
            }
          }
        }

        if (!resourceDirExists) {
          debugPrint("FileService: 无法找到有效的资源目录，所有尝试均失败");
          return [];
        }
      }

      debugPrint("FileService: 资源目录存在，开始处理目录内容");

      // 过滤目录内容，只保留目录
      List<FileSystemEntity> dirs = [];
      for (var entity in contents) {
        bool isDir = false;

        if (_useShizuku) {
          // 使用Shizuku判断是否是目录
          isDir = await ShizukuFileService.isDirectory(entity.path);
        } else {
          // 使用常规方法判断是否是目录
          try {
            isDir = await FileSystemEntity.isDirectory(entity.path);
          } catch (e) {
            debugPrint("FileService: 检查是否是目录时出错: $e");
            // 尝试使用Shizuku
            if (await ShizukuFileService.isAvailable()) {
              isDir = await ShizukuFileService.isDirectory(entity.path);
            }
          }
        }

        if (isDir) {
          dirs.add(entity);
        }
      }

      debugPrint("FileService: 找到${dirs.length}个目录");

      // 优化性能：并行处理目录
      final folderItems = <FolderItem>[];
      final contentJsonCache = <String, bool>{};

      // 由于需要检查content.json，使用批量检查以提高效率
      if (_useShizuku && dirs.length > 5) {
        // 创建要检查的content.json路径列表
        final contentJsonPaths = dirs.map((dir) {
          final path = '${dir.path}/content.json';
          // 清理路径，去除可能的对象描述和特殊字符
          return path
              .replaceAll('Directory: ', '')
              .replaceAll('File: ', '')
              .replaceAll("'", "")
              .trim();
        }).toList();

        // 批量检查文件是否存在
        debugPrint(
            "FileService: 使用批量检查${contentJsonPaths.length}个content.json文件");

        // 每次检查10个路径
        const batchSize = 10;
        for (var i = 0; i < contentJsonPaths.length; i += batchSize) {
          final endIdx = (i + batchSize < contentJsonPaths.length)
              ? i + batchSize
              : contentJsonPaths.length;
          final batch = contentJsonPaths.sublist(i, endIdx);

          // 并行处理批次，提高扫描速度
          await Future.wait(batch.map((path) async {
            final exists = await ShizukuFileService.exists(path);
            contentJsonCache[path] = exists;
            if (exists) {
              debugPrint("FileService: 找到content.json: $path");
            }
          }));
        }
      }

      // 遍历处理每个目录
      for (var dir in dirs) {
        try {
          final folderName = dir.path.split('/').last;
          // debugPrint("FileService: 检查目录: $folderName");

          // 检查是否有content.json文件
          bool hasContentJson = false;
          final contentJsonPath = '${dir.path}/content.json';
          // 清理路径，去除可能的对象描述和特殊字符
          final sanitizedContentJsonPath = contentJsonPath
              .replaceAll('Directory: ', '')
              .replaceAll('File: ', '')
              .replaceAll("'", "")
              .trim();

          // 首先检查缓存
          if (contentJsonCache.containsKey(sanitizedContentJsonPath)) {
            hasContentJson =
                contentJsonCache[sanitizedContentJsonPath] ?? false;
            debugPrint("FileService: 从缓存获取content.json状态: $hasContentJson");
          } else if (_useShizuku) {
            // 使用Shizuku检查content.json是否存在
            hasContentJson =
                await ShizukuFileService.exists(sanitizedContentJsonPath);
            contentJsonCache[sanitizedContentJsonPath] = hasContentJson;
          } else {
            // 使用常规方法列出目录内容
            List<FileSystemEntity> files = [];
            try {
              if (dir is Directory) {
                files = await dir.list().toList();
              } else {
                final directory = Directory(dir.path);
                files = await directory.list().toList();
              }
            } catch (e) {
              debugPrint("FileService: 普通方式列出目录内容失败: $e");

              // 尝试使用Shizuku
              if (await ShizukuFileService.isAvailable()) {
                files = await ShizukuFileService.listDirectory(dir.path);
              } else {
                files = []; // 如果都失败，使用空列表
              }
            }

            // 检查是否有content.json文件
            final contentJsonFiles = files
                .where((file) =>
                    file is File && file.path.endsWith('content.json'))
                .toList();
            hasContentJson = contentJsonFiles.isNotEmpty;
          }

          debugPrint(
              "FileService: 目录 $folderName 包含content.json: $hasContentJson");

          if (hasContentJson) {
            // 获取content.json文件的修改时间，或者目录的修改时间
            DateTime fileModifiedTime;
            try {
              // 尝试获取目录的直接修改时间
              if (_useShizuku) {
                fileModifiedTime =
                    await ShizukuFileService.getModifiedTime(dir.path);
              } else {
                final fileStats = await Directory(dir.path).stat();
                fileModifiedTime = fileStats.modified;
              }
              // debugPrint("FileService: 使用目录修改时间: $fileModifiedTime");
            } catch (e) {
              // 如果无法获取目录时间，使用当前时间
              debugPrint("FileService: 无法获取修改时间，使用当前时间: $e");
              fileModifiedTime =
                  DateTime.now().subtract(const Duration(minutes: 1));
            }

            folderItems.add(FolderItem(
              name: dir.path,
              path: dir.path, // 确保 path 属性被赋值
              lastModified: fileModifiedTime,
              tag: 'ETS',
            ));
            // debugPrint("FileService: 添加文件夹: $folderName");
          }
        } catch (e) {
          debugPrint("FileService: 处理目录时出错: $e");
          // 错误时继续处理下一个目录
        }
      }

      debugPrint("FileService: 符合条件的文件夹数量: ${folderItems.length}");

      if (folderItems.isEmpty) {
        debugPrint("FileService: 未找到符合条件的文件夹");
        return [];
      }

      // 获取文件夹列表并显示
      await updateFolderTimesAndSort(folderItems);

      return folderItems;
    } catch (e) {
      debugPrint("FileService: 获取资源文件夹时出错: $e");
      return [];
    }
  }

  // 获取文件夹列表并显示
  static Future<void> updateFolderTimesAndSort(List<FolderItem> folders) async {
    try {
      // 获取所有文件夹的路径列表
      final paths = folders.map((f) => f.name).toList();

      if (_useShizuku) {
        // 如果设置中启用了 Shizuku，则使用 Shizuku 方式
        debugPrint("FileService: 使用 Shizuku 方式获取修改时间");
        final timesMap = await ShizukuFileService.getFilesModifiedTimes(paths,
            forceShizuku: true);

        // 更新文件夹的修改时间
        for (int i = 0; i < folders.length; i++) {
          final folder = folders[i];
          if (timesMap.containsKey(folder.name)) {
            final time = timesMap[folder.name]!;
            folders[i] = folder.copyWith(lastModified: time);
            debugPrint(
                "FileService: 文件夹时间更新(Shizuku) - ${folder.name}: ${time}");
          }
        }
      } else {
        // 如果设置中未启用 Shizuku，则使用普通文件方式
        debugPrint("FileService: 使用普通文件方式获取修改时间");
        for (int i = 0; i < folders.length; i++) {
          try {
            final folder = folders[i];
            final stat = await FileStat.stat(folder.name);
            if (stat.modified.isAfter(DateTime(1971))) {
              folders[i] = folder.copyWith(lastModified: stat.modified);
              debugPrint(
                  "FileService: 文件夹时间更新(普通) - ${folder.name}: ${stat.modified}");
            }
          } catch (e) {
            debugPrint("FileService: 获取文件夹时间失败: $e");
          }
        }
      }

      // 按修改时间排序文件夹
      folders.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      debugPrint("FileService: 文件夹已按修改时间排序");

      if (folders.isNotEmpty) {
        debugPrint(
            "FileService: 排序后第一个文件夹: ${folders.first.name}, 时间: ${folders.first.lastModified}");
      }
    } catch (e) {
      debugPrint("FileService: 更新文件夹时间时出错: $e");
    }
  }

  static List<List<FolderItem>> groupResourceFoldersByTime(
      List<FolderItem> folders,
      {double timeThresholdSeconds = 1.0}) {
    try {
      debugPrint(
          "FileService: 开始按时间分组，输入文件夹数量: ${folders.length}，时间阈值: $timeThresholdSeconds秒");

      if (folders.isEmpty) {
        debugPrint("FileService: 输入文件夹列表为空");
        return [];
      }

      // 按修改时间降序排序
      final sortedFolders = List<FolderItem>.from(folders)
        ..sort((a, b) => b.lastModified.compareTo(a.lastModified));

      debugPrint(
          "FileService: 排序后第一个文件夹: ${sortedFolders.first.name}, 时间: ${sortedFolders.first.lastModified}");
      if (sortedFolders.length > 1) {
        debugPrint(
            "FileService: 排序后第二个文件夹: ${sortedFolders[1].name}, 时间: ${sortedFolders[1].lastModified}");
      }
      debugPrint(
          "FileService: 排序后最后一个文件夹: ${sortedFolders.last.name}, 时间: ${sortedFolders.last.lastModified}");

      // 动态时间间隔分组逻辑：基于传入的时间阈值
      List<List<FolderItem>> groups = [];
      if (sortedFolders.isNotEmpty) {
        List<FolderItem> currentGroup = [sortedFolders.first];
        for (int i = 1; i < sortedFolders.length; i++) {
          final currentFolder = sortedFolders[i];
          final previousFolder = currentGroup.last;
          final timeDifference = previousFolder.lastModified
              .difference(currentFolder.lastModified);

          // 检查时间差是否在设定的阈值内（转换为毫秒进行比较以支持小数秒）
          if (timeDifference.inMilliseconds.abs() <=
              (timeThresholdSeconds * 1000).round()) {
            currentGroup.add(currentFolder);
          } else {
            // 时间差超过阈值，结束当前组，开始新组
            groups.add(currentGroup);
            currentGroup = [currentFolder];
          }
        }
        // 添加最后一组
        groups.add(currentGroup);
      }

      debugPrint(
          "FileService: 分组完成，共${groups.length}组，时间阈值: $timeThresholdSeconds秒");
      for (int i = 0; i < groups.length; i++) {
        final groupFolders =
            groups[i].map((f) => f.name.split('/').last).toList();
        final firstTime = groups[i].first.lastModified;
        final lastTime = groups[i].last.lastModified;
        final timeDiff = firstTime.difference(lastTime);
        debugPrint(
            "FileService: 第${i + 1}组包含${groups[i].length}个文件夹: $groupFolders, 时间范围: $firstTime 到 $lastTime (间隔: ${timeDiff.inMilliseconds / 1000}秒)");
      }

      return groups;
    } catch (e) {
      debugPrint("FileService: 按时间分组时出错: $e");
      return [];
    }
  }

  static List<List<FolderItem>> filterFolderGroups(
    List<List<FolderItem>> groupedFolders,
    bool isActivated,
    String userType,
  ) {
    debugPrint("FileService: 过滤前分组数量: ${groupedFolders.length}");

    // 打印每个分组的信息
    for (int i = 0; i < groupedFolders.length; i++) {
      final groupNames =
          groupedFolders[i].map((f) => f.name.split('/').last).toList();
      debugPrint(
          "FileService: 过滤前分组[$i]包含${groupedFolders[i].length}个文件夹: $groupNames");
    }

    // 只保留深圳高中题型，过滤掉其他地区
    List<List<FolderItem>> result = switch (userType) {
      'blacklist' => [], // 黑名单用户看不到内容
      _ =>
        groupedFolders.where((group) => group.length == 3).toList(), // 只保留深圳高中
    };

    debugPrint(
        "FileService: 社区版本过滤后分组数量: ${result.length}（仅深圳高中），用户类型: $userType");
    return result;
  }

// 标记题库类型并更新文件夹列表适配器 (调整标记逻辑)
  static List<({List<FolderItem> group, String tag})> markAndFilterGroups(
      List<List<FolderItem>> groupedFolders) {
    try {
      debugPrint("FileService: 开始标记分组，输入分组数量: ${groupedFolders.length}");

      // 创建结果列表
      List<({List<FolderItem> group, String tag})> result = [];

      // 根据分组大小确定标签
      for (int i = 0; i < groupedFolders.length; i++) {
        final group = groupedFolders[i];
        String tag;
        final folderNames = group.map((f) => f.name.split('/').last).toList();

        // 只支持深圳高中
        switch (group.length) {
          case 3:
            tag = "深圳高中";
            break;
          default:
            tag = "不支持";
        }

        debugPrint(
            "FileService: 分组[$i]包含${group.length}个文件夹: $folderNames, 标记为: $tag");

        // 添加到结果列表
        result.add((group: group, tag: tag));
      }

      debugPrint("FileService: 标记完成，共标记了${result.length}个组");
      return result;
    } catch (e) {
      debugPrint("FileService: 标记和过滤组时出错: $e");
      return []; // 出错时返回空列表
    }
  }

  // 获取学生姓名
  static Future<String?> getStudentName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? studentName = prefs.getString('student_name');

      if (studentName != null) {
        debugPrint("FileService: 从缓存获取到学生姓名: $studentName");
        return studentName;
      }

      debugPrint("FileService: 缓存中无学生姓名，尝试从文件读取");
      String? rootDirectoryPath = await FileService().getRootDirectoryPath();
      if (rootDirectoryPath == null) {
        debugPrint("FileService: 根目录路径为空，无法获取学生姓名");
        return null;
      }

      // 确保路径使用正确的分隔符
      rootDirectoryPath = rootDirectoryPath.replaceAll('\\', '/');

      // 检查根目录是否已经包含正确的结构
      String tempPath;

      // 检查是否已经包含/files部分
      if (rootDirectoryPath.endsWith('/com.ets100.secondary') ||
          rootDirectoryPath.contains('/com.ets100.secondary/')) {
        // 已经包含应用包名，检查是否已经包含files路径
        if (rootDirectoryPath.contains('/files/Download/ETS_SECONDARY/temp')) {
          // 路径已经包含完整结构，直接使用
          tempPath = rootDirectoryPath;
          debugPrint("FileService: 路径已包含temp目录: $tempPath");
        } else if (rootDirectoryPath.contains('/files/')) {
          // 路径包含files但没有完整路径，添加剩余部分
          tempPath =
              '$rootDirectoryPath${rootDirectoryPath.endsWith('/') ? '' : '/'}'
              'Download/ETS_SECONDARY/temp';
          debugPrint("FileService: 路径已包含files目录，补充后续路径: $tempPath");
        } else {
          // 只有包名，添加完整子路径
          tempPath =
              '$rootDirectoryPath${rootDirectoryPath.endsWith('/') ? '' : '/'}'
              'files/Download/ETS_SECONDARY/temp';
          debugPrint("FileService: 路径已包含包名，补充后续路径: $tempPath");
        }
      } else {
        // 完全不包含期望结构，使用完整路径
        tempPath =
            '$rootDirectoryPath/A${ZERO_WIDTH_SPACE}ndroid/data/com.ets100.secondary/'
            'files/Download/ETS_SECONDARY/temp';
        debugPrint("FileService: 使用完整路径: $tempPath");
      }

      debugPrint("FileService: 尝试访问temp目录: $tempPath");

      try {
        // 优先尝试使用Shizuku访问，如果已经启用Shizuku模式
        if (_useShizuku) {
          debugPrint("FileService: 使用Shizuku模式访问temp目录");

          // 检查目录是否存在
          final tempExists =
              await ShizukuFileService.exists(tempPath, forceShizuku: true);
          if (!tempExists) {
            debugPrint("FileService: Shizuku模式下temp目录不存在");
            return null;
          }

          // 获取目录内容
          final files = await ShizukuFileService.listDirectory(tempPath,
              forceShizuku: true);
          if (files.isEmpty) {
            debugPrint("FileService: Shizuku模式下temp目录为空");
            return null;
          }

          // 找到第一个文件
          final fileList = files
              .where((file) => file.path.split('/').last.contains('.json'))
              .toList();
          if (fileList.isEmpty) {
            debugPrint("FileService: Shizuku模式下目录中没有JSON文件");
            return null;
          }

          final filePath = fileList.first.path;
          debugPrint("FileService: Shizuku模式下尝试读取文件: $filePath");

          // 读取文件内容
          final content =
              await ShizukuFileService.readFile(filePath, forceShizuku: true);
          final data = jsonDecode(content);
          studentName = data['data'][0]['student_name'];
          debugPrint("FileService: Shizuku模式下获取到学生姓名: $studentName");

          // 保存到SharedPreferences
          await prefs.setString('student_name', studentName!);
          debugPrint("FileService: 学生姓名已保存到缓存");
          return studentName;
        }

        // 如果未启用Shizuku，使用常规方式
        var tempDir = Directory(tempPath);
        final exists = await tempDir.exists();

        if (!exists) {
          debugPrint("FileService: temp目录不存在(普通模式)，尝试其他路径");

          // 尝试多种可能的路径结构
          final possiblePaths = [
            '$rootDirectoryPath/files/Download/ETS_SECONDARY/temp',
            '$rootDirectoryPath/Download/ETS_SECONDARY/temp',
            '$rootDirectoryPath/ETS_SECONDARY/temp',
            '$rootDirectoryPath/temp',
          ];

          bool found = false;
          for (final path in possiblePaths) {
            debugPrint("FileService: 尝试备选路径: $path");
            final dir = Directory(path);
            if (await dir.exists()) {
              tempDir = dir;
              found = true;
              debugPrint("FileService: 找到有效路径: $path");
              break;
            }
          }

          if (!found) {
            debugPrint("FileService: 所有备选路径均无效(普通模式)，尝试使用Shizuku");

            // 尝试使用Shizuku
            debugPrint("FileService: 尝试启用Shizuku访问");
            final shizukuAvailable = await ShizukuFileService.initialize();
            if (!shizukuAvailable) {
              debugPrint("FileService: Shizuku初始化失败，无法获取学生姓名");
              return null;
            }

            // 启用Shizuku模式
            _useShizuku = true;
            await ShizukuFileService.setForceShizukuMode(true);

            // 保存设置
            await prefs.setBool('use_shizuku', true);

            // 使用Shizuku重新尝试
            return await getStudentName(); // 递归调用，这次将使用Shizuku
          }
        }

        // 读取文件中的学生姓名
        try {
          final files = await tempDir.list().toList();
          if (files.isEmpty) {
            debugPrint("FileService: 目录为空");
            return null;
          }

          final fileList = files
              .whereType<File>()
              .where((file) => file.path.endsWith('.json'))
              .toList();
          if (fileList.isEmpty) {
            debugPrint("FileService: 目录中没有JSON文件");
            return null;
          }

          final file = fileList.first;
          debugPrint("FileService: 尝试从文件读取学生姓名: ${file.path}");

          try {
            final content = await file.readAsString();
            final data = jsonDecode(content);
            studentName = data['data'][0]['student_name'];
            debugPrint("FileService: 获取到学生姓名: $studentName");

            // 保存到 SharedPreferences
            await prefs.setString('student_name', studentName!);
            debugPrint("FileService: 学生姓名已保存到缓存");
          } catch (readError) {
            debugPrint("FileService: 读取文件内容时出错: $readError，尝试使用Shizuku");

            // 权限错误，尝试使用Shizuku
            if (readError.toString().contains("Permission denied") ||
                readError.toString().contains("errno = 13")) {
              // 启用Shizuku模式
              debugPrint("FileService: 启用Shizuku模式");
              _useShizuku = true;

              // 初始化Shizuku
              final initialized = await ShizukuFileService.initialize();
              if (!initialized) {
                debugPrint("FileService: Shizuku初始化失败");
                return null;
              }

              await ShizukuFileService.setForceShizukuMode(true);

              // 保存设置
              await prefs.setBool('use_shizuku', true);

              // 使用Shizuku读取文件
              try {
                final content = await ShizukuFileService.readFile(file.path,
                    forceShizuku: true);
                final data = jsonDecode(content);
                studentName = data['data'][0]['student_name'];
                debugPrint("FileService: 使用Shizuku获取到学生姓名: $studentName");

                // 保存到 SharedPreferences
                await prefs.setString('student_name', studentName!);
                debugPrint("FileService: 学生姓名已保存到缓存");
              } catch (shizukuError) {
                debugPrint("FileService: 使用Shizuku读取文件也失败: $shizukuError");
                return null;
              }
            } else {
              // 其他错误
              debugPrint("FileService: 获取学生姓名时发生非权限错误: $readError");
              return null;
            }
          }
        } catch (listError) {
          debugPrint("FileService: 列出目录内容时出错: $listError，尝试使用Shizuku");

          // 列目录权限错误，尝试使用Shizuku
          if (listError.toString().contains("Permission denied") ||
              listError.toString().contains("errno = 13")) {
            // 启用Shizuku模式
            debugPrint("FileService: 启用Shizuku模式");
            _useShizuku = true;

            // 初始化Shizuku
            final initialized = await ShizukuFileService.initialize();
            if (!initialized) {
              debugPrint("FileService: Shizuku初始化失败");
              return null;
            }

            await ShizukuFileService.setForceShizukuMode(true);

            // 保存设置
            await prefs.setBool('use_shizuku', true);

            // 使用Shizuku列出目录
            try {
              final files = await ShizukuFileService.listDirectory(tempDir.path,
                  forceShizuku: true);
              if (files.isEmpty) {
                debugPrint("FileService: Shizuku模式下目录为空");
                return null;
              }

              final fileList = files
                  .where((file) => file.path.endsWith('.json') && file is File)
                  .toList();
              if (fileList.isEmpty) {
                debugPrint("FileService: Shizuku模式下目录中没有JSON文件");
                return null;
              }

              final filePath = fileList.first.path;
              debugPrint("FileService: Shizuku模式下尝试读取文件: $filePath");

              final content = await ShizukuFileService.readFile(filePath,
                  forceShizuku: true);
              final data = jsonDecode(content);
              studentName = data['data'][0]['student_name'];
              debugPrint("FileService: Shizuku模式下获取到学生姓名: $studentName");

              // 保存到 SharedPreferences
              await prefs.setString('student_name', studentName!);
              debugPrint("FileService: 学生姓名已保存到缓存");
            } catch (shizukuError) {
              debugPrint("FileService: 使用Shizuku列出目录也失败: $shizukuError");
              return null;
            }
          } else {
            // 其他错误
            debugPrint("FileService: 列出目录时发生非权限错误: $listError");
            return null;
          }
        }
      } catch (e) {
        debugPrint("FileService: 访问temp目录时发生错误: $e");

        // 尝试使用Shizuku作为最后的手段
        if (!_useShizuku) {
          debugPrint("FileService: 尝试使用Shizuku作为备选方案");

          // 初始化Shizuku
          final initialized = await ShizukuFileService.initialize();
          if (!initialized) {
            debugPrint("FileService: Shizuku初始化失败");
            return null;
          }

          // 启用Shizuku模式
          _useShizuku = true;
          await ShizukuFileService.setForceShizukuMode(true);

          // 保存设置
          await prefs.setBool('use_shizuku', true);

          // 使用Shizuku重新尝试整个过程
          return await getStudentName(); // 递归调用，这次将使用Shizuku
        }
      }

      return studentName;
    } catch (e) {
      debugPrint("FileService: 获取学生姓名过程中出错: $e");
      return null;
    }
  }

//读取答案数据
  static Future<String> getAnswersFromFolderGroup(
      List<FolderItem> folderGroup) async {
    // 检查平台类型
    final isWindowsPlatform = Platform.isWindows;

    if (folderGroup.length != 3) {
      debugPrint("FileService: 社区版本不支持此题型，文件夹数量: ${folderGroup.length}");
      return "社区版本仅支持深圳高中题型，当前题型不被支持。";
    }
    debugPrint("FileService: 检测到3个文件夹，使用深圳高中解析逻辑");
    // --- End of community version check ---

    // 如果是Windows平台且文件夹标签为windows，使用Windows特定的解析方法
    if (isWindowsPlatform &&
        folderGroup.isNotEmpty &&
        folderGroup[0].tag == 'windows') {
      return await _getWindowsAnswers(folderGroup);
    }

    // 移除云端模式支持

    try {
      debugPrint("FileService: 开始从文件夹组获取答案，文件夹数量: ${folderGroup.length}");

      // 提前检查组是否为空
      if (folderGroup.isEmpty) {
        debugPrint("FileService: 文件夹组为空，无法获取答案");
        return "未能获取到答案，文件夹组为空";
      }

      for (final folder in folderGroup) {
        debugPrint("FileService: 文件夹路径: ${folder.name}");
      }

      final storyBuilder = StringBuffer();
      final questionBuilder = StringBuffer();
      // bool anyProcessingFailed = false; // 移除重复定义

      // 首先尝试从缓存获取答案
      try {
        // 创建文件列表的副本以防修改
        final folderFiles = folderGroup.map((e) => File(e.name)).toList();
        debugPrint("FileService: 尝试从缓存获取答案，文件数: ${folderFiles.length}");

        final cachedAnswers = await SimpleStorage.getCachedAnswers(folderFiles);
        if (cachedAnswers != null && cachedAnswers.isNotEmpty) {
          debugPrint("FileService: 使用缓存的答案，长度: ${cachedAnswers.length}");
          return cachedAnswers; // 如果缓存存在，直接返回缓存的答案
        } else {
          debugPrint("FileService: 缓存不存在或为空");
        }
      } catch (cacheError) {
        debugPrint("FileService: 获取缓存答案时出错: $cacheError");
        // 缓存获取失败，继续尝试读取文件
      }

      debugPrint("FileService: 缓存中无答案，从文件读取");

      // 不再获取根目录路径，直接使用传入的完整文件夹路径
      int processedFolders = 0;
      // ignore: unused_local_variable
      bool anyProcessingFailed = false;

      // 仅在没有特定处理器时运行此通用循环
      if (folderGroup.length != 7) {
        for (final folder in folderGroup) {
          try {
            // 从完整路径中提取文件夹名
            final folderPath = folder.name; // 这是完整的文件夹路径
            final pathSeparator = isWindowsPlatform ? '\\' : '/';
            final folderName = folderPath.split(pathSeparator).last;
            debugPrint(
                "FileService: 处理文件夹 ${++processedFolders}/${folderGroup.length}: $folderName");

            // 验证这是一个目录，而不是文件
            bool isDir = false;
            String contentJsonPath =
                folderPath + pathSeparator + 'content.json';

            try {
              // 优先使用Shizuku方式，如果启用了Shizuku
              if (_useShizuku) {
                debugPrint("FileService: 使用Shizuku检查目录");
                isDir = await ShizukuFileService.exists(folderPath,
                        forceShizuku: true) &&
                    await ShizukuFileService.isDirectory(folderPath,
                        forceShizuku: true);

                if (!isDir) {
                  debugPrint(
                      "FileService: Shizuku方式 - 路径不是目录或不存在: $folderPath");
                  continue;
                }

                // 检查content.json是否存在
                final contentExists = await ShizukuFileService.exists(
                    contentJsonPath,
                    forceShizuku: true);
                if (!contentExists) {
                  debugPrint(
                      "FileService: Shizuku方式 - content.json不存在: $contentJsonPath");
                  continue;
                }

                // 读取content.json内容
                debugPrint(
                    "FileService: 使用Shizuku读取content.json: $contentJsonPath");
                final data = await ShizukuFileService.readFile(contentJsonPath,
                    forceShizuku: true);

                if (data.isEmpty) {
                  debugPrint("FileService: Shizuku方式 - content.json为空");
                  continue;
                }

                try {
                  final jsonData = jsonDecode(data);
                  debugPrint("FileService: Shizuku方式 - 成功读取并解析content.json");

                  // 根据结构类型解析数据
                  if (jsonData.containsKey('structure_type')) {
                    switch (jsonData['structure_type']) {
                      case 'collector.3q5a': // 深圳高中
                        debugPrint("FileService: 解析深圳高中题目");
                        questionBuilder
                            .writeln(parseQuestionData(jsonData, true));
                        break;
                      case 'collector.picture':
                        debugPrint("FileService: 解析短文复述");
                        storyBuilder.writeln(parseStoryData(jsonData));
                        break;
                      case 'collector.read': // 朗读题目 - 不处理
                        debugPrint("FileService: 跳过朗读题目类型");
                        // 不处理此类型
                        break;
                      default:
                        debugPrint(
                            'FileService: 未知的 structure_type: ${jsonData['structure_type']}');
                    }
                  } else {
                    debugPrint("FileService: JSON数据中没有structure_type字段");
                  }
                } catch (parseError) {
                  debugPrint("FileService: Shizuku方式 - 解析JSON时出错: $parseError");
                  continue;
                }
              } else {
                // 使用普通方式
                final directory = Directory(folderPath);
                isDir = await directory.exists();

                if (!isDir) {
                  debugPrint("FileService: 普通方式 - 目录不存在: $folderPath");
                  continue;
                }

                // 尝试读取content.json
                debugPrint("FileService: 尝试读取content.json: $contentJsonPath");

                final contentFile = File(contentJsonPath);
                final contentExists = await contentFile.exists();
                debugPrint("FileService: content.json存在: $contentExists");

                // 确保 content.json 文件存在
                if (contentExists) {
                  try {
                    final data = await contentFile.readAsString();
                    if (data.isEmpty) {
                      debugPrint("FileService: content.json为空");
                      continue;
                    }

                    final jsonData = jsonDecode(data);
                    debugPrint("FileService: 成功读取并解析content.json");

                    // 根据结构类型解析数据
                    if (jsonData.containsKey('structure_type')) {
                      switch (jsonData['structure_type']) {
                        case 'collector.3q5a': // 深圳高中
                          debugPrint("FileService: 解析深圳高中题目");
                          questionBuilder
                              .writeln(parseQuestionData(jsonData, true));
                          break;
                        case 'collector.picture':
                          debugPrint("FileService: 解析短文复述");
                          storyBuilder.writeln(parseStoryData(jsonData));
                          break;
                        case 'collector.read': // 朗读题目 - 不处理
                          debugPrint("FileService: 跳过朗读题目类型");
                          // 不处理此类型
                          break;
                        default:
                          debugPrint(
                              'FileService: 未知的 structure_type: ${jsonData['structure_type']}');
                      }
                    } else {
                      debugPrint("FileService: JSON数据中没有structure_type字段");
                    }
                  } catch (parseError) {
                    debugPrint("FileService: 解析JSON时出错: $parseError");
                    continue;
                  }
                } else {
                  debugPrint("FileService: content.json不存在，尝试解析其他文件结构");
                  anyProcessingFailed = true;
                }
              }
            } catch (e) {
              debugPrint("FileService: 访问目录出错: $e");
              anyProcessingFailed = true;
              continue;
            }
          } catch (e) {
            anyProcessingFailed = true;
            debugPrint("FileService: 处理文件夹时出错: $e");
          }
        }
      }

      // 构建最终答案字符串
      String finalAnswer = "";

      // 根据文件夹数量判断题型
      if (folderGroup.length == 7) {
        // 广东初中有7个文件夹
        debugPrint("FileService: 广东初中题型，按指定顺序排序显示答案");

        // 创建初中题型的StringBuffer
        final listeningChoiceBuilder = StringBuffer(); // 听选信息
        final answeringQuestionsBuilder = StringBuffer(); // 回答问题
        final askingQuestionsBuilder = StringBuffer(); // 提问
        // storyBuilder 用于短文复述

        // 从questionBuilder中提取各种题型并分类
        final allQuestions = questionBuilder.toString();
        final lines = allQuestions.split('\n');

        StringBuffer currentBuilder = StringBuffer();
        String currentType = "";

        for (final line in lines) {
          if (line.contains('【听选信息')) {
            if (currentBuilder.isNotEmpty && currentType.isNotEmpty) {
              if (currentType == "听选信息")
                listeningChoiceBuilder
                    .writeln(currentBuilder.toString().trim());
              else if (currentType == "回答问题")
                answeringQuestionsBuilder
                    .writeln(currentBuilder.toString().trim());
              else if (currentType == "提问")
                askingQuestionsBuilder
                    .writeln(currentBuilder.toString().trim());
            }
            currentBuilder = StringBuffer()..writeln(line);
            currentType = "听选信息";
          } else if (line.contains('【回答问题')) {
            if (currentBuilder.isNotEmpty && currentType.isNotEmpty) {
              if (currentType == "听选信息")
                listeningChoiceBuilder
                    .writeln(currentBuilder.toString().trim());
              else if (currentType == "回答问题")
                answeringQuestionsBuilder
                    .writeln(currentBuilder.toString().trim());
              else if (currentType == "提问")
                askingQuestionsBuilder
                    .writeln(currentBuilder.toString().trim());
            }
            currentBuilder = StringBuffer()..writeln(line);
            currentType = "回答问题";
          } else if (line.contains('【提问')) {
            if (currentBuilder.isNotEmpty && currentType.isNotEmpty) {
              if (currentType == "听选信息")
                listeningChoiceBuilder
                    .writeln(currentBuilder.toString().trim());
              else if (currentType == "回答问题")
                answeringQuestionsBuilder
                    .writeln(currentBuilder.toString().trim());
              else if (currentType == "提问")
                askingQuestionsBuilder
                    .writeln(currentBuilder.toString().trim());
            }
            currentBuilder = StringBuffer()..writeln(line);
            currentType = "提问";
          } else {
            if (currentBuilder.isNotEmpty && line.trim().isNotEmpty) {
              currentBuilder.writeln(line);
            }
          }
        }

        // 处理最后一个部分
        if (currentBuilder.isNotEmpty && currentType.isNotEmpty) {
          if (currentType == "听选信息")
            listeningChoiceBuilder.writeln(currentBuilder.toString().trim());
          else if (currentType == "回答问题")
            answeringQuestionsBuilder.writeln(currentBuilder.toString().trim());
          else if (currentType == "提问")
            askingQuestionsBuilder.writeln(currentBuilder.toString().trim());
        }
        debugPrint(
            "FileService: 广东初中分类后长度 - 听选: ${listeningChoiceBuilder.length}, 回答: ${answeringQuestionsBuilder.length}, 提问: ${askingQuestionsBuilder.length}, 转述: ${storyBuilder.length}");

        // 按指定顺序合并答案：听选信息 -> 回答问题 -> 短文复述 -> 提问
        if (listeningChoiceBuilder.isNotEmpty) {
          finalAnswer += listeningChoiceBuilder.toString();
        }
        if (answeringQuestionsBuilder.isNotEmpty) {
          finalAnswer += answeringQuestionsBuilder.toString();
        }
        if (storyBuilder.isNotEmpty) {
          finalAnswer += storyBuilder.toString();
        }
        if (askingQuestionsBuilder.isNotEmpty) {
          finalAnswer += askingQuestionsBuilder.toString();
        }
      } else {
        // 非初中题型或其他情况，保持原有逻辑
        // 添加题目解析
        if (questionBuilder.isNotEmpty) {
          debugPrint("FileService: 添加题目解析到最终答案");
          finalAnswer += questionBuilder.toString();
        }

        // 添加短文复述
        if (storyBuilder.isNotEmpty) {
          debugPrint("FileService: 添加短文复述到最终答案");
          finalAnswer += storyBuilder.toString();
        }
      }

      // 如果所有构建器都是空的，则返回错误消息
      if (finalAnswer.isEmpty) {
        return "未能获取到答案，请确保选择了正确的文件夹";
      }

      // 缓存结果（只缓存成功的结果）
      try {
        // 创建文件列表的副本以防修改
        final folderFiles =
            folderGroup.map((e) => File(e.name)).toList(); // 使用 folderGroup
        await SimpleStorage.cacheAnswers(folderFiles, finalAnswer);
        debugPrint("FileService: 答案已缓存");
      } catch (e) {
        debugPrint("FileService: 缓存答案时出错: $e");
        // 缓存失败不影响返回结果
      }

      return finalAnswer;
    } catch (e) {
      debugPrint("FileService: 获取答案时出错: $e");
      return "获取答案时出错: $e";
    }
  }

  // 移除云端答案功能

  static String parseQuestionData(
      Map<String, dynamic> data, bool isHighSchool) {
    final builder = StringBuffer();

    // 检查是否是北京初中题型（collector.choose类型）
    if (data['structure_type'] == 'collector.choose') {
      try {
        debugPrint("FileService: 检测到collector.choose类型，调用专用解析方法");
        return parseBeijingJuniorData(data);
      } catch (e) {
        debugPrint("FileService: parseBeijingJuniorData执行出错: $e");
        builder.writeln('【解析错误】\n');
        builder.writeln('尝试解析北京初中题型时出错: $e\n');
        builder.writeln('--------------------------------\n');

        // 尝试使用通用方法解析
        debugPrint("FileService: 尝试使用通用方法解析collector.choose类型");
      }
    }

    try {
      // 检查info字段是否存在
      if (!data.containsKey('info')) {
        // 对于collector.choose类型，直接返回特殊处理结果
        if (data['structure_type'] == 'collector.choose') {
          return parseBeijingJuniorData(data);
        }

        // 对于其他类型，尝试寻找关键字段
        debugPrint("FileService: 没有找到info字段，尝试直接解析数据");
        builder.writeln('【数据错误】\n');
        builder.writeln('未找到info字段，无法解析标准格式。\n');

        // 尝试直接检查items或questions字段
        if (data.containsKey('items') || data.containsKey('questions')) {
          builder.writeln('尝试使用替代方法解析:\n');
          final items = data['items'] ?? data['questions'] ?? [];

          if (items is List && items.isNotEmpty) {
            for (int i = 0; i < items.length; i++) {
              final item = items[i];
              final question = item['xt_nr'] ?? item['question'] ?? '';
              final answer = item['answer'] ?? item['da_an'] ?? '';

              if (question.isNotEmpty) {
                builder.writeln('${i + 1}. $question');
              }
              if (answer.isNotEmpty) {
                builder.writeln('答案: $answer\n');
              }
            }
          }
        } else {
          // 列出可用的顶级字段
          builder.writeln('可用字段:\n');
          data.keys.forEach((key) {
            builder.writeln('- $key\n');
          });
        }

        builder.writeln('--------------------------------\n');
        return builder.toString();
      }

      final info = data['info'];

      // 检查question字段是否存在
      if (!info.containsKey('question')) {
        debugPrint("FileService: info中没有找到question字段");
        builder.writeln('【数据错误】\n');
        builder.writeln('info字段中未找到question数组，无法解析标准格式。\n');

        // 尝试查找其他可能的字段
        if (info.containsKey('value') || info.containsKey('std')) {
          builder.writeln('可能是短文复述类型，尝试解析:\n');
          return parseStoryData(data);
        } else {
          // 列出info中的字段
          builder.writeln('info中的可用字段:\n');
          info.keys.forEach((key) {
            builder.writeln('- $key\n');
          });
        }

        builder.writeln('--------------------------------\n');
        return builder.toString();
      }

      if (!info.containsKey('question') ||
          !(info['question'] is List) ||
          (info['question'] as List).isEmpty) {
        debugPrint("FileService: info中的question字段为空或格式错误");
        builder.writeln('【数据错误】\n');
        builder.writeln('info.question数组为空或格式错误。\n');
        builder.writeln('--------------------------------\n');
        return builder.toString();
      }

      // 确认至少有一个问题
      final questions = info['question'];
      if (questions.isEmpty) {
        debugPrint("FileService: 题目列表为空");
        builder.writeln('【数据错误】\n');
        builder.writeln('题目列表为空。\n');
        builder.writeln('--------------------------------\n');
        return builder.toString();
      }

      // 检查题型内容进行分类，不再使用广东初中/高中前缀
      if (isHighSchool) {
        // 高中
        builder.writeln('【角色扮演】\n');
      } else {
        // 初中
        // 听选信息特征: ask包含<br>分隔的多个选项且askaudio不为空
        if (questions[0]['ask'].contains('<br>') &&
            questions[0]['askaudio'] != null &&
            questions[0]['askaudio'].isNotEmpty) {
          builder.writeln('【听选信息】\n');

          // 特殊处理听选信息的格式
          String processedAsk = parseQuestion(questions[0]['ask']);

          // 提取问题和选项
          List<String> parts = processedAsk.split('/');
          if (parts.length >= 3) {
            // 第一部分是问题
            String mainQuestion = parts[0].trim();
            builder.writeln('$mainQuestion\n');

            // 后面的部分是选项，每个换行并用括号括起来
            for (int i = 1; i < parts.length; i++) {
              if (parts[i].trim().isNotEmpty) {
                builder.writeln('(${parts[i].trim()})');
              }
            }
          } else {
            // 简单替换<br>为/
            builder.writeln(processedAsk.replaceAll('<br>', '/'));
          }
          builder.writeln('');
        }
        // 提问特征: askaudio为空字符串且ask包含中文
        else if (questions[0]['askaudio'] != null &&
            questions[0]['askaudio'].isEmpty &&
            _containsChinese(questions[0]['ask'])) {
          builder.writeln('【提问】\n${parseQuestion(questions[0]['ask'])}\n');
        }
        // 回答问题: askaudio有值
        else if (questions[0]['askaudio'] != null &&
            questions[0]['askaudio'].isNotEmpty) {
          builder.writeln('【回答问题】\n${parseQuestion(questions[0]['ask'])}\n');
        }
        // 其他情况，默认为回答问题
        else {
          builder.writeln('【回答问题】\n${parseQuestion(questions[0]['ask'])}\n');
        }
      }

      for (int j = 0; j < questions.length; j++) {
        final question = questions[j];
        final stdAnswers = question['std'];
        final ask = question['ask'];
        // 检查askaudio字段，用于区分题型
        final askAudio =
            question.containsKey('askaudio') ? question['askaudio'] : "";

        if (isHighSchool) {
          // 高中，只显示题号，不显示"广东高中"前缀
          if (j > 0) {
            builder.writeln('【角色扮演 ${j + 1}】\n');
          }
        } else {
          // 初中
          if (j > 0) {
            // 听选信息特征: ask包含<br>分隔的多个选项且askaudio不为空
            if (ask.contains('<br>') &&
                askAudio != null &&
                askAudio.isNotEmpty) {
              builder.writeln('【听选信息 ${j + 1}】\n');

              // 特殊处理听选信息的格式
              String processedAsk = parseQuestion(ask);

              // 提取问题和选项
              List<String> parts = processedAsk.split('/');
              if (parts.length >= 3) {
                // 第一部分是问题
                String mainQuestion = parts[0].trim();
                builder.writeln('$mainQuestion\n');

                // 后面的部分是选项，每个换行并用括号括起来
                for (int i = 1; i < parts.length; i++) {
                  if (parts[i].trim().isNotEmpty) {
                    builder.writeln('(${parts[i].trim()})');
                  }
                }
              } else {
                // 简单替换<br>为/
                builder.writeln(processedAsk.replaceAll('<br>', '/'));
              }
              builder.writeln('');
            }
            // 提问特征: askaudio为空字符串且ask包含中文
            else if (askAudio != null &&
                askAudio.isEmpty &&
                _containsChinese(ask)) {
              builder.writeln('【提问 ${j + 1}】\n${parseQuestion(ask)}\n');
            }
            // 回答问题: askaudio有值
            else if (askAudio != null && askAudio.isNotEmpty) {
              builder.writeln('【回答问题 ${j + 1}】\n${parseQuestion(ask)}\n');
            }
            // 其他情况，默认为回答问题
            else {
              builder.writeln('【回答问题 ${j + 1}】\n${parseQuestion(ask)}\n');
            }
          }
        }

        for (int k = 0; k < stdAnswers.length; k++) {
          final answer = stdAnswers[k];
          final answerText = answer['value'];
          final plainText = removeHtmlTags(answerText);
          builder.writeln('${k + 1}. $plainText\n');
        }
        builder.writeln('--------------------------------\n');
      }
    } catch (e) {
      // 处理解析过程中的异常
      debugPrint("FileService: parseQuestionData执行出错: $e");
      builder.writeln('【解析错误】\n');
      builder.writeln('解析数据时出错: $e\n');

      // 尝试输出数据类型信息
      builder.writeln('数据类型: ${data['structure_type'] ?? "未知"}\n');

      // 列出顶级字段
      builder.writeln('可用字段:\n');
      try {
        data.keys.forEach((key) {
          builder.writeln('- $key\n');
        });
      } catch (e2) {
        builder.writeln('无法列出字段: $e2\n');
      }

      builder.writeln('--------------------------------\n');
    }

    return builder.toString();
  }

  // 解析北京初中题型数据
  static String parseBeijingJuniorData(Map<String, dynamic> data) {
    final builder = StringBuffer();

    try {
      debugPrint("FileService: 开始解析北京初中数据");

      // 创建不同题型的StringBuffer
      final Map<String, StringBuffer> typeBuilders = {
        '听后选择': StringBuffer(),
        '听后回答': StringBuffer(),
        '听后转述': StringBuffer(),
      };

      // 跟踪每种题型是否有内容
      final Map<String, bool> hasContent = {
        '听后选择': false,
        '听后回答': false,
        '听后转述': false,
      };

      final infoData = data['info'];

      // 处理听后选择题 (xt字段)
      if (infoData != null &&
          infoData.containsKey('xt') &&
          infoData['xt'] is List) {
        final xtList = infoData['xt'] as List;

        if (xtList.isNotEmpty) {
          final sb = typeBuilders['听后选择']!;
          sb.writeln('【听后选择】\n');

          for (int i = 0; i < xtList.length; i++) {
            if (xtList[i] is Map) {
              final xtItem = xtList[i] as Map;

              // 提取题目
              String question = xtItem['xt_nr']?.toString() ?? '';
              question = parseQuestion(question);

              // 提取答案
              String answer =
                  xtItem['answer']?.toString() ?? ''; // 使用 'answer' 而不是 'xt_da'

              // 提取选项
              List<String> options = [];
              if (xtItem.containsKey('xxlist') && xtItem['xxlist'] is List) {
                final xxlist = xtItem['xxlist'] as List;

                for (final xxItem in xxlist) {
                  if (xxItem is Map) {
                    final optionLabel = xxItem['xx_mc']?.toString() ?? '';
                    final optionText = xxItem['xx_nr']?.toString() ?? '';
                    options.add('$optionLabel$optionText');
                  }
                }
              }

              // 输出题目和选项
              if (question.isNotEmpty) {
                sb.writeln('${i + 1}. $question');

                // 添加选项
                for (final option in options) {
                  sb.writeln('   $option');
                }

                // 添加答案
                if (answer.isNotEmpty) {
                  sb.writeln('正确答案: $answer\n');
                }

                hasContent['听后选择'] = true;
              }
            }
          }
        }
      }

      // 处理听后回答题 (question字段)
      if (infoData != null &&
          infoData.containsKey('question') &&
          infoData['question'] is List) {
        final questions = infoData['question'] as List;
        if (questions.isNotEmpty) {
          final sb = typeBuilders['听后回答']!;
          sb.writeln('【听后回答】\n');

          for (int i = 0; i < questions.length; i++) {
            if (questions[i] is Map) {
              final question = questions[i] as Map;

              // 提取问题
              String questionText = question['ask']?.toString() ?? '';
              questionText =
                  questionText.replaceAll(RegExp(r'ets_th[12]\s*'), '').trim();

              // 提取答案
              List<String> answers = [];
              if (question.containsKey('std') && question['std'] is List) {
                final stdList = question['std'] as List;

                // 最多显示3个答案
                int count = 0;
                for (final stdItem in stdList) {
                  if (stdItem is Map && stdItem.containsKey('value')) {
                    answers.add(stdItem['value'].toString());
                    count++;
                    if (count >= 3) break;
                  }
                }
              }

              // 输出题目和答案
              if (questionText.isNotEmpty) {
                sb.writeln('${i + 1}. $questionText');

                if (answers.isNotEmpty) {
                  sb.writeln('参考答案:');
                  for (int j = 0; j < answers.length; j++) {
                    sb.writeln('  ${j + 1}) ${answers[j]}');
                  }
                  sb.writeln();
                }

                hasContent['听后回答'] = true;
              }
            }
          }
        }
      }

      // 处理听后转述题 (直接从info提取，必须有std字段)
      if (infoData != null &&
          infoData.containsKey('std') &&
          infoData['std'] is List) {
        final sb = typeBuilders['听后转述']!;
        sb.writeln('【听后转述】\n');

        // 添加主题（如果有）
        if (infoData.containsKey('topic') && infoData['topic'] is String) {
          String topic = infoData['topic'].toString();
          sb.writeln('主题: $topic\n');
          hasContent['听后转述'] = true;
        }

        // 添加参考转述
        final stdList = infoData['std'] as List;
        if (stdList.isNotEmpty) {
          sb.writeln('参考转述:');

          // 最多显示2个参考转述
          int count = 0;
          for (final stdItem in stdList) {
            if (stdItem is Map && stdItem.containsKey('value')) {
              sb.writeln('${count + 1}. ${stdItem['value']}\n');
              count++;
              if (count >= 2) break; // 最多2个
            }
          }

          hasContent['听后转述'] = true;
        }

        // 添加关键点
        if (infoData.containsKey('keypoint') &&
            infoData['keypoint'] is String) {
          String keypoint = infoData['keypoint'].toString();
          keypoint = removeHtmlTags(keypoint);
          sb.writeln('关键点: \n$keypoint\n');
          hasContent['听后转述'] = true;
        }
      }

      // 根据structure_type补充识别类型
      if (!hasContent['听后选择']! &&
          !hasContent['听后回答']! &&
          !hasContent['听后转述']!) {
        final structureType = data['structure_type']?.toString() ?? '';
        debugPrint("FileService: 无法从内容识别题型，尝试使用structure_type: $structureType");

        if (structureType == 'collector.choose') {
          typeBuilders['听后选择']!.writeln('【听后选择】\n');
          typeBuilders['听后选择']!.writeln('未能识别具体题目内容，但文件类型为选择题。\n');
          hasContent['听后选择'] = true;
        } else if (structureType == 'collector.role') {
          typeBuilders['听后回答']!.writeln('【听后回答】\n');
          typeBuilders['听后回答']!.writeln('未能识别具体题目内容，但文件类型为回答题。\n');
          hasContent['听后回答'] = true;
        } else if (structureType == 'collector.picture') {
          typeBuilders['听后转述']!.writeln('【听后转述】\n');
          typeBuilders['听后转述']!.writeln('未能识别具体题目内容，但文件类型为转述题。\n');
          hasContent['听后转述'] = true;
        } else {
          // 默认作为选择题处理
          typeBuilders['听后选择']!.writeln('【听后选择】\n');
          typeBuilders['听后选择']!.writeln('未能识别题目类型和内容。\n');
          hasContent['听后选择'] = true;
        }
      }

      // 强制识别所有类型 - 对于北京初中collector.choose类型，添加所有三种类型
      if (data['structure_type'] == 'collector.choose' && infoData != null) {
        // 如果是collector.choose类型，需要确保即使结构中没有相应字段，也要尝试提取所有三种题型
        debugPrint("FileService: 强制解析collector.choose类型的所有题型");

        // 如果st_nr字段包含对话内容，可能包含听后回答和转述的内容
        if (infoData.containsKey('st_nr') && !hasContent['听后回答']!) {
          final dialogueContent = infoData['st_nr']?.toString() ?? '';
          if (dialogueContent.isNotEmpty && dialogueContent.length > 50) {
            final sb = typeBuilders['听后回答']!;
            sb.writeln('【听后回答】\n');
            // 不显示对话内容
            if (infoData.containsKey('wt_nr')) {
              sb.writeln('问题: ${infoData['wt_nr']}\n');
            }
            hasContent['听后回答'] = true;
          }
        }

        // 如果包含etsContent字段，可能包含转述内容
        if (infoData.containsKey('etsContent') && !hasContent['听后转述']!) {
          final content = infoData['etsContent']?.toString() ?? '';
          if (content.isNotEmpty && content.length > 50) {
            final sb = typeBuilders['听后转述']!;
            sb.writeln('【听后转述】\n');
            // 不显示转述内容
            hasContent['听后转述'] = true;
          }
        }
      }

      // 汇总诊断结果
      debugPrint(
          "FileService: 北京初中题型识别结果 - 听后选择: ${hasContent['听后选择']}, 听后回答: ${hasContent['听后回答']}, 听后转述: ${hasContent['听后转述']}");

      // 合并所有有内容的StringBuffer，确保包含听后转述
      for (final type in ['听后选择', '听后回答', '听后转述']) {
        if (hasContent[type] == true) {
          builder.writeln(typeBuilders[type]!.toString());
        }
      }

      // 如果结果为空，给出提示
      if (builder.toString().trim().isEmpty) {
        builder.writeln('【听后选择】\n');
        builder.writeln('无法识别题目内容，请联系开发者。');
        debugPrint("FileService: 警告 - 北京初中解析结果为空");
      }
    } catch (e) {
      debugPrint("FileService: 解析北京初中数据出错: $e");
      builder.writeln('【听后选择】\n');
      builder.writeln('解析数据时出错: $e\n');
    }

    final result = builder.toString();
    debugPrint("FileService: 完成解析北京初中数据，结果长度: ${result.length}");

    // 再次检查是否包含多种题型
    final containsChoice = result.contains('【听后选择】');
    final containsAnswer = result.contains('【听后回答】');
    final containsRetell = result.contains('【听后转述】');
    debugPrint(
        "FileService: 最终结果包含题型 - 听后选择: $containsChoice, 听后回答: $containsAnswer, 听后转述: $containsRetell");

    return result;
  }

  // 判断字符串是否包含中文
  static bool _containsChinese(String text) {
    // 中文字符的Unicode范围大致为：\u4e00-\u9fff
    final chineseRegex = RegExp(r'[\u4e00-\u9fff]');
    return chineseRegex.hasMatch(text);
  }

// 解析问题，去除HTML标签和多余的换行符
  static String parseQuestion(String questionText) {
    return questionText
        .replaceAll(RegExp(r'<.*?>'), '') // 删除HTML标签
        .replaceAll('<br>', '/') // 特殊处理<br>标签为/
        .replaceAll(RegExp(r'</?br>'), '/') // 确保各种br标签都被处理
        .replaceAll(RegExp(r'ets_th[1234]'), '')
        .replaceAll('\n', '') // 去除所有换行符
        .trim(); // 去除首尾空格
  }

// 解析短文数据
  static String parseStoryData(Map<String, dynamic> data) {
    final builder = StringBuffer();
    final info = data['info'];

    if (info != null && info.containsKey('std')) {
      builder.writeln('【短文复述】\n');
      final stdArray = info['std'];

      for (int i = 0; i < stdArray.length; i++) {
        final stdObject = stdArray[i];
        if (stdObject.containsKey('value')) {
          final answerText = stdObject['value'];
          final plainAnswerText = removeHtmlTags(answerText);
          builder.writeln('${i + 1}. $plainAnswerText\n');
        }
      }
    }

    return builder.toString();
  }

//获取hitokoto
  static Future<String> fetchHitokoto() async {
    try {
      final response = await http.get(Uri.parse('https://v1.hitokoto.cn/'));
      if (response.statusCode == 200) {
        final jsonObject = jsonDecode(response.body);
        final hitokoto = jsonObject['hitokoto'];
        final from = jsonObject['from'];
        final fromWho = jsonObject['from_who'] ?? '';

        return '$hitokoto\n  -- ${fromWho.isNotEmpty ? '$fromWho 「$from」' : '「$from」'}';
      } else {
        return '用代码表达言语的魅力，用代码书写山河的壮丽。\n「一言获取失败」';
      }
    } catch (e) {
      print('获取一言失败: $e');
      return '用代码表达言语的魅力，用代码书写山河的壮丽。\n「一言获取失败」';
    }
  }

  // 移除云端资源文件夹功能

  // Windows平台下获取ETS目录中的资源文件夹
  static Future<List<FolderItem>> _getWindowsResourceFolders(
      {bool deepScan = false}) async {
    debugPrint("FileService: Windows平台获取ETS资源文件夹");

    try {
      // 获取保存的目录路径
      String? rootDirectoryPath = await FileService().getRootDirectoryPath();
      debugPrint("FileService: Windows ETS根目录路径: $rootDirectoryPath");

      if (rootDirectoryPath == null) {
        debugPrint("FileService: ETS根目录路径为空");
        return [];
      }

      // 确保路径使用正确的分隔符
      rootDirectoryPath = rootDirectoryPath.replaceAll('/', '\\');

      // 检查目录是否存在
      final directory = Directory(rootDirectoryPath);
      final exists = await directory.exists();

      if (!exists) {
        debugPrint("FileService: ETS根目录不存在: $rootDirectoryPath");
        return [];
      }

      // 列出所有子目录
      final List<FileSystemEntity> entities = await directory.list().toList();
      debugPrint("FileService: ETS根目录下的实体数量: ${entities.length}");

      // 处理每个数字文件夹内的content子文件夹
      final List<FolderItem> result = [];

      for (var entity in entities) {
        if (entity is Directory) {
          final folderName = path.basename(entity.path);

          // 检查是否为数字文件夹
          if (RegExp(r'^\d+$').hasMatch(folderName)) {
            debugPrint("FileService: 找到ETS题目文件夹: $folderName，扫描内部content文件夹");

            // 查找该文件夹内的content_开头的子文件夹
            final contentFolders =
                await _findContentFoldersInDirectory(entity.path);

            if (contentFolders.isNotEmpty) {
              debugPrint(
                  "FileService: 在文件夹 $folderName 下找到 ${contentFolders.length} 个content文件夹");

              // 记录修改时间用于按时间分组
              DateTime folderModifiedTime;
              try {
                final stat = entity.statSync();
                folderModifiedTime = stat.modified;
              } catch (e) {
                folderModifiedTime = DateTime.now();
              }

              // 添加每个content文件夹作为单独项
              for (var contentFolder in contentFolders) {
                final contentFolderPath = contentFolder.path;
                final contentFolderName = path.basename(contentFolderPath);

                result.add(FolderItem(
                  name: contentFolderPath,
                  lastModified: folderModifiedTime, // 使用相同时间以便分到同一组
                  tag: 'windows',
                  path: contentFolderPath,
                  numericId: folderName, // 保存上一级的纯数字ID
                ));
                debugPrint(
                    "FileService: 添加content文件夹: $contentFolderName, 路径: $contentFolderPath");
              }
            } else {
              debugPrint("FileService: 在文件夹 $folderName 下没有找到content文件夹");
            }
          }
        }
      }

      debugPrint("FileService: Windows平台找到${result.length}个content文件夹");
      return result;
    } catch (e) {
      debugPrint("FileService: Windows平台获取资源文件夹时出错: $e");
      return [];
    }
  }

  // 查找目录中的content_开头的文件夹
  static Future<List<Directory>> _findContentFoldersInDirectory(
      String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        debugPrint("FileService: 目录不存在: $directoryPath");
        return [];
      }

      final entities = await directory.list().toList();
      final List<Directory> contentFolders = [];

      for (var entity in entities) {
        if (entity is Directory) {
          final folderName = path.basename(entity.path).toLowerCase();
          if (folderName.startsWith('content_') || folderName == 'content') {
            contentFolders.add(entity);
            debugPrint("FileService: 找到content文件夹: ${entity.path}");
          }
        }
      }

      return contentFolders;
    } catch (e) {
      debugPrint("FileService: 查找content文件夹时出错: $e");
      return [];
    }
  }

  // Windows平台下从ETS题目文件夹获取答案
  static Future<String> _getWindowsAnswers(List<FolderItem> folders) async {
    debugPrint('FileService: _getWindowsAnswers开始执行，共${folders.length}个文件夹');

    if (folders.isEmpty) {
      debugPrint('FileService: _getWindowsAnswers - 文件夹列表为空');
      return '无法获取答案：未找到有效的题目文件夹';
    }

    try {
      // 创建结果集合
      final storyBuilder = StringBuffer();
      final questionBuilder = StringBuffer();

      int validAnswersCount = 0;

      // 直接处理每个content文件夹
      for (final folderItem in folders) {
        final contentFolderPath = folderItem.name;
        final contentFolderName = path.basename(contentFolderPath);

        debugPrint(
            'FileService: _getWindowsAnswers - 正在处理content文件夹: $contentFolderName, 路径: $contentFolderPath');

        // 验证路径是否存在
        final contentFolder = Directory(contentFolderPath);
        if (!await contentFolder.exists()) {
          debugPrint(
              'FileService: _getWindowsAnswers - 文件夹不存在: $contentFolderPath');
          continue;
        }

        // 查找content.json文件
        final contentJsonPath = path.join(contentFolderPath, 'content.json');
        final contentJsonFile = File(contentJsonPath);

        if (await contentJsonFile.exists()) {
          debugPrint(
              'FileService: _getWindowsAnswers - 找到content.json: $contentJsonPath');

          try {
            // 读取和解析content.json
            final jsonContent = await contentJsonFile.readAsString();
            debugPrint(
                'FileService: _getWindowsAnswers - 成功读取content.json, 内容长度: ${jsonContent.length}');

            final jsonData = jsonDecode(jsonContent);

            // 根据结构类型解析数据
            if (jsonData.containsKey('structure_type')) {
              switch (jsonData['structure_type']) {
                case 'collector.3q5a': // 深圳高中
                  debugPrint("FileService: 解析深圳高中题目");
                  questionBuilder.writeln(parseQuestionData(jsonData, true));
                  validAnswersCount++;
                  break;
                case 'collector.picture':
                  debugPrint("FileService: 解析短文复述");
                  storyBuilder.writeln(parseStoryData(jsonData));
                  validAnswersCount++;
                  break;
                case 'collector.read': // 朗读题目 - 不处理
                  debugPrint("FileService: 跳过朗读题目类型");
                  // 不处理此类型
                  break;
                default:
                  debugPrint(
                      'FileService: 未知的 structure_type: ${jsonData['structure_type']}');
                  // 尝试直接显示JSON内容
                  questionBuilder.writeln('未知类型题目内容:');
                  questionBuilder.writeln(jsonContent);
                  validAnswersCount++;
              }
            } else {
              // 如果没有structure_type字段，直接显示JSON内容
              debugPrint("FileService: JSON中没有structure_type字段，直接显示内容");
              questionBuilder.writeln('原始JSON内容:');
              questionBuilder.writeln(jsonContent);
              validAnswersCount++;
            }
          } catch (e) {
            debugPrint(
                'FileService: _getWindowsAnswers - 解析content.json失败: $e');
          }
        } else {
          debugPrint(
              'FileService: _getWindowsAnswers - 未找到content.json，查找其他JSON文件');

          // 如果没有找到content.json，尝试列出此目录下的所有JSON文件
          try {
            final files = await contentFolder.list().toList();
            final jsonFiles = files
                .whereType<File>()
                .where((f) => path.extension(f.path).toLowerCase() == '.json')
                .toList();

            if (jsonFiles.isNotEmpty) {
              debugPrint(
                  'FileService: _getWindowsAnswers - 找到其他JSON文件: ${jsonFiles.length}个');

              // 尝试读取第一个JSON文件
              final jsonFile = jsonFiles.first;
              final jsonContent = await jsonFile.readAsString();

              try {
                // ignore: unused_local_variable
                final jsonData = jsonDecode(jsonContent);
                debugPrint('FileService: _getWindowsAnswers - 成功解析其他JSON文件');

                // 直接显示JSON内容
                questionBuilder
                    .writeln('文件 ${path.basename(jsonFile.path)} 内容:');
                questionBuilder.writeln(jsonContent);
                validAnswersCount++;
              } catch (e) {
                debugPrint(
                    'FileService: _getWindowsAnswers - 解析其他JSON文件失败: $e');
              }
            } else {
              debugPrint('FileService: _getWindowsAnswers - 未找到任何JSON文件');
            }
          } catch (e) {
            debugPrint('FileService: _getWindowsAnswers - 列出目录内容失败: $e');
          }
        }
      }

      debugPrint(
          'FileService: _getWindowsAnswers - 处理完成，有效答案数: $validAnswersCount');

      // 如果没有找到任何答案，返回提示信息
      if (validAnswersCount == 0) {
        return '未找到答案内容。请确保选择了正确的文件夹：\n1. 文件夹中应包含content.json文件\n如问题仍然存在，请联系开发者。';
      }

      // 构建最终答案字符串
      String finalAnswer = "";

      // 只支持深圳高中
      if (folders.length == 3) {
        // 深圳高中有3个文件夹，直接处理题目和短文复述
        // 添加题目解析
        if (questionBuilder.isNotEmpty) {
          debugPrint("FileService: 添加深圳高中题目解析到最终答案");
          finalAnswer += questionBuilder.toString();
        }

        // 添加短文复述
        if (storyBuilder.isNotEmpty) {
          debugPrint("FileService: 添加深圳高中短文复述到最终答案");
          finalAnswer += storyBuilder.toString();
        }
      } else {
        finalAnswer = "社区版本仅支持深圳高中题型，当前题型不被支持。";
      }

      // 如果所有构建器都是空的，则返回错误消息
      if (finalAnswer.isEmpty) {
        return "未能获取到答案，请确保选择了正确的文件夹";
      }

      // 缓存结果（只缓存成功的结果）
      try {
        // 创建文件列表的副本以防修改
        final folderFiles =
            folders.map((e) => File(e.name)).toList(); // 使用 folders
        await SimpleStorage.cacheAnswers(folderFiles, finalAnswer);
        debugPrint("FileService: 答案已缓存");
      } catch (e) {
        debugPrint("FileService: 缓存答案时出错: $e");
        // 缓存失败不影响返回结果
      }

      return finalAnswer;
    } catch (e) {
      debugPrint("FileService: 获取答案时出错: $e");
      return "获取答案时出错: $e";
    }
  }
}
