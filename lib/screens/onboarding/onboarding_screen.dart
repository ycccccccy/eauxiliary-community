import 'package:eauxiliary/screens/onboarding/directory_fragment.dart';
import 'package:eauxiliary/screens/onboarding/permission_fragment.dart';
import 'package:eauxiliary/screens/onboarding/welcome_fragment.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eauxiliary/providers/answer_provider.dart';
import 'package:eauxiliary/screens/eula_screen.dart';
import 'package:flutter/services.dart';
import 'package:eauxiliary/utils/page_transition.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  bool _hasError = false;
  String _errorMessage = '';
  bool _isNavigating = false;
  bool _showWelcome = true; // 控制是否显示欢迎页面
  bool _isButtonAnimating = false; // 控制按钮动画状态

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _animController.forward();

    // 添加初始化后的检查
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEulaStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // 从欢迎页面继续到隐私协议
  Future<void> _continueToEula() async {
    if (!mounted || _isNavigating || _isButtonAnimating) return;

    try {
      setState(() {
        _isNavigating = true;
        _isButtonAnimating = true;
      });

      // 等待按钮动画执行 (这里的时间必须与welcomeFragment中的按钮动画时长协调)
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      // 使用高级过渡动画导航到隐私协议页面
      // ignore: unused_local_variable
      final result = await Navigator.of(context).push<bool>(
        PageTransition.welcomeToEula(
          page: const EulaScreen(
            source: 'OnboardingActivity',
            canReturnToMain: false, // 不允许直接返回主页
          ),
        ),
      );

      // 检查是否同意了隐私协议
      if (mounted) {
        setState(() {
          _isNavigating = false;
          _isButtonAnimating = false;
        });

        final provider = Provider.of<AnswerProvider>(context, listen: false);
        final hasReadAfterReturn = provider.hasReadPrivacyPolicy;

        if (!hasReadAfterReturn) {
          // 如果用户未同意隐私协议，则退出应用
          debugPrint("OnboardingScreen: 用户未同意隐私协议，退出应用");
          await Future.delayed(const Duration(milliseconds: 100));
          SystemNavigator.pop(); // 退出应用
          return;
        }

        // 隐私协议已同意，切换到权限页面
        setState(() {
          _showWelcome = false;
        });

        // 调用新的页面切换动画
        _animateToPermissionPage();

        debugPrint("OnboardingScreen: 从隐私协议页面返回，继续引导流程");
      }
    } catch (e) {
      debugPrint("OnboardingScreen: 导航到隐私协议页面时出错 $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '导航到隐私协议页面时出错，请重试';
          _isNavigating = false;
          _isButtonAnimating = false;
        });
      }
    }
  }

  // 动画切换到权限页面
  Future<void> _animateToPermissionPage() async {
    _animController.reset();
    await Future.delayed(const Duration(milliseconds: 100));
    _animController.forward();
  }

  Future<void> _checkEulaStatus() async {
    if (!mounted || _isNavigating) return;

    try {
      final provider = Provider.of<AnswerProvider>(context, listen: false);
      final hasRead = provider.hasReadPrivacyPolicy;

      if (hasRead) {
        // 如果已同意隐私协议，直接显示权限页面
        setState(() {
          _showWelcome = false;
        });
      }
    } catch (e) {
      debugPrint("OnboardingScreen: 检查隐私协议状态时出错 $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '检查隐私协议状态时出错，请重试';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 主内容
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: _showWelcome
                ? WelcomeFragment(
                    onContinue: _continueToEula,
                    isButtonAnimating: _isButtonAnimating,
                  )
                : PageView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _pageController,
                    children: const [
                      PermissionFragment(),
                      DirectoryFragment(),
                    ],
                  ),
          ),

          // 错误提示
          if (_hasError)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorMessage = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void nextPage() {
    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
