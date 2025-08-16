import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WelcomeFragment extends StatefulWidget {
  final VoidCallback onContinue;
  final bool isButtonAnimating;

  const WelcomeFragment({
    super.key,
    required this.onContinue,
    this.isButtonAnimating = false,
  });

  @override
  State<WelcomeFragment> createState() => _WelcomeFragmentState();
}

class _WelcomeFragmentState extends State<WelcomeFragment> with SingleTickerProviderStateMixin {
  String _version = '';
  late AnimationController _buttonController;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();
    _getVersion();
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _contentFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    ));
  }

  @override
  void didUpdateWidget(WelcomeFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isButtonAnimating && !oldWidget.isButtonAnimating) {
      _buttonController.forward();
    } else if (!widget.isButtonAnimating && oldWidget.isButtonAnimating) {
      _buttonController.reverse();
    }
  }

  Future<void> _getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = packageInfo.version;
      });
    }
  }

  void _handleContinue() {
    widget.onContinue();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF2196F3);
    final size = MediaQuery.of(context).size;
    
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _contentFadeAnimation,
          child: child,
        );
      },
      child: SizedBox(
        width: size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // 应用图标
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
              child: Center(
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 75,
                  height: 75,
                ),
              ),
            ),
            const SizedBox(height: 50),
            
            // 欢迎标题
            Text(
              'EAuxiliary',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            
            // 欢迎信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '让获取E听说答案不再成为问题',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white60 : Colors.black45,
                  height: 1.8,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const Spacer(flex: 2),
            
            // 继续按钮
            Container(
              width: size.width * 0.85,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '开始使用',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 版本信息
            Text(
              '版本 $_version',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
} 