import 'dart:async';
import 'package:eauxiliary/models/folder_item.dart';
import 'package:eauxiliary/providers/answer_provider.dart';
import 'package:eauxiliary/screens/settings_screen.dart';
import 'package:eauxiliary/utils/page_transition.dart';
import 'package:eauxiliary/utils/responsive_wrapper.dart';
import 'package:eauxiliary/widgets/group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

/// Main Screen Widget
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// Main Screen State Management
class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // --- Animation Controllers ---
  late AnimationController _screenTransitionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 设置动画控制器
    _screenTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _screenTransitionController,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _screenTransitionController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _screenTransitionController,
        curve: Curves.easeOut,
      ),
    );

    // 启动动画
    _screenTransitionController.forward();

    // 将初始化逻辑移动到帧渲染后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  // 简化数据初始化，不再依赖JSON数据管理器
  void _initializeData() async {
    // 直接刷新文件夹列表
    if (mounted) {
      await _refreshData(force: true);
    }
  }

  @override
  void dispose() {
    _screenTransitionController.dispose();
    super.dispose();
  }

  // --- Helper Methods ---

  Future<void> _refreshData({bool force = false}) async {
    debugPrint("MainScreen: 开始刷新文件夹数据 (强制: $force)");
    if (!mounted) return;

    final answerProvider = Provider.of<AnswerProvider>(context, listen: false);

    // 初始加载或手动下拉刷新时，强制刷新
    await answerProvider.loadGroupedFolders(forceRefresh: force);

    // 如果文件夹列表仍然为空，尝试深度扫描
    if (answerProvider.groupedFolders.isEmpty && mounted) {
      debugPrint("MainScreen: 常规扫描无结果，尝试深度扫描");
      await answerProvider.loadGroupedFolders(
          forceRefresh: true, deepScan: true);
    }
  }

  // --- UI Build Methods ---
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final answerProvider = context.watch<AnswerProvider>();

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8F8F8),
      body: SafeArea(
        child: ResponsiveWrapper(
          maxWidth: 900,
          child: Column(
            children: [
              CustomHeader(
                isDarkMode: isDarkMode,
                onSettingsTap: () {
                  Navigator.push(
                    context,
                    PageTransition.slide(page: const SettingsScreen()),
                  );
                },
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _screenTransitionController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _buildBody(answerProvider, isDarkMode, primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建主页面内容，简化逻辑
  Widget _buildBody(
      AnswerProvider provider, bool isDarkMode, Color primaryColor) {
    // 1. 如果文件夹列表正在加载且为空，显示加载动画
    if (provider.isLoading && provider.groupedFolders.isEmpty) {
      return _buildLoadingShimmer(isDarkMode);
    }

    // 2. 如果加载完成但没有文件夹，显示空状态
    if (provider.groupedFolders.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    // 3. 否则显示文件夹列表
    return RefreshIndicator(
      onRefresh: () => _refreshData(force: true),
      child: _buildGroupedList(
        provider.groupedFolders,
        isDarkMode,
        primaryColor,
      ),
    );
  }

  // 移除JSON加载指示器，不再需要

  Widget _buildLoadingShimmer(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: 5, // Display 5 shimmer cards
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white, // This will be covered by shimmer
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 120.0, height: 16.0, color: Colors.white),
                  Container(width: 24.0, height: 24.0, color: Colors.white),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(width: 50.0, height: 14.0, color: Colors.white),
                  const SizedBox(width: 8),
                  Container(width: 80.0, height: 14.0, color: Colors.white),
                  const SizedBox(width: 12),
                  Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Container(width: 60.0, height: 14.0, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 80,
                color: isDarkMode ? Colors.white24 : Colors.black26,
              ),
              const SizedBox(height: 24),
              Text(
                '暂无内容',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  '我们正在尝试解析答案\n如果长时间未显示，请确保已下载试题\n或尝试下拉刷新。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList(
    List<({List<FolderItem> group, String tag})> groups,
    bool isDarkMode,
    Color primaryColor,
  ) {
    // 简化卡片构建，不再依赖JSON数据管理器
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final groupData = groups[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: GroupCard(
                  key: ValueKey(groupData.group.isNotEmpty
                      ? groupData.group.first.path
                      : index),
                  parentContext: context,
                  groupData: groupData,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CustomHeader extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onSettingsTap;

  const CustomHeader({
    super.key,
    required this.isDarkMode,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Eauxiliary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettingsTap,
            tooltip: '设置',
          ),
        ],
      ),
    );
  }
}
