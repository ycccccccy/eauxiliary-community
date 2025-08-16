/// Eauxiliary社区版
///
/// 本文件负责应用的初始化、主题配置和状态管理设置。
library;

import 'package:eauxiliary/providers/answer_provider.dart';
import 'package:eauxiliary/providers/settings_provider.dart';
import 'package:eauxiliary/screens/main_screen.dart';
import 'package:eauxiliary/screens/onboarding/onboarding_screen.dart';
import 'package:eauxiliary/utils/first_run_check.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eauxiliary/services/file_service.dart';
import 'package:eauxiliary/services/shizuku_file_service.dart';
import 'package:eauxiliary/services/version_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// 应用程序的主入口点
///
/// 负责初始化Flutter绑定、平台服务，并启动应用
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置全局错误处理器
  _setupErrorHandling();

  // 记录应用启动信息，便于调试
  _logAppStart();

  // 执行平台相关的初始化
  await _initializePlatformServices();

  // 初始化应用核心服务
  await FileService.initSettings();

  // 检查应用状态，如是否首次运行
  final isFirstRun = await FirstRunCheck.isFirstRun();
  debugPrint("应用启动: 设置加载完成，首次运行=$isFirstRun");

  // 使用 MultiProvider 启动应用，为整个应用提供状态管理
  runApp(
    MultiProvider(
      providers: [
        // 提供设置状态
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        // 提供答案相关的状态，并依赖于 SettingsProvider
        ChangeNotifierProvider(
          create: (context) => AnswerProvider()..initialize(),
        ),
      ],
      child: MyApp(isFirstRun: isFirstRun),
    ),
  );
}

/// 设置全局错误处理机制
void _setupErrorHandling() {
  // 捕获 Flutter 框架内的错误
  FlutterError.onError = (FlutterErrorDetails details) {
    // 特别处理 MissingPluginException，通常发生在平台通道调用失败时
    // 在这里忽略它，以避免因 Shizuku 等可选插件不存在而导致应用崩溃
    if (details.exception is MissingPluginException) {
      debugPrint('已忽略的 MissingPluginException: ${details.exception}');
    } else {
      // 对于所有其他类型的错误，使用 Flutter 默认的错误呈现方式
      FlutterError.presentError(details);
    }
  };

  // 捕获来自平台通道的错误（例如，方法调用失败）
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error is MissingPluginException) {
      debugPrint('已忽略的平台通道 MissingPluginException: $error');
      return true; // 返回 true 表示错误已被处理。
    }
    return false; // 返回 false 表示让系统或其他处理器处理。
  };
}

/// 打印应用启动日志。
void _logAppStart() {
  debugPrint("==========================================");
  debugPrint("Eauxiliary 应用启动 (${DateTime.now()})");
  debugPrint(
      "平台: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}");
  debugPrint("==========================================");
}

/// 根据当前运行的平台初始化特定服务。
Future<void> _initializePlatformServices() async {
  // 在 Android 平台上，尝试初始化 Shizuku 服务以获取高级文件访问权限。
  if (Platform.isAndroid) {
    try {
      // 加载用户是否启用强制 Shizuku 模式的设置。
      await ShizukuFileService.loadShizukuModeSetting();

      // 如果启用了强制 Shizuku 模式，则进行初始化。
      if (ShizukuFileService.isForceShizukuMode) {
        try {
          final initialized = await ShizukuFileService.initialize();
          debugPrint(
              "应用启动: Shizuku初始化${initialized ? '成功' : '失败'}，强制Shizuku模式: ${ShizukuFileService.isForceShizukuMode}");
        } on MissingPluginException catch (e) {
          // 如果设备上没有安装 Shizuku，会抛出此异常。
          debugPrint("应用启动: Shizuku 插件不可用: $e");
        } catch (e) {
          debugPrint("应用启动: Shizuku 初始化失败: $e");
        }
      }
    } catch (e) {
      debugPrint("应用启动: Shizuku 设置加载失败: $e");
    }
  } else {
    debugPrint("非 Android 平台，跳过 Shizuku 初始化");
  }
}

/// MyApp 是应用的根 Widget。
///
/// 它负责构建 MaterialApp，并根据 `SettingsProvider` 配置明亮和黑暗主题。
class MyApp extends StatelessWidget {
  /// 是否为首次运行。
  final bool isFirstRun;

  const MyApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    // 从 Provider 获取设置，用于主题切换。
    final settingsProvider = Provider.of<SettingsProvider>(context);
    const primaryColor = Color(0xFF2196F3);

    return MaterialApp(
      title: 'EAuxiliary',
      // 应用的明亮主题配置。
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: _getSystemFontFamily(),
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: primaryColor,
          surface: Colors.white,
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        // 为不同平台定义页面切换动画。
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF99BBDD), width: 2.0),
          ),
          color: Colors.white,
          shadowColor: const Color(0x66000000),
          surfaceTintColor: Colors.white,
          margin: const EdgeInsets.all(4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // 定义应用的文本样式。
        textTheme: const TextTheme(
          bodyLarge:
              TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w400),
          bodyMedium:
              TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w400),
          bodySmall:
              TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.w400),
          titleLarge:
              TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w600),
          titleMedium:
              TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w600),
          titleSmall:
              TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w500),
          labelLarge:
              TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w500),
          labelMedium:
              TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w500),
          labelSmall:
              TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.w500),
        ),
      ),
      // 应用的黑暗主题配置。
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: _getSystemFontFamily(),
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: primaryColor,
          surface: Colors.grey[900]!,
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF555555), width: 1.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      // 根据 Provider 的状态切换主题模式。
      themeMode: settingsProvider.themeMode,
      // 应用的起始页面。
      home: _AppStartScreen(isFirstRun: isFirstRun),
      // 隐藏调试横幅。
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        // 此处可以处理动态路由。
        return null;
      },
    );
  }

  /// 获取系统字体。这里统一使用鸿蒙黑体。
  String? _getSystemFontFamily() {
    return 'HarmonyOS_SansSC';
  }
}

/// `_AppStartScreen` 是一个有状态的 Widget，用作应用的启动分发器。
///
/// 它在初始化时检查应用版本，并根据 `isFirstRun` 标志决定显示引导页还是主页。
class _AppStartScreen extends StatefulWidget {
  final bool isFirstRun;

  const _AppStartScreen({required this.isFirstRun});

  @override
  State<_AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<_AppStartScreen> {
  @override
  void initState() {
    super.initState();
    // 异步检查应用版本更新。
    _checkVersion();
  }

  /// 连接到服务器检查是否有新版本。
  Future<void> _checkVersion() async {
    try {
      final versionInfo = await VersionService.checkVersion();

      // 检查 Widget 是否仍然挂载在树上，避免在已销毁的 Widget 上调用 setState。
      if (!mounted) return;

      // 如果需要更新，则显示更新对话框。
      if (versionInfo['needsUpdate'] == true) {
        _showUpdateDialog(versionInfo);
      }
    } catch (e) {
      debugPrint('版本检查失败: $e');
    }
  }

  /// 显示版本更新对话框。
  void _showUpdateDialog(Map<String, dynamic> versionInfo) {
    showDialog(
      context: context,
      barrierDismissible: false, // 不允许点击外部关闭
      builder: (context) => AlertDialog(
        title: const Text('发现新版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前版本: ${versionInfo['currentVersion']}'),
            Text('最新版本: ${versionInfo['serverVersion']}'),
            const SizedBox(height: 16),
            const Text('更新内容：'),
            // 从 changelog 动态创建更新内容列表。
            ...List<Widget>.from(
              (versionInfo['changelog'] as List<String>).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• $item'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () async {
              // 使用 url_launcher 打开更新链接。
              final Uri url =
                  Uri.parse('https://www.123684.com/s/gsA8Vv-LcC23');
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                debugPrint('无法打开更新网站: $url');
              }
              Navigator.of(context).pop();
            },
            child: const Text('现在更新'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 根据是否首次运行，决定显示引导页还是主屏幕。
    return widget.isFirstRun ? const OnboardingScreen() : const MainScreen();
  }
}
