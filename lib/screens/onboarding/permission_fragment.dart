import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:eauxiliary/screens/onboarding/onboarding_screen.dart';

class PermissionFragment extends StatefulWidget {
  const PermissionFragment({super.key});

  @override
  _PermissionFragmentState createState() => _PermissionFragmentState();
}

class _PermissionFragmentState extends State<PermissionFragment>
    with SingleTickerProviderStateMixin {
  String _welcomeText = "我们需要文件访问权限来帮助您管理答案";
  String _detailText = "点击下方按钮开始授权";
  bool _isProcessing = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _requestAllFilesAccessPermission() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _welcomeText = "正在请求权限...";
      _detailText = "请在系统新页面中授予权限";
    });

    try {
      // 使用 manageExternalStorage 权限
      final status = await Permission.manageExternalStorage.request();
      debugPrint("权限状态: $status");

      if (!mounted) return; // 检查 mounted 状态

      if (status.isGranted) {
        setState(() {
          _welcomeText = "做的不错";
          _detailText = "权限已获得，即将进入下一步";
        });
        _showPermissionGrantedAndAllowNavigation();
      } else if (status.isPermanentlyDenied) {
        // 用户永久拒绝，显示对话框引导用户去设置
        setState(() {
          _isProcessing = false;
          _welcomeText = "权限获取失败";
          _detailText = "请前往系统设置中手动授予所有文件访问权限";
        });
        _showPermissionDeniedDialog();
      } else {
        // 其他情况，如 denied
        setState(() {
          _isProcessing = false;
          _welcomeText = "权限获取失败";
          _detailText = "请重新尝试或手动在系统设置中授予权限";
        });
      }
    } catch (e) {
      debugPrint("权限请求错误: $e");
      setState(() {
        _isProcessing = false;
        _welcomeText = "发生错误";
        _detailText = "请重新尝试授权";
      });
    }
  }

  void _showPermissionGrantedAndAllowNavigation() {
    if (!mounted) return;

    // 使用动画控制器重置并播放新的动画
    _animController.reset();
    _animController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _navigateToNextStep();
      });
    });
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("权限被拒绝"),
          content: const Text("您需要授予所有文件访问权限才能使用此功能。请前往应用设置开启权限。"),
          actions: <Widget>[
            TextButton(
              child: const Text("前往设置"),
              onPressed: () {
                Navigator.of(context).pop(); // 先关闭对话框
                openAppSettings(); // 打开应用设置
              },
            ),
            TextButton(
              child: const Text("取消"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToNextStep() {
    if (!mounted) return;

    try {
      final state =
          (context.findAncestorStateOfType<State<OnboardingScreen>>());
      if (state != null) {
        (state as dynamic).nextPage();
      }
    } catch (e) {
      debugPrint("导航错误: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 图标容器
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
                    Icons.folder_open,
                    size: 60,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 40),

                // 主标题
                Text(
                  _welcomeText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // 详细说明
                Text(
                  _detailText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // 权限按钮
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _isProcessing ? null : _requestAllFilesAccessPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDarkMode ? Colors.white70 : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "处理中...",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.white,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            "授权",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
