import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shizuku_api/shizuku_api.dart';

// 自定义文件系统实体类，包含修改时间和大小信息
class CustomFileSystemEntity implements FileSystemEntity {
  @override
  final String path;
  final DateTime modified;
  final int size;
  final bool isDirectory;

  CustomFileSystemEntity(
      {required this.path,
      required this.modified,
      required this.size,
      required this.isDirectory});

  // 转换为目录对象
  Directory asDirectory() => Directory(path);

  // 转换为文件对象
  File asFile() => File(path);

  @override
  String toString() =>
      "${isDirectory ? 'Directory' : 'File'}: $path (修改时间: $modified, 大小: $size字节)";

  // 实现必要的方法
  @override
  Future<bool> exists() =>
      isDirectory ? Directory(path).exists() : File(path).exists();

  @override
  bool existsSync() =>
      isDirectory ? Directory(path).existsSync() : File(path).existsSync();

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) => isDirectory
      ? Directory(path).delete(recursive: recursive)
      : File(path).delete();

  @override
  void deleteSync({bool recursive = false}) => isDirectory
      ? Directory(path).deleteSync(recursive: recursive)
      : File(path).deleteSync();

  @override
  Future<String> resolveSymbolicLinks() => isDirectory
      ? Directory(path).resolveSymbolicLinks()
      : File(path).resolveSymbolicLinks();

  @override
  String resolveSymbolicLinksSync() => isDirectory
      ? Directory(path).resolveSymbolicLinksSync()
      : File(path).resolveSymbolicLinksSync();

  @override
  Future<FileStat> stat() =>
      isDirectory ? Directory(path).stat() : File(path).stat();

  @override
  FileStat statSync() =>
      isDirectory ? Directory(path).statSync() : File(path).statSync();

  @override
  Uri get uri => isDirectory ? Directory(path).uri : File(path).uri;

  @override
  Stream<FileSystemEvent> watch({
    int events = FileSystemEvent.all,
    bool recursive = false,
  }) =>
      isDirectory
          ? Directory(path).watch(events: events, recursive: recursive)
          : File(path).watch(events: events, recursive: recursive);

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is CustomFileSystemEntity) {
      return path == other.path && isDirectory == other.isDirectory;
    }
    return false;
  }

  // 新增必需的方法
  @override
  Future<FileSystemEntity> rename(String newPath) => isDirectory
      ? Directory(path).rename(newPath)
      : File(path).rename(newPath);

  @override
  FileSystemEntity renameSync(String newPath) => isDirectory
      ? Directory(path).renameSync(newPath)
      : File(path).renameSync(newPath);

  @override
  FileSystemEntity get absolute =>
      isDirectory ? Directory(path).absolute : File(path).absolute;

  @override
  bool get isAbsolute => path.startsWith('/');

  @override
  Directory get parent => Directory(path).parent;
}

class ShizukuFileService {
  static bool _isInitialized = false;
  static bool _isShizukuAvailable = false;
  static dynamic _shizukuApi;

  // 判断当前是否为Android平台
  static bool get _isAndroidPlatform => Platform.isAndroid;

  // 全局强制使用Shizuku模式的开关
  static bool _forceShizukuMode = false;
  static const String _shizukuModeKey = 'force_shizuku_mode';

  // 获取当前是否强制使用Shizuku模式
  static bool get isForceShizukuMode => _forceShizukuMode && _isAndroidPlatform;

  // Shizuku错误类型
  static const String ERROR_SHIZUKU_NOT_INSTALLED = "SHIZUKU_NOT_INSTALLED";
  static const String ERROR_SHIZUKU_NOT_RUNNING = "SHIZUKU_NOT_RUNNING";
  static const String ERROR_SHIZUKU_PERMISSION_DENIED =
      "SHIZUKU_PERMISSION_DENIED";

  // 获取用户友好的错误提示
  static String getErrorMessage(String errorType) {
    switch (errorType) {
      case ERROR_SHIZUKU_NOT_INSTALLED:
        return "需要安装Shizuku应用才能访问此路径。\n"
            "1. 从Google Play或官方网站安装Shizuku\n"
            "2. 按照Shizuku的说明进行设置\n"
            "3. 重新尝试访问";
      case ERROR_SHIZUKU_NOT_RUNNING:
        return "Shizuku服务未运行。\n"
            "1. 打开Shizuku应用\n"
            "2. 根据设备情况选择以下方式之一启动服务：\n"
            "   - 无Root设备：使用无线调试功能\n"
            "   - Root设备：直接启动服务\n"
            "   - Android 11以下：通过电脑ADB启动";
      case ERROR_SHIZUKU_PERMISSION_DENIED:
        return "应用没有Shizuku权限。\n"
            "1. 打开Shizuku应用\n"
            "2. 在应用列表中找到本应用\n"
            "3. 授予权限后重试";
      default:
        return "访问失败，请尝试使用Shizuku模式。";
    }
  }

  // 从持久化存储中加载Shizuku模式设置
  static Future<void> loadShizukuModeSetting() async {
    // 非Android平台跳过加载
    if (!_isAndroidPlatform) {
      _forceShizukuMode = false;
      return;
    }

    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final savedMode = sharedPreferences.getBool(_shizukuModeKey) ?? false;
      _forceShizukuMode = savedMode;
      debugPrint("ShizukuFileService: 从存储加载Shizuku模式: $_forceShizukuMode");
    } catch (e) {
      debugPrint("ShizukuFileService: 加载Shizuku模式设置失败: $e");
    }
  }

  // 保存Shizuku模式设置到持久化存储
  static Future<void> _saveShizukuModeSetting(bool mode) async {
    // 非Android平台跳过保存
    if (!_isAndroidPlatform) return;

    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setBool(_shizukuModeKey, mode);
      debugPrint("ShizukuFileService: 保存Shizuku模式设置: $mode");
    } catch (e) {
      debugPrint("ShizukuFileService: 保存Shizuku模式设置失败: $e");
    }
  }

  // 设置是否强制使用Shizuku模式
  static Future<bool> setForceShizukuMode(bool force) async {
    // 非Android平台不允许设置
    if (!_isAndroidPlatform) {
      debugPrint("ShizukuFileService: 非Android平台，无法设置Shizuku模式");
      return false;
    }

    if (force && !await isAvailable()) {
      debugPrint("ShizukuFileService: 无法启用强制Shizuku模式，因为Shizuku服务不可用");
      return false;
    }
    _forceShizukuMode = force;
    // 保存设置到持久化存储
    await _saveShizukuModeSetting(force);
    debugPrint("ShizukuFileService: ${force ? '启用' : '禁用'}强制Shizuku模式");
    return true;
  }

  // 初始化Shizuku服务
  static Future<bool> initialize() async {
    // 非Android平台直接返回false
    if (!_isAndroidPlatform) {
      _isInitialized = true;
      _isShizukuAvailable = false;
      return false;
    }

    // 首先加载保存的Shizuku模式设置
    await loadShizukuModeSetting();

    if (_isInitialized) return _isShizukuAvailable;

    try {
      debugPrint("ShizukuFileService: 开始初始化Shizuku服务");

      // 安全地创建Shizuku实例
      try {
        // 这个实例化操作在非Android平台上会抛出错误
        _shizukuApi = ShizukuApi();
      } catch (e) {
        debugPrint("ShizukuFileService: 创建ShizukuApi实例失败: $e");
        _isInitialized = true;
        _isShizukuAvailable = false;
        return false;
      }

      // 检查Shizuku是否运行
      final isRunning = await _safeCall(_shizukuApi?.pingBinder, false);
      debugPrint("ShizukuFileService: Shizuku运行状态: $isRunning");

      if (!isRunning) {
        debugPrint("ShizukuFileService: Shizuku未运行,请先启动Shizuku服务");
        _isInitialized = true;
        _isShizukuAvailable = false;
        throw Exception(getErrorMessage(ERROR_SHIZUKU_NOT_RUNNING));
      }

      // 检查权限状态
      final hasPermission =
          await _safeCall(_shizukuApi?.checkPermission, false);
      debugPrint("ShizukuFileService: 当前权限状态: $hasPermission");

      if (!hasPermission) {
        debugPrint("ShizukuFileService: 没有权限,开始自动请求");
        // 请求权限
        final permissionResult =
            await _safeCall(_shizukuApi?.requestPermission, false);
        debugPrint("ShizukuFileService: 权限请求结果: $permissionResult");

        if (!permissionResult) {
          debugPrint("ShizukuFileService: 权限请求被拒绝");
          _isInitialized = true;
          _isShizukuAvailable = false;
          throw Exception(getErrorMessage(ERROR_SHIZUKU_PERMISSION_DENIED));
        }
      }

      // 初始化成功
      _isInitialized = true;
      _isShizukuAvailable = true;
      debugPrint("ShizukuFileService: Shizuku服务初始化成功,权限已获取");
      return true;
    } catch (e) {
      debugPrint("ShizukuFileService: 初始化Shizuku时出错: $e");
      _isInitialized = true;
      _isShizukuAvailable = false;

      if (e is Exception) {
        rethrow;
      }
      throw Exception(getErrorMessage(ERROR_SHIZUKU_NOT_INSTALLED));
    }
  }

  // 安全调用方法，捕获所有可能的异常
  static Future<T> _safeCall<T>(Function? method, T defaultValue) async {
    if (method == null) return defaultValue;
    try {
      return await method() ?? defaultValue;
    } catch (e) {
      debugPrint("ShizukuFileService: 安全调用异常: $e");
      return defaultValue;
    }
  }

  // 检查Shizuku是否可用
  static Future<bool> isAvailable() async {
    // 非Android平台直接返回false
    if (!_isAndroidPlatform) {
      return false;
    }

    try {
      if (!_isInitialized) {
        return await initialize();
      }
      // 即使已初始化,也要再次检查运行状态和权限
      if (_isShizukuAvailable && _shizukuApi != null) {
        final isRunning = await _safeCall(_shizukuApi?.pingBinder, false);
        final hasPermission = isRunning
            ? (await _safeCall(_shizukuApi?.checkPermission, false))
            : false;
        return isRunning && hasPermission;
      }
      return false;
    } catch (e) {
      debugPrint("ShizukuFileService: 检查Shizuku可用性时出错: $e");
      return false;
    }
  }

  // 检查路径是否需要Shizuku访问
  static bool isPathNeedShizuku(String path) {
    return path.contains('/Android/data') ||
        path.contains('/Android/obb') ||
        path.startsWith('/data') ||
        path.contains('/storage/emulated/0/Android/data') ||
        path.contains('/storage/emulated/0/Android/obb');
  }

  // 尝试使用Shizuku访问特定路径
  static Future<bool> tryAccessWithShizuku(String path) async {
    if (!isPathNeedShizuku(path)) {
      return false;
    }

    try {
      // 如果Shizuku未初始化或不可用，先尝试初始化
      if (!_isInitialized || !_isShizukuAvailable) {
        final initialized = await initialize();
        if (!initialized) {
          return false;
        }
      }

      // 启用强制Shizuku模式
      await setForceShizukuMode(true);

      // 尝试访问目录以验证权限
      await _shizukuApi?.runCommand('ls $path');

      return true;
    } catch (e) {
      debugPrint("Shizuku访问路径失败: $e");
      return false;
    }
  }

  // 获取Shizuku状态信息
  static Future<Map<String, dynamic>> getShizukuStatus() async {
    bool isInstalled = false;
    bool isRunning = false;
    bool hasPermission = false;
    String errorMessage = '';

    try {
      // 1. 检查是否安装
      _shizukuApi = ShizukuApi();
      isInstalled = true;

      // 2. 检查是否运行
      isRunning = await _safeCall(_shizukuApi?.pingBinder, false);

      // 3. 检查权限
      if (isRunning) {
        hasPermission = await _safeCall(_shizukuApi?.checkPermission, false);
      }
    } catch (e) {
      errorMessage = "检查Shizuku状态时出错: $e";
      debugPrint(errorMessage);
    }

    return {
      'isInstalled': isInstalled,
      'isRunning': isRunning,
      'hasPermission': hasPermission,
      'needSetup': isInstalled && (!isRunning || !hasPermission),
      'errorMessage': errorMessage,
    };
  }

  // 使用Shizuku构建目录
  static Future<bool> createDirectoryWithShizuku(String path) async {
    try {
      if (!await isAvailable()) {
        debugPrint("ShizukuFileService: Shizuku不可用，尝试初始化");
        final initialized = await initialize();
        if (!initialized) {
          debugPrint("ShizukuFileService: Shizuku初始化失败");
          return false;
        }
      }

      // 确保目录路径不包含特殊字符
      final sanitizedPath = path.replaceAll('"', '\\"');
      debugPrint("ShizukuFileService: 使用Shizuku创建目录: $sanitizedPath");

      final result = await _shizukuApi!.runCommand('mkdir -p "$sanitizedPath"');
      debugPrint("ShizukuFileService: 创建目录结果: $result");

      // 验证目录是否创建成功
      final checkResult =
          await _shizukuApi!.runCommand('ls -la "$sanitizedPath"');
      final success = checkResult != null;
      debugPrint("ShizukuFileService: 验证目录创建${success ? '成功' : '失败'}");

      return success;
    } catch (e) {
      debugPrint("ShizukuFileService: 使用Shizuku创建目录失败: $e");
      return false;
    }
  }

  // 当普通方式构建目录失败时，尝试使用Shizuku构建
  static Future<bool> tryBuildDirectoryWithShizuku(String path) async {
    debugPrint("ShizukuFileService: 尝试构建目录: $path");
    try {
      // 先尝试普通方式
      final dir = Directory(path);
      await dir.create(recursive: true);
      debugPrint("ShizukuFileService: 普通方式创建目录成功");
      return true;
    } catch (e) {
      debugPrint("ShizukuFileService: 普通方式构建目录失败: $e");

      // 普通方式失败，尝试Shizuku
      debugPrint("ShizukuFileService: 尝试使用Shizuku方式");
      final result = await createDirectoryWithShizuku(path);
      if (result) {
        // 如果成功，启用强制Shizuku模式
        await setForceShizukuMode(true);
      }
      return result;
    }
  }

  // 检查目录是否可以通过Shizuku访问
  static Future<bool> canAccessDirectoryWithShizuku(String path) async {
    debugPrint("ShizukuFileService: 检查目录是否可通过Shizuku访问: $path");
    if (!await isAvailable()) {
      debugPrint("ShizukuFileService: Shizuku不可用");
      return false;
    }

    try {
      // 确保路径不包含特殊字符
      final sanitizedPath = path.replaceAll('"', '\\"');
      final output = await _shizukuApi!.runCommand('ls "$sanitizedPath"');
      final result = output != null;
      debugPrint("ShizukuFileService: 可通过Shizuku访问: $result");
      return result;
    } catch (e) {
      debugPrint("ShizukuFileService: 通过Shizuku访问目录失败: $e");
      return false;
    }
  }

  // 初始化应用目录，如果普通方式失败则尝试Shizuku
  static Future<Map<String, dynamic>> initializeAppDirectory(
      String basePath, String appDirName) async {
    final appDirPath = '$basePath/$appDirName';
    bool success = false;
    bool usedShizuku = false;
    String errorMessage = '';

    // 先尝试普通方式
    try {
      final dir = Directory(appDirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      success = true;
    } catch (e) {
      errorMessage = "普通方式创建应用目录失败: $e";
      debugPrint(errorMessage);

      // 普通方式失败，检查Shizuku是否可用
      if (await isAvailable()) {
        try {
          // 尝试使用Shizuku创建目录
          await _shizukuApi!.runCommand('mkdir -p $appDirPath');

          // 验证目录是否创建成功
          final output = await _shizukuApi!.runCommand('ls -la $appDirPath');
          if (output != null) {
            success = true;
            usedShizuku = true;
            // 启用Shizuku模式
            await setForceShizukuMode(true);
          }
        } catch (e) {
          errorMessage = "Shizuku方式创建应用目录也失败: $e";
          debugPrint(errorMessage);
        }
      } else {
        errorMessage = "Shizuku服务不可用，无法创建应用目录";
        debugPrint(errorMessage);
      }
    }

    return {
      'success': success,
      'usedShizuku': usedShizuku,
      'path': appDirPath,
      'errorMessage': errorMessage,
    };
  }

  // 使用Shizuku写入文件内容
  static Future<bool> writeFileWithShizuku(String path, String content) async {
    if (!await isAvailable()) {
      return false;
    }

    try {
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.txt');
      await tempFile.writeAsString(content);

      // 使用Shizuku复制文件
      await _shizukuApi!.runCommand('cat "${tempFile.path}" > "$path"');

      // 删除临时文件
      await tempFile.delete();

      return true;
    } catch (e) {
      debugPrint("使用Shizuku写入文件失败: $e");
      return false;
    }
  }

  // 尝试使用普通方式写入文件，如果失败则使用Shizuku
  static Future<bool> writeFile(String path, String content,
      {bool? forceShizuku}) async {
    if (!(forceShizuku ?? _forceShizukuMode)) {
      try {
        final file = File(path);
        await file.writeAsString(content);
        return true;
      } catch (e) {
        debugPrint("普通方式写入文件失败，尝试使用Shizuku: $e");
      }
    }

    return await writeFileWithShizuku(path, content);
  }

  // 使用Shizuku复制文件
  static Future<bool> copyFileWithShizuku(
      String sourcePath, String destinationPath) async {
    if (!await isAvailable()) {
      return false;
    }

    try {
      await _shizukuApi!.runCommand('cp "$sourcePath" "$destinationPath"');
      return true;
    } catch (e) {
      debugPrint("使用Shizuku复制文件失败: $e");
      return false;
    }
  }

  // 尝试使用普通方式复制文件，如果失败则使用Shizuku
  static Future<bool> copyFile(String sourcePath, String destinationPath,
      {bool? forceShizuku}) async {
    if (!(forceShizuku ?? _forceShizukuMode)) {
      try {
        final sourceFile = File(sourcePath);
        await sourceFile.copy(destinationPath);
        return true;
      } catch (e) {
        debugPrint("普通方式复制文件失败，尝试使用Shizuku: $e");
      }
    }

    return await copyFileWithShizuku(sourcePath, destinationPath);
  }

  // 使用Shizuku删除文件
  static Future<bool> deleteFileWithShizuku(String path) async {
    if (!await isAvailable()) {
      return false;
    }

    try {
      await _shizukuApi!.runCommand('rm "$path"');
      return true;
    } catch (e) {
      debugPrint("使用Shizuku删除文件失败: $e");
      return false;
    }
  }

  // 尝试使用普通方式删除文件，如果失败则使用Shizuku
  static Future<bool> deleteFile(String path, {bool? forceShizuku}) async {
    if (!(forceShizuku ?? _forceShizukuMode)) {
      try {
        final file = File(path);
        await file.delete();
        return true;
      } catch (e) {
        debugPrint("普通方式删除文件失败，尝试使用Shizuku: $e");
      }
    }

    return await deleteFileWithShizuku(path);
  }

  // 使用Shizuku删除目录
  static Future<bool> deleteDirectoryWithShizuku(String path,
      {bool recursive = true}) async {
    if (!await isAvailable()) {
      return false;
    }

    try {
      if (recursive) {
        await _shizukuApi!.runCommand('rm -rf "$path"');
      } else {
        await _shizukuApi!.runCommand('rmdir "$path"');
      }
      return true;
    } catch (e) {
      debugPrint("使用Shizuku删除目录失败: $e");
      return false;
    }
  }

  // 尝试使用普通方式删除目录，如果失败则使用Shizuku
  static Future<bool> deleteDirectory(String path,
      {bool recursive = true, bool? forceShizuku}) async {
    if (!(forceShizuku ?? _forceShizukuMode)) {
      try {
        final dir = Directory(path);
        await dir.delete(recursive: recursive);
        return true;
      } catch (e) {
        debugPrint("普通方式删除目录失败，尝试使用Shizuku: $e");
      }
    }

    return await deleteDirectoryWithShizuku(path, recursive: recursive);
  }

  // 辅助方法：清理路径格式，去除可能的对象描述和多余引号
  static String _sanitizePath(String path) {
    return path
        .replaceAll('Directory: ', '')
        .replaceAll('File: ', '')
        .replaceAll("'", "")
        .trim();
  }

  // 检查文件或目录是否存在
  static Future<bool> exists(String path, {bool? forceShizuku}) async {
    // 首先清理路径
    path = _sanitizePath(path);

    debugPrint("ShizukuFileService: 检查路径是否存在: $path");

    // 路径是否需要Shizuku访问
    final needShizuku = isPathNeedShizuku(path);
    final useShizuku = forceShizuku ?? _forceShizukuMode;

    if (!useShizuku && !needShizuku) {
      // 使用普通方式
      try {
        final entity = FileSystemEntity.typeSync(path);
        final exists = entity != FileSystemEntityType.notFound;
        debugPrint("ShizukuFileService: 普通方式检查路径存在性: $exists");
        return exists;
      } catch (e) {
        debugPrint("ShizukuFileService: 普通方式检查路径失败: $e");
        // 如果普通方式出错，即使没有要求，也尝试Shizuku
      }
    }

    // 使用Shizuku方式
    try {
      // 确保Shizuku可用
      if (!await isAvailable()) {
        final initialized = await initialize();
        if (!initialized) {
          debugPrint("ShizukuFileService: Shizuku不可用，无法检查路径存在性");
          return false;
        }
      }

      // 使用更可靠的test命令检查文件存在性
      final sanitizedPath = path.replaceAll('"', '\\"');

      // 特别注意：修复存在性检查的脚本，确保空格和特殊字符不会导致问题
      // 使用[ -e ]检查文件或目录是否存在
      final cmd =
          '[ -e "$sanitizedPath" ] && echo "exists" || echo "not_exists"';
      debugPrint("ShizukuFileService: 执行Shizuku命令: $cmd");

      final output = await _shizukuApi!.runCommand(cmd);
      final result = output?.trim() == "exists";

      // 如果路径包含content.json但结果为false，添加额外的检查
      if (!result && path.endsWith("content.json")) {
        // 尝试获取上级目录内容，并检查列表中是否包含content.json
        try {
          // 获取父目录路径
          final parentPath = path.substring(0, path.lastIndexOf('/'));
          final sanitizedParentPath = parentPath.replaceAll('"', '\\"');

          debugPrint("ShizukuFileService: 尝试检查父目录: $parentPath");
          final lsCmd = 'ls "$sanitizedParentPath"';
          final lsOutput = await _shizukuApi!.runCommand(lsCmd);

          if (lsOutput != null && lsOutput.contains("content.json")) {
            debugPrint("ShizukuFileService: 在父目录内容中找到了content.json");
            return true;
          }
        } catch (e) {
          debugPrint("ShizukuFileService: 检查父目录内容失败: $e");
        }
      }

      debugPrint("ShizukuFileService: Shizuku检查路径存在结果: $result");
      return result;
    } catch (e) {
      debugPrint("ShizukuFileService: Shizuku方式检查路径存在性失败: $e");

      // 如果路径不是必须要Shizuku访问，则尝试普通方式
      if (!needShizuku) {
        try {
          final entity = FileSystemEntity.typeSync(path);
          return entity != FileSystemEntityType.notFound;
        } catch (e2) {
          debugPrint("ShizukuFileService: 普通方式检查路径也失败: $e2");
          return false;
        }
      }
      return false;
    }
  }

  // 尝试使用普通方式读取文件，如果失败则使用Shizuku
  static Future<String> readFile(String path, {bool? forceShizuku}) async {
    // 首先清理路径
    path = _sanitizePath(path);

    debugPrint("ShizukuFileService: 尝试读取文件: $path");

    // 路径是否需要Shizuku访问
    final needShizuku = isPathNeedShizuku(path);
    final useShizuku = forceShizuku ?? _forceShizukuMode;

    // 特别处理content.json文件，优先使用Shizuku方式
    final isContentJson = path.endsWith('content.json');

    // 优先使用Shizuku方式的条件: 1.强制使用 2.路径需要特权访问 3.是content.json文件
    if (useShizuku || needShizuku || isContentJson) {
      debugPrint(
          "ShizukuFileService: 将使用Shizuku读取文件: $path, isContentJson: $isContentJson");
      try {
        // 确保Shizuku可用
        if (!await isAvailable()) {
          final initialized = await initialize();
          if (!initialized) {
            debugPrint("ShizukuFileService: Shizuku不可用");

            // 如果是content.json但不强制Shizuku，可以回退到普通方式
            if (isContentJson && !useShizuku && !needShizuku) {
              debugPrint("ShizukuFileService: 回退到普通方式读取content.json");
              try {
                final file = File(path);
                final content = await file.readAsString();
                return content;
              } catch (e) {
                debugPrint("ShizukuFileService: 普通方式读取content.json失败: $e");
                throw Exception("无法读取文件: Shizuku不可用，普通方式也失败");
              }
            }

            final errorType = !_isInitialized
                ? ERROR_SHIZUKU_NOT_INSTALLED
                : !_isShizukuAvailable
                    ? ERROR_SHIZUKU_NOT_RUNNING
                    : ERROR_SHIZUKU_PERMISSION_DENIED;
            throw Exception(getErrorMessage(errorType));
          }
        }

        // 先检查文件是否存在
        final fileExists = await exists(path, forceShizuku: true);
        if (!fileExists) {
          // 对于content.json特殊处理，尝试检查目录
          if (isContentJson) {
            final dirPath = path.substring(0, path.lastIndexOf('/'));
            final dirExists = await exists(dirPath, forceShizuku: true);
            if (!dirExists) {
              debugPrint("ShizukuFileService: 文件的父目录不存在: $dirPath");
              throw Exception("无法读取文件: 父目录不存在");
            }
            debugPrint("ShizukuFileService: 父目录存在，但文件不存在: $path");
          }
          debugPrint("ShizukuFileService: 文件不存在: $path");
          throw Exception("文件不存在: $path");
        }

        // 使用Shizuku读取文件 - 用cat命令
        final sanitizedPath = path.replaceAll('"', '\\"');
        debugPrint("ShizukuFileService: 执行Shizuku命令: cat \"$sanitizedPath\"");

        final output = await _shizukuApi!.runCommand('cat "$sanitizedPath"');
        if (output == null) {
          debugPrint("ShizukuFileService: 读取文件失败，输出为null");
          throw Exception("读取文件失败，输出为null");
        }

        debugPrint(
            "ShizukuFileService: Shizuku方式成功读取文件，内容长度: ${output.length}");
        return output;
      } catch (e) {
        debugPrint("ShizukuFileService: Shizuku方式读取文件失败: $e");

        // 如果不是强制Shizuku且不需要特权访问，尝试普通方式
        if (!useShizuku && !needShizuku) {
          try {
            final file = File(path);
            final content = await file.readAsString();
            debugPrint(
                "ShizukuFileService: 普通方式成功读取文件，内容长度: ${content.length}");
            return content;
          } catch (e2) {
            debugPrint("ShizukuFileService: 普通方式读取文件也失败: $e2");
            throw Exception(
                "无法读取文件：所有方式均失败\n${getErrorMessage(ERROR_SHIZUKU_NOT_RUNNING)}\n原始错误: $e");
          }
        }

        // 如果是content.json，尝试使用不同的cat命令形式
        if (isContentJson) {
          try {
            debugPrint("ShizukuFileService: 尝试备用cat命令读取content.json");
            final sanitizedPath = path.replaceAll('"', '\\"');
            final altOutput = await _shizukuApi!.runCommand(
                'cat "$sanitizedPath" 2>/dev/null || echo "FILE_NOT_FOUND"');

            if (altOutput == null || altOutput.contains("FILE_NOT_FOUND")) {
              debugPrint("ShizukuFileService: 备用命令也无法读取文件");
              throw Exception("无法读取文件: 备用命令也失败");
            }

            debugPrint(
                "ShizukuFileService: 备用命令成功读取文件，内容长度: ${altOutput.length}");
            return altOutput;
          } catch (altError) {
            debugPrint("ShizukuFileService: 备用命令也失败: $altError");
          }
        }

        throw Exception(
            "无法读取文件：Shizuku方式失败\n${getErrorMessage(ERROR_SHIZUKU_NOT_RUNNING)}");
      }
    } else {
      // 普通方式
      try {
        final file = File(path);
        final content = await file.readAsString();
        debugPrint("ShizukuFileService: 普通方式成功读取文件，内容长度: ${content.length}");
        return content;
      } catch (e) {
        debugPrint("ShizukuFileService: 普通方式读取文件失败: $e");

        // 检查错误是否为权限问题
        if (e.toString().contains("Permission denied") ||
            e.toString().contains("errno = 13")) {
          debugPrint("ShizukuFileService: 检测到权限拒绝错误，尝试使用Shizuku");

          // 启用Shizuku并重试
          return await readFile(path, forceShizuku: true);
        }

        throw Exception("无法读取文件: $e");
      }
    }
  }

  // 尝试使用普通方式检查是否是目录，如果失败则使用Shizuku
  static Future<bool> isDirectory(String path, {bool? forceShizuku}) async {
    if (!(forceShizuku ?? _forceShizukuMode)) {
      try {
        return await FileSystemEntity.isDirectory(path);
      } catch (e) {
        debugPrint("普通方式检查是否是目录失败，尝试使用Shizuku: $e");
      }
    }

    // 如果普通方式失败或强制使用Shizuku，则尝试使用Shizuku
    if (!await isAvailable() || _shizukuApi == null) {
      throw Exception("无法检查是否是目录：普通方式失败且Shizuku服务不可用");
    }

    try {
      final output = await _shizukuApi!.runCommand('ls -ld $path');
      return (output ?? '').trim().startsWith('d');
    } catch (e) {
      debugPrint("Shizuku方式检查是否是目录失败: $e");
      return false;
    }
  }

  // 尝试使用普通方式创建目录，如果失败则使用Shizuku
  static Future<void> createDirectory(String path, {bool? forceShizuku}) async {
    if (!(forceShizuku ?? _forceShizukuMode)) {
      try {
        final dir = Directory(path);
        await dir.create(recursive: true);
        return;
      } catch (e) {
        debugPrint("普通方式创建目录失败，尝试使用Shizuku: $e");
      }
    }

    // 如果普通方式失败或强制使用Shizuku，则尝试使用Shizuku
    if (!await isAvailable() || _shizukuApi == null) {
      throw Exception("无法创建目录：普通方式失败且Shizuku服务不可用");
    }

    try {
      await _shizukuApi!.runCommand('mkdir -p $path');
    } catch (e) {
      debugPrint("Shizuku方式创建目录失败: $e");
      throw Exception("无法创建目录：所有方式均失败");
    }
  }

  // 关闭Shizuku服务
  static void dispose() {
    _shizukuApi = null;
    _isInitialized = false;
    _isShizukuAvailable = false;
    _forceShizukuMode = false;
  }

  // 添加新的方法，获取文件或目录的修改时间
  static Future<DateTime> getModifiedTime(String path,
      {bool? forceShizuku}) async {
    // 首先清理路径
    path = _sanitizePath(path);

    debugPrint("ShizukuFileService: 尝试获取修改时间: $path");
    final useShizuku = forceShizuku ?? _forceShizukuMode;
    final needShizuku = isPathNeedShizuku(path);

    // 获取当前时间作为上限，确保不返回未来时间
    final now = DateTime.now();

    // 如果是普通路径，尝试直接获取时间
    if (!useShizuku && !needShizuku) {
      try {
        final stat = await FileStat.stat(path);
        if (stat.modified.isAfter(DateTime(1971)) &&
            stat.modified.isBefore(now)) {
          debugPrint("ShizukuFileService: 普通方式获取到修改时间: ${stat.modified}");
          return stat.modified;
        }
        // 如果获取到的是1970年时间或未来时间，认为可能有问题，继续尝试Shizuku方式
      } catch (e) {
        debugPrint("ShizukuFileService: 普通方式获取修改时间失败: $e");
      }
    }

    // 使用Shizuku方式获取修改时间
    if (await isAvailable()) {
      try {
        final sanitizedPath = path.replaceAll('"', '\\"');
        // 使用stat命令获取修改时间的Unix时间戳
        final output =
            await _shizukuApi!.runCommand('stat -c %Y "$sanitizedPath"');

        if (output != null && output.trim().isNotEmpty) {
          final timestamp = int.tryParse(output.trim());
          if (timestamp != null && timestamp > 0) {
            var dateTime =
                DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            // 确保时间不是未来时间
            if (dateTime.isAfter(now)) {
              debugPrint("ShizukuFileService: 检测到未来时间: $dateTime，调整为当前时间");
              dateTime = now;
            }
            debugPrint("ShizukuFileService: Shizuku方式获取到修改时间: $dateTime");
            return dateTime;
          }
        }
      } catch (e) {
        debugPrint("ShizukuFileService: Shizuku方式获取修改时间失败: $e");

        // 尝试使用ls命令获取时间
        try {
          final sanitizedPath = path.replaceAll('"', '\\"');
          final output =
              await _shizukuApi!.runCommand('ls -la "$sanitizedPath"');

          if (output != null && output.trim().isNotEmpty) {
            final lines = const LineSplitter().convert(output);
            if (lines.isNotEmpty) {
              // 对于目录，ls -la会显示目录本身的信息在第一行
              final line = lines.first.trim();

              // 解析ls -la的输出，尝试获取时间信息
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 8) {
                try {
                  // 尝试解析月份、日期、时间/年份
                  final month = _parseMonth(parts[5]);
                  final day = int.tryParse(parts[6]) ?? 1;

                  DateTime dateTime;
                  if (parts[7].contains(':')) {
                    // 格式是时间 (HH:MM)，表示当前年份
                    final timeComponents = parts[7].split(':');
                    final hour = int.tryParse(timeComponents[0]) ?? 0;
                    final minute = int.tryParse(timeComponents[1]) ?? 0;

                    dateTime = DateTime(now.year, month, day, hour, minute);
                    // 如果解析出的日期在未来，可能是去年的文件
                    if (dateTime.isAfter(now)) {
                      dateTime =
                          DateTime(now.year - 1, month, day, hour, minute);
                    }
                  } else {
                    // 格式是年份，表示往年的文件
                    final year = int.tryParse(parts[7]) ?? now.year;
                    // 确保年份不超过当前年份
                    final adjustedYear = year > now.year ? now.year : year;
                    dateTime = DateTime(adjustedYear, month, day);
                  }

                  if (dateTime.isAfter(DateTime(1971)) &&
                      dateTime.isBefore(now)) {
                    debugPrint("ShizukuFileService: 从ls命令解析到修改时间: $dateTime");
                    return dateTime;
                  }
                } catch (parseError) {
                  debugPrint("ShizukuFileService: 解析时间格式失败: $parseError");
                }
              }
            }
          }
        } catch (lsError) {
          debugPrint("ShizukuFileService: 使用ls命令获取时间失败: $lsError");
        }
      }
    }

    // 如果所有方法都失败，返回当前时间减去1分钟作为默认值（确保不是未来时间）
    final defaultTime = now.subtract(const Duration(minutes: 1));
    debugPrint("ShizukuFileService: 无法获取准确修改时间，使用默认时间: $defaultTime");
    return defaultTime;
  }

  // 为目录获取修改时间的方便方法
  static Future<DateTime> getDirectoryModifiedTime(Directory directory,
      {bool? forceShizuku}) async {
    return await getModifiedTime(directory.path, forceShizuku: forceShizuku);
  }

  // 为文件获取修改时间的方便方法
  static Future<DateTime> getFileModifiedTime(File file,
      {bool? forceShizuku}) async {
    return await getModifiedTime(file.path, forceShizuku: forceShizuku);
  }

  // 批量获取文件修改时间的方法
  static Future<Map<String, DateTime>> getFilesModifiedTimes(List<String> paths,
      {bool? forceShizuku}) async {
    final results = <String, DateTime>{};
    final now = DateTime.now(); // 获取当前时间作为上限

    // 如果可用Shizuku并且路径较多，使用批量命令提高效率
    if (await isAvailable() && paths.length > 3) {
      try {
        // 单独处理每个路径，避免命令过长
        for (final path in paths) {
          if (results.containsKey(path)) continue;

          try {
            final sanitizedPath = path.replaceAll('"', '\\"');
            // 使用stat命令获取修改时间的Unix时间戳
            final output =
                await _shizukuApi!.runCommand('stat -c %Y "$sanitizedPath"');

            if (output != null && output.trim().isNotEmpty) {
              final timestamp = int.tryParse(output.trim());
              if (timestamp != null && timestamp > 0) {
                var dateTime =
                    DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                // 确保时间不是未来时间
                if (dateTime.isAfter(now)) {
                  debugPrint("ShizukuFileService: 检测到未来时间: $dateTime，调整为当前时间");
                  dateTime = now;
                }
                results[path] = dateTime;
                debugPrint("ShizukuFileService: 获取到文件时间 - $path: $dateTime");
              }
            }
          } catch (e) {
            debugPrint("ShizukuFileService: 获取路径时间失败: $path - $e");
          }
        }

        // 如果所有路径都已获取到时间，直接返回结果
        if (paths.every((p) => results.containsKey(p))) {
          debugPrint("ShizukuFileService: 批量获取时间完成，获取到${results.length}个时间");
          return results;
        }

        // 检查是否有任何路径没有获取到时间
        final missingPaths =
            paths.where((p) => !results.containsKey(p)).toList();
        if (missingPaths.isEmpty) {
          debugPrint("ShizukuFileService: 批量获取时间完成，获取到${results.length}个时间");
          return results;
        }

        // 对于未获取到时间的路径，尝试使用ls命令
        debugPrint("ShizukuFileService: ${missingPaths.length}个路径需要尝试备用方法获取时间");

        for (final path in missingPaths) {
          try {
            final sanitizedPath = path.replaceAll('"', '\\"');
            // 使用ls -la获取文件信息
            final output =
                await _shizukuApi!.runCommand('ls -la "$sanitizedPath"');

            if (output != null && output.trim().isNotEmpty) {
              final lines = const LineSplitter().convert(output);
              if (lines.isNotEmpty) {
                final line = lines.first;
                // 解析ls -la的输出，尝试获取时间信息
                final parts = line.split(RegExp(r'\s+'));
                if (parts.length >= 8) {
                  try {
                    // 尝试解析月份、日期、时间/年份
                    final month = _parseMonth(parts[5]);
                    final day = int.tryParse(parts[6]) ?? 1;

                    DateTime dateTime;
                    if (parts[7].contains(':')) {
                      // 格式是时间 (HH:MM)，表示当前年份
                      final timeComponents = parts[7].split(':');
                      final hour = int.tryParse(timeComponents[0]) ?? 0;
                      final minute = int.tryParse(timeComponents[1]) ?? 0;

                      dateTime = DateTime(now.year, month, day, hour, minute);
                      // 如果解析出的日期在未来，可能是去年的文件
                      if (dateTime.isAfter(now)) {
                        dateTime =
                            DateTime(now.year - 1, month, day, hour, minute);
                      }
                    } else {
                      // 格式是年份，表示往年的文件
                      final year = int.tryParse(parts[7]) ?? now.year;
                      // 确保年份不超过当前年份
                      final adjustedYear = year > now.year ? now.year : year;
                      dateTime = DateTime(adjustedYear, month, day);
                    }

                    if (dateTime.isAfter(DateTime(1971)) &&
                        dateTime.isBefore(now)) {
                      results[path] = dateTime;
                      debugPrint(
                          "ShizukuFileService: 从ls命令获取到时间 - $path: $dateTime");
                    }
                  } catch (parseError) {
                    debugPrint("ShizukuFileService: 解析时间失败: $parseError");
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("ShizukuFileService: ls命令获取时间失败: $path - $e");
          }
        }

        debugPrint("ShizukuFileService: 备用方法获取时间完成，现有${results.length}个时间");
      } catch (e) {
        debugPrint("ShizukuFileService: 批量获取时间失败: $e");
      }
    }

    // 对于仍未获取到时间的路径，逐个获取
    for (final path in paths) {
      if (!results.containsKey(path)) {
        results[path] = await getModifiedTime(path, forceShizuku: forceShizuku);
      }
    }

    debugPrint("ShizukuFileService: 获取时间完成，共${results.length}个时间");
    return results;
  }

  // 辅助方法：解析月份名称为月份数字
  static int _parseMonth(String monthName) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
      '1月': 1,
      '2月': 2,
      '3月': 3,
      '4月': 4,
      '5月': 5,
      '6月': 6,
      '7月': 7,
      '8月': 8,
      '9月': 9,
      '10月': 10,
      '11月': 11,
      '12月': 12,
    };
    return months[monthName] ?? 1; // 默认返回1月
  }

  // 尝试使用普通方式读取目录，如果失败则使用Shizuku
  static Future<List<FileSystemEntity>> listDirectory(String path,
      {bool? forceShizuku}) async {
    // 首先清理路径
    path = _sanitizePath(path);

    debugPrint("ShizukuFileService: 尝试列出目录: $path");

    // 路径是否需要Shizuku访问
    final needShizuku = isPathNeedShizuku(path);
    final useShizuku = forceShizuku ?? _forceShizukuMode;

    // 优先使用Shizuku方式的条件: 1.强制使用 2.路径需要特权访问(Android/data等)
    if (useShizuku || needShizuku) {
      debugPrint("ShizukuFileService: 将使用Shizuku列出目录");
      try {
        // 确保Shizuku可用
        if (!await isAvailable()) {
          final initialized = await initialize();
          if (!initialized) {
            debugPrint("ShizukuFileService: Shizuku不可用");
            final errorType = !_isInitialized
                ? ERROR_SHIZUKU_NOT_INSTALLED
                : !_isShizukuAvailable
                    ? ERROR_SHIZUKU_NOT_RUNNING
                    : ERROR_SHIZUKU_PERMISSION_DENIED;
            throw Exception(getErrorMessage(errorType));
          }
        }

        // 使用Shizuku列出目录 - 使用更简单可靠的命令
        final sanitizedPath = path.replaceAll('"', '\\"');

        // 先判断目录是否存在
        final dirCheckCmd =
            '[ -d "$sanitizedPath" ] && echo "exists" || echo "not_exists"';
        final dirCheckResult = await _shizukuApi!.runCommand(dirCheckCmd);

        if (dirCheckResult?.trim() != "exists") {
          debugPrint("ShizukuFileService: 目录不存在");
          return [];
        }

        // 使用简单的ls命令，避免复杂解析
        debugPrint("ShizukuFileService: 执行Shizuku命令: ls \"$sanitizedPath\"");
        final output = await _shizukuApi!.runCommand('ls "$sanitizedPath"');

        if (output == null || output.trim().isEmpty) {
          debugPrint("ShizukuFileService: 目录为空或无法访问");
          return [];
        }

        final result = <FileSystemEntity>[];
        final fileNames = const LineSplitter().convert(output);
        debugPrint("ShizukuFileService: 获取到${fileNames.length}个文件名");

        // 简单解析，只处理文件名
        for (var fileName in fileNames) {
          fileName = fileName.trim();
          if (fileName.isEmpty || fileName == "." || fileName == "..") continue;

          final fullPath = '$path/$fileName';

          // 检查是目录还是文件
          try {
            final fileTypeCmd =
                '[ -d "$fullPath" ] && echo "dir" || echo "file"';
            final fileType = await _shizukuApi!.runCommand(fileTypeCmd);

            if (fileType?.trim() == "dir") {
              result.add(Directory(fullPath));
              debugPrint("ShizukuFileService: 添加目录: $fileName");
            } else {
              result.add(File(fullPath));
              debugPrint("ShizukuFileService: 添加文件: $fileName");
            }
          } catch (e) {
            debugPrint("ShizukuFileService: 检查文件类型失败: $e");
            // 默认添加为文件
            result.add(File(fullPath));
          }
        }

        debugPrint("ShizukuFileService: Shizuku方式成功列出${result.length}个文件");
        return result;
      } catch (e) {
        debugPrint("ShizukuFileService: Shizuku方式读取目录失败: $e");

        // 尝试备用方法 - 使用find命令
        try {
          debugPrint("ShizukuFileService: 尝试使用备用find命令");
          final sanitizedPath = path.replaceAll('"', '\\"');
          final findCmd =
              'find "$sanitizedPath" -maxdepth 1 -not -path "$sanitizedPath"';
          final output = await _shizukuApi!.runCommand(findCmd);

          if (output == null || output.trim().isEmpty) {
            debugPrint("ShizukuFileService: 备用命令未找到文件");
            return [];
          }

          final result = <FileSystemEntity>[];
          final paths = const LineSplitter().convert(output);

          for (final entryPath in paths) {
            if (entryPath.trim().isEmpty) continue;

            // 检查是目录还是文件
            final typeCmd = '[ -d "$entryPath" ] && echo "dir" || echo "file"';
            final typeOutput = await _shizukuApi!.runCommand(typeCmd);

            if (typeOutput?.trim() == "dir") {
              result.add(Directory(entryPath));
              debugPrint(
                  "ShizukuFileService: 添加目录(备用方式): ${entryPath.split('/').last}");
            } else {
              result.add(File(entryPath));
              debugPrint(
                  "ShizukuFileService: 添加文件(备用方式): ${entryPath.split('/').last}");
            }
          }

          debugPrint("ShizukuFileService: 备用方式成功列出${result.length}个文件");
          return result;
        } catch (backupError) {
          debugPrint("ShizukuFileService: 备用方式也失败: $backupError");
        }

        // 如果路径不是必须要Shizuku访问，则尝试普通方式
        if (!needShizuku) {
          try {
            final dir = Directory(path);
            final list = await dir.list().toList();
            debugPrint("ShizukuFileService: 普通方式列出目录成功，文件数: ${list.length}");
            return list;
          } catch (e2) {
            debugPrint("ShizukuFileService: 普通方式读取目录也失败: $e2");
            throw Exception(
                "无法访问目录：所有方式均失败\n${getErrorMessage(ERROR_SHIZUKU_NOT_RUNNING)}\n原始错误: $e");
          }
        }
        throw Exception(
            "无法访问目录：Shizuku方式失败\n${getErrorMessage(ERROR_SHIZUKU_NOT_RUNNING)}");
      }
    } else {
      // 普通方式
      try {
        final dir = Directory(path);
        final list = await dir.list().toList();
        debugPrint("ShizukuFileService: 普通方式列出目录成功，文件数: ${list.length}");
        return list;
      } catch (e) {
        debugPrint("ShizukuFileService: 普通方式读取目录失败: $e");

        // 检查错误是否为权限问题
        if (e.toString().contains("Permission denied") ||
            e.toString().contains("errno = 13")) {
          debugPrint("ShizukuFileService: 检测到权限拒绝错误，尝试使用Shizuku");

          return await listDirectory(path, forceShizuku: true);
        }
        rethrow;
      }
    }
  }
}
