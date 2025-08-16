import 'package:eauxiliary/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:eauxiliary/utils/first_run_check.dart';
import 'package:eauxiliary/services/shizuku_file_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryFragment extends StatefulWidget {
  const DirectoryFragment({super.key});

  @override
  _DirectoryFragmentState createState() => _DirectoryFragmentState();
}

class _DirectoryFragmentState extends State<DirectoryFragment>
    with SingleTickerProviderStateMixin {
  static const _targetPackageName = "com.ets100.secondary";
  static const ZERO_WIDTH_SPACE = "\u200B";
  String _resultText = "正在自动进行环境准备..."; // 初始文本
  String _detailText = ""; // 详细信息文本
  bool _isShizukuAvailable = false;
  bool _isProcessing = false; // 标记是否正在处理，用于禁用按钮和显示加载指示器, true的时候不能按按钮
  bool _isWindowsPlatform = false; // 标记是否为Windows平台

  // 动画相关
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint("DirectoryFragment: initState");

    // 检测当前平台
    _checkPlatform();

    // 初始化动画控制器
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    // 根据平台选择相应的初始化方法
    if (_isWindowsPlatform) {
      _setupWindowsDirectory();
    } else {
      _checkShizukuAvailability();
      _buildDirectoryInBackground();
    }

    // 启动动画
    _animController.forward();
  }

  @override
  void dispose() {
    debugPrint("DirectoryFragment: dispose");
    _animController.dispose(); // 释放动画控制器
    super.dispose();
  }

  Future<void> _checkShizukuAvailability() async {
    try {
      final initialized = await ShizukuFileService.initialize();
      debugPrint("Shizuku初始化结果: $initialized");

      final status = await ShizukuFileService.getShizukuStatus();
      debugPrint("Shizuku状态: $status");

      setState(() {
        _isShizukuAvailable = status['isInstalled'];
      });
      debugPrint("Shizuku可用性: $_isShizukuAvailable");
    } catch (e) {
      debugPrint("检查Shizuku可用性时出错: $e");
    }
  }

  Future<void> _buildDirectoryInBackground() async {
    if (_isProcessing) return; // 如果正在处理，则直接返回

    setState(() {
      _isProcessing = true;
      _resultText = "正在自动进行环境准备...";
      _detailText = "正在查找目标应用目录...";
    });

    try {
      debugPrint("开始构建目录");
      final targetDirectoryPath = await _getTargetPathWithWorkaround();

      if (targetDirectoryPath != null) {
        debugPrint("找到目标路径: $targetDirectoryPath");
        final directory = Directory(targetDirectoryPath);
        final exists = await directory.exists();
        debugPrint("目录存在: $exists");

        if (exists) {
          try {
            final contents = await directory.list().toList();
            debugPrint("目录可访问，内容数量: ${contents.length}");

            setState(() {
              _resultText = "已找到目标应用目录";
              _detailText =
                  "目录路径: $targetDirectoryPath\n目录可访问: 是\n内容数量: ${contents.length}";
            });

            await _saveDirectoryPath(targetDirectoryPath);
            await _showSuccessAndNavigate();
          } catch (e) {
            debugPrint("目录存在但无法访问: $e");
            _handleDirectoryAccessFailure(targetDirectoryPath, e);
          }
        } else {
          _handleDirectoryNotFound(targetDirectoryPath);
        }
      } else {
        _handleTargetAppNotFound();
      }
    } catch (e) {
      _handleGenericError(e);
    } finally {
      setState(() {
        _isProcessing = false; // 完成处理，无论结果如何
      });
    }
  }

  void _handleDirectoryAccessFailure(String path, Object e) {
    if (!mounted) return;
    setState(() {
      _resultText = "目录存在，但无法访问";
      _detailText = "目录路径: $path\n错误信息: $e\n\n请手动选择目录或使用Shizuku访问";
    });
  }

  void _handleDirectoryNotFound(String path) {
    if (!mounted) return;
    setState(() {
      _resultText = "未找到目标应用目录";
      _detailText = "已尝试路径: $path\n\n请确保已安装目标应用，或手动选择目录或使用Shizuku访问";
    });
  }

  void _handleTargetAppNotFound() {
    if (!mounted) return;
    setState(() {
      _resultText = "未找到目标应用";
      _detailText = "请确保已安装目标应用，或手动选择目录或使用Shizuku访问";
    });
  }

  void _handleGenericError(Object e) {
    if (!mounted) return;
    setState(() {
      _resultText = "发生错误";
      _detailText = "错误信息: $e\n\n请手动选择目录或使用Shizuku访问";
    });
  }

  Future<String?> _getTargetPathWithWorkaround() async {
    try {
      final directPath =
          '${Directory.systemTemp.path}/A${ZERO_WIDTH_SPACE}ndroid/data/$_targetPackageName';
      debugPrint("尝试路径: $directPath");

      final exists = await Directory(directPath).exists();
      debugPrint("目录存在: $exists");

      if (exists) {
        return directPath;
      } else {
        const alternativePath =
            '/storage/emulated/0/A${ZERO_WIDTH_SPACE}ndroid/data/$_targetPackageName';
        debugPrint("尝试替代路径: $alternativePath");

        final alternativeExists = await Directory(alternativePath).exists();
        debugPrint("替代路径存在: $alternativeExists");

        if (alternativeExists) {
          return alternativePath;
        }
      }

      final tempDir = Directory.systemTemp;
      debugPrint("系统临时目录: ${tempDir.path}");
      try {
        final contents = await tempDir.list().toList();
        debugPrint(
            "系统临时目录内容: ${contents.map((e) => e.path.split('/').last).join(', ')}");
      } catch (e) {
        debugPrint("无法列出系统临时目录内容: $e");
      }

      return null;
    } catch (e) {
      debugPrint("获取目标路径时发生错误: $e");
      return null;
    }
  }

  Future<void> _saveDirectoryPath(String path) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString('directory_uri', path);
      debugPrint("目录路径已保存: $path");
      await FirstRunCheck.setNotFirstRun();
      debugPrint("已设置为非首次运行");
    } catch (e) {
      debugPrint("保存目录路径时发生错误: $e");
      rethrow;
    }
  }

  Future<void> _showSuccessAndNavigate() async {
    if (!mounted) return;

    setState(() {
      _resultText = "一切就绪";
      _detailText = "即将跳转到主界面...";
    });

    // 重置并启动动画
    _animController.reset();
    _animController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        debugPrint("DirectoryFragment: 准备导航到MainScreen");
        if (mounted) {
          try {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
            debugPrint("DirectoryFragment: 已调用导航到MainScreen");
          } catch (e) {
            debugPrint("DirectoryFragment: 导航到MainScreen时发生错误: $e");
          }
        } else {
          debugPrint("DirectoryFragment: 组件已卸载，无法导航");
        }
      });
    });
  }

  Future<void> _pickDirectoryWithSAF() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _resultText = "请选择目录...";
      _detailText = "请在文件选择器中选择目标应用的数据目录";
    });

    try {
      debugPrint("开始手动选择目录");
      String? directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath != null) {
        debugPrint("用户选择的目录: $directoryPath");

        if (directoryPath.contains('Android/data')) {
          directoryPath = directoryPath.replaceAll(
              'Android/data', 'A${ZERO_WIDTH_SPACE}ndroid/data');
          debugPrint("修正后的路径: $directoryPath");
        }

        await _saveDirectoryPath(directoryPath);

        setState(() {
          _resultText = "已选择目录";
          _detailText = "已保存目录: $directoryPath";
        });

        // 延迟导航，让用户看到成功消息
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showSuccessAndNavigate();
          }
        });
      } else {
        debugPrint("用户取消了目录选择");
        setState(() {
          _resultText = "未选择目录";
          _detailText = "用户取消了目录选择，请重试或使用Shizuku访问";
        });
      }
    } catch (e) {
      debugPrint("手动选择目录时发生错误: $e");
      setState(() {
        _resultText = "选择目录时出错";
        _detailText = "错误信息: $e\n\n请重试或使用Shizuku访问";
      });
    } finally {
      setState(() {
        _isProcessing = false; // 确保处理状态被重置
      });
    }
  }

  Future<void> _accessWithShizuku() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _resultText = "正在使用Shizuku...";
      _detailText = "正在初始化Shizuku...\n";
    });

    try {
      debugPrint("开始使用Shizuku访问");

      await updateDetailText("检查Shizuku状态...");
      final status = await ShizukuFileService.getShizukuStatus();
      debugPrint("Shizuku状态: $status");

      if (!status['isInstalled']) {
        debugPrint("Shizuku未安装");
        setState(() {
          _resultText = "Shizuku未安装";
          _detailText = "请先安装Shizuku应用";
        });
        _showShizukuNotInstalledDialog();
        return;
      }

      if (!status['isRunning']) {
        debugPrint("Shizuku未运行");
        setState(() {
          _resultText = "Shizuku未运行";
          _detailText = "请先启动Shizuku服务";
        });
        _showShizukuNotRunningDialog();
        return;
      }

      await updateDetailText("初始化Shizuku服务...");
      final initialized = await ShizukuFileService.initialize();
      debugPrint("Shizuku初始化结果: $initialized");

      if (!initialized) {
        debugPrint("Shizuku初始化失败");
        setState(() {
          _resultText = "Shizuku初始化失败";
          _detailText = "请确保Shizuku已安装并正在运行";
        });
        return;
      }

      await updateDetailText("设置强制Shizuku模式...");
      await ShizukuFileService.setForceShizukuMode(true);
      debugPrint("已启用强制Shizuku模式");

      final targetPath = '/storage/emulated/0/Android/data/$_targetPackageName';
      await updateDetailText("目标路径: $targetPath\n检查目录是否存在...");

      final exists =
          await ShizukuFileService.exists(targetPath, forceShizuku: true);
      debugPrint("目录存在: $exists");

      if (!exists) {
        debugPrint("目录不存在，尝试创建");
        await updateDetailText("目录不存在，尝试创建...");

        try {
          await ShizukuFileService.createDirectory(targetPath,
              forceShizuku: true);
          debugPrint("目录创建成功");
          await updateDetailText("目录创建成功！");
        } catch (e) {
          debugPrint("创建目录失败: $e");
          setState(() {
            _resultText = "创建目录失败";
            _detailText = "创建目录失败: $e";
          });
          return;
        }
      }

      try {
        await updateDetailText("列出目录内容以验证访问权限...");
        debugPrint("尝试列出目录内容");

        final files = await ShizukuFileService.listDirectory(targetPath,
            forceShizuku: true);
        debugPrint("使用Shizuku成功访问目录，文件数量: ${files.length}");

        await updateDetailText("成功访问目录！目录中共有 ${files.length} 个文件\n显示部分文件：\n" +
            files.take(5).map((f) => "- ${f.path.split('/').last}").join('\n'));

        await updateDetailText("保存目录路径...");
        await _saveDirectoryPath(targetPath);
        debugPrint("目录路径已保存");

        setState(() {
          _resultText = "Shizuku访问成功";
          _detailText = "已成功使用Shizuku设置目录";
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showSuccessAndNavigate();
          }
        });
      } catch (e) {
        debugPrint("使用Shizuku访问目录失败: $e");
        setState(() {
          _resultText = "Shizuku访问失败";
          _detailText = "使用Shizuku访问目录失败: $e";
        });
      }
    } catch (e) {
      debugPrint("使用Shizuku时发生错误: $e");
      setState(() {
        _resultText = "Shizuku操作出错";
        _detailText = "使用Shizuku时发生错误: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false; // 确保处理状态被重置
      });
    }
  }

  Future<void> updateDetailText(String newText) async {
    if (mounted) {
      setState(() {
        _detailText += newText + "\n";
      });
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _openShizukuDownloadPage() async {
    const url = 'https://www.123684.com/s/gsA8Vv-zcC23'; //Shizuku下载链接
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _showShizukuNotInstalledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("需要安装Shizuku"),
        content: Text(ShizukuFileService.getErrorMessage(
            ShizukuFileService.ERROR_SHIZUKU_NOT_INSTALLED)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openShizukuDownloadPage();
            },
            child: const Text("下载Shizuku"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("取消"),
          ),
        ],
      ),
    );
  }

  void _showShizukuNotRunningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Shizuku未运行"),
        content: Text(ShizukuFileService.getErrorMessage(
            ShizukuFileService.ERROR_SHIZUKU_NOT_RUNNING)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showShizukuPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Shizuku权限被拒绝"),
        content: Text(ShizukuFileService.getErrorMessage(
            ShizukuFileService.ERROR_SHIZUKU_PERMISSION_DENIED)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "手动选择目录说明:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "1. 点击下方的「选择目录」按钮\n"
            "2. 在文件管理器中，导航到「Android」→「data」\n"
            "3. 找到并选择「com.ets100.secondary」文件夹\n"
            "4. 如果看不到此文件夹，请确保已安装目标应用\n"
            "5. 将其复制到内部存储下的Download文件夹中"
            "6. 点击选择目录选择刚刚复制到Download的ets目录",
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShizukuInstructions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.amber.shade900 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDarkMode ? Colors.amber.shade700 : Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "使用Shizuku访问说明:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Shizuku可以帮助访问Android 11+系统限制的目录，如Android/data。\n\n"
            "1. 安装Shizuku应用（Google Play或官网）\n"
            "2. 根据设备情况启动Shizuku服务\n"
            "3. 点击下方的「使用Shizuku访问」按钮",
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String text,
    required Color backgroundColor,
    required Color foregroundColor,
    Widget? leading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: 12),
            ],
            Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary; // 获取主题色

    // 准备条件判断结果
    final bool shouldShowOptions = _resultText.contains("无法") ||
        _resultText.contains("失败") ||
        _resultText.contains("未找到") ||
        _resultText.contains("无效") ||
        _resultText.contains("错误");

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 顶部图标
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isWindowsPlatform ? Icons.computer : Icons.folder_open,
                    size: 60,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 40),

                // 主要结果文本
                Text(
                  _resultText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),

                // 详细信息
                if (_detailText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _detailText,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // 根据平台和状态显示不同的选项
                if (_isWindowsPlatform && shouldShowOptions) ...[
                  // Windows平台特定UI
                  _buildWindowsInstructions(),
                  _buildButton(
                    onPressed: _isProcessing ? null : _pickWindowsDirectory,
                    text: "手动选择ETS目录",
                    backgroundColor:
                        isDarkMode ? Colors.green.shade700 : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                ] else if (!_isWindowsPlatform && shouldShowOptions) ...[
                  // 移动平台UI
                  _buildInstructions(),
                  _buildShizukuInstructions(),
                  _buildButton(
                    onPressed: _isProcessing ? null : _pickDirectoryWithSAF,
                    text: "手动选择目录[不推荐]",
                    backgroundColor: isDarkMode
                        ? Colors.pinkAccent.shade700
                        : Colors.pinkAccent,
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Shizuku 安装教程"),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("1. 下载并安装 Shizuku："),
                                      TextButton(
                                        onPressed: _openShizukuDownloadPage,
                                        child: const Text("点击下载 Shizuku"),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text("2. 启动方法（二选一）：\n"
                                          "• 无Root设备（华为）：\n"
                                          "  - 连接电脑\n"
                                          "  - 开启USB调试\n"
                                          "  - 在电脑执行Shizuku给的 adb 命令\n"
                                          "  - 无Root设备（非华为）\n"
                                          "  - 前往设置页面的开发者模式\n"
                                          "  - 打开无线调试\n"
                                          "  - 回到Shizuku使用无线调试方案激活\n"
                                          "• Root设备：\n"
                                          "  - 直接在应用内启动"),
                                      const SizedBox(height: 8),
                                      const Text("3. 启动后回到本应用\n"
                                          "4. 点击使用 Shizuku按钮"),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text("关闭"),
                                  ),
                                ],
                              ),
                            );
                          },
                    text: "Shizuku 教程",
                    backgroundColor:
                        isDarkMode ? Colors.blue.shade700 : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildButton(
                    onPressed: _isProcessing ? null : _accessWithShizuku,
                    text: _isProcessing ? "处理中..." : "使用 Shizuku 访问",
                    backgroundColor:
                        isDarkMode ? Colors.blue.shade700 : Colors.blue,
                    foregroundColor: Colors.white,
                    leading: _isProcessing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  isDarkMode ? Colors.white70 : Colors.white),
                            ),
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 检测当前平台
  void _checkPlatform() {
    try {
      // 使用Platform.isWindows检测是否为Windows平台
      _isWindowsPlatform = Platform.isWindows;
      debugPrint("DirectoryFragment: 当前平台是Windows: $_isWindowsPlatform");
    } catch (e) {
      debugPrint("DirectoryFragment: 检测平台时出错: $e");
      _isWindowsPlatform = false;
    }
  }

  // Windows平台的目录设置
  Future<void> _setupWindowsDirectory() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _resultText = "正在配置Windows环境...";
      _detailText = "正在查找ETS目录...";
    });

    try {
      // 获取Windows下的AppData目录
      final appDataPath = Platform.environment['APPDATA'];
      if (appDataPath == null) {
        throw Exception("无法获取AppData目录路径");
      }

      final etsDirectoryPath = '$appDataPath\\ETS';
      debugPrint("Windows ETS目录路径: $etsDirectoryPath");

      // 检查目录是否存在
      final directory = Directory(etsDirectoryPath);
      final exists = await directory.exists();

      if (exists) {
        debugPrint("ETS目录存在");

        // 检查目录内容
        try {
          final contents = await directory.list().toList();
          debugPrint("ETS目录可访问，内容数量: ${contents.length}");

          // 验证是否有效 - 检查是否包含数字文件夹
          bool hasValidContent = false;
          for (var item in contents) {
            if (item is Directory) {
              final folderName = item.path.split(Platform.pathSeparator).last;
              if (RegExp(r'^\d+$').hasMatch(folderName)) {
                hasValidContent = true;
                break;
              }
            }
          }

          if (hasValidContent) {
            setState(() {
              _resultText = "已找到ETS目录";
              _detailText =
                  "目录路径: $etsDirectoryPath\n目录可访问: 是\n内容数量: ${contents.length}";
            });

            await _saveDirectoryPath(etsDirectoryPath);
            await _showSuccessAndNavigate();
          } else {
            _handleInvalidETSDirectory(etsDirectoryPath);
          }
        } catch (e) {
          debugPrint("ETS目录存在但无法访问: $e");
          _handleDirectoryAccessFailure(etsDirectoryPath, e);
        }
      } else {
        _handleMissingETSDirectory(etsDirectoryPath);
      }
    } catch (e) {
      _handleGenericError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // 处理ETS目录无效的情况
  void _handleInvalidETSDirectory(String path) {
    if (!mounted) return;
    setState(() {
      _resultText = "ETS目录结构无效";
      _detailText = "目录路径: $path\n未找到有效的试题文件夹\n请确保ETS目录下有数字命名的文件夹";
    });
  }

  // 处理ETS目录不存在的情况
  void _handleMissingETSDirectory(String path) {
    if (!mounted) return;
    setState(() {
      _resultText = "未找到ETS目录";
      _detailText = "尝试路径: $path\n请确保已安装ETS软件\n或手动选择ETS目录";
    });
  }

  // Windows平台手动选择目录
  Future<void> _pickWindowsDirectory() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _resultText = "请选择ETS目录...";
      _detailText = "请在文件选择器中选择ETS目录";
    });

    try {
      debugPrint("开始手动选择Windows目录");
      String? directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath != null) {
        debugPrint("用户选择的目录: $directoryPath");

        // 检查选择的目录是否为有效的ETS目录
        final directory = Directory(directoryPath);

        // 如果不存在则创建目录
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // 验证目录内容
        final contents = await directory.list().toList();
        debugPrint("选择的目录内容数量: ${contents.length}");

        // 检查是否有数字命名的文件夹（可能是ETS试题文件夹）
        bool hasValidContent = false;
        for (var item in contents) {
          if (item is Directory) {
            final folderName = item.path.split(Platform.pathSeparator).last;
            if (RegExp(r'^\d+$').hasMatch(folderName)) {
              hasValidContent = true;
              break;
            }
          }
        }

        if (hasValidContent) {
          await _saveDirectoryPath(directoryPath);

          setState(() {
            _resultText = "已设置ETS目录";
            _detailText = "目录路径: $directoryPath\n目录包含有效内容";
          });

          // 延迟导航，让用户看到成功消息
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _showSuccessAndNavigate();
            }
          });
        } else {
          // 即使目录内没有明确的ETS内容，也允许用户继续
          // 但给予警告提示
          setState(() {
            _resultText = "已设置目录，但未找到试题";
            _detailText =
                "目录路径: $directoryPath\n未检测到ETS试题文件夹\n将继续使用该目录，但可能无法显示答案";
          });

          await _saveDirectoryPath(directoryPath);

          // 延迟导航，让用户看到成功消息
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _showSuccessAndNavigate();
            }
          });
        }
      } else {
        debugPrint("用户取消了目录选择");
        setState(() {
          _resultText = "未选择目录";
          _detailText = "用户取消了目录选择，请重试";
        });
      }
    } catch (e) {
      debugPrint("手动选择Windows目录时发生错误: $e");
      setState(() {
        _resultText = "选择目录时出错";
        _detailText = "错误信息: $e\n\n请重试";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Windows平台说明
  Widget _buildWindowsInstructions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.green.shade900 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDarkMode ? Colors.green.shade700 : Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Windows平台说明:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "应用会自动查找位于 %APPDATA%\\ETS 的目录。\n\n"
            "如果自动查找失败，您可以：\n"
            "1. 确认已安装ETS软件\n"
            "2. 点击下方按钮手动选择ETS目录\n"
            "3. 正确的ETS目录中应包含数字命名的试题文件夹",
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
