import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.2, 0.0, 0.0, 1.0),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('使用教程与常见问题',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FC),
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child:
                    Transform.scale(scale: _scaleAnimation.value, child: child),
              ),
            );
          },
          child: AnimationLimiter(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: const [
                  _HelpSection(
                    title: '快速开始',
                    items: [
                      '安装并启动 Eauxiliary。',
                      '首次进入会显示引导页，按提示完成隐私协议确认。',
                      'Android：建议开启 Shizuku 模式以读取 ETS 目录；Windows：应用会自动定位 %APPDATA%/ETS。',
                      '返回主界面后，应用会自动扫描并展示最近的试题组。',
                    ],
                  ),
                  _HelpSection(
                    title: '路径初始化失败怎么办？',
                    items: [
                      '确认题库已正确下载并存在于设备上：Android 通常位于 /storage/emulated/0/Android/data/com.ets100.secondary/files/Download/ETS_SECONDARY/resource。',
                      'Android 13+ 无法直接访问外部存储：请在设置中启用 Shizuku 模式以提升访问权限。',
                      'Windows：确保 %APPDATA%/ETS 下的题库文件夹可被访问且包含 content.json。',
                      '仍为空？在主界面下拉刷新，或在设置中清除缓存后重试。',
                    ],
                  ),
                  _HelpSection(
                    title: '常见问题',
                    items: [
                      'Q: 没有任何内容显示？\nA: 先检查路径是否正确；Android 可开启 Shizuku，再下拉刷新。',
                      'Q: 为何只显示一个试题组？\nA: 社区版默认只展示最近的一个试题组。',
                      'Q: 如何再次查看本页面？\nA: 在设置页「帮助与支持」中进入。',
                      'Q: 如何保存答案图片？\nA: 在答案页右上角点击分享按钮，Android 保存到相册，Windows 保存到下载目录。',
                    ],
                  ),
                  _HelpSection(
                    title: '建议的目录结构（Android）',
                    items: [
                      '.../Android/data/com.ets100.secondary/files/Download/ETS_SECONDARY/resource/<题目ID>/content.json',
                      '若路径包含“Android”被分隔（A\u200Bndroid），应用会自动尝试修复。',
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final List<String> items;
  const _HelpSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final shadowColor =
        isDark ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.15);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...items.map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SelectableText(
                  t,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
