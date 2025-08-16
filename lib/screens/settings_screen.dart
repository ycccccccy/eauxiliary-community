// ignore_for_file: unused_field

import 'package:eauxiliary/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eauxiliary/providers/answer_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:eauxiliary/services/file_service.dart';
import 'package:eauxiliary/utils/page_transition.dart';
import 'package:eauxiliary/screens/eula_screen.dart';
import 'package:eauxiliary/screens/onboarding/onboarding_screen.dart';
import 'package:eauxiliary/utils/first_run_check.dart';
import 'package:eauxiliary/providers/settings_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  String _version = '';
  bool _isLoading = false;
  bool _isNavigating = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // 添加Shizuku模式状态
  bool _useShizuku = FileService.useShizuku;
  bool _isShizukuLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.2, 0.0, 0.0, 1.0),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  // GitHub相关链接方法
  void _openGitHub() {
    _launchURL('https://github.com/ycccccccy/eauxiliary-community');
  }

  void _openGitHubIssues() {
    _launchURL('https://github.com/ycccccccy/eauxiliary-community/issues/new');
  }

  void _openGitHubDiscussions() {
    _launchURL('https://github.com/ycccccccy/eauxiliary-community/discussions');
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('无法打开链接: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开链接时出错: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 使用AnswerProvider的方法来清除缓存
      await context.read<AnswerProvider>().clearAnswerCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text('缓存已清除'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("SettingsScreen: 清除缓存时出错: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '清除缓存失败: ${e.toString()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 切换Shizuku模式
  Future<void> _toggleShizukuMode(bool value) async {
    setState(() {
      _isShizukuLoading = true;
    });

    try {
      final success = await FileService.setUseShizuku(value);
      if (success) {
        setState(() {
          _useShizuku = value;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value ? '已启用Shizuku模式，可以访问更多文件' : '已禁用Shizuku模式'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法切换Shizuku模式，请确保已安装Shizuku应用'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('切换Shizuku模式时出错: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isShizukuLoading = false;
        });
      }
    }
  }

  // 显示撤回隐私协议确认对话框
  Future<void> _showRevokePrivacyConfirmation() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('撤回隐私协议同意'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('此操作将撤回您的隐私协议同意，应用将返回到首次启动状态。'),
                SizedBox(height: 8),
                Text('您的数据不会被删除，但您需要重新同意隐私协议才能继续使用应用。'),
                SizedBox(height: 8),
                Text('确定要继续吗？', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '取消',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '确认撤回',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _revokePrivacyConsent();
              },
            ),
          ],
        );
      },
    );
  }

  // 撤回隐私协议同意
  Future<void> _revokePrivacyConsent() async {
    if (_isLoading || _isNavigating) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 执行撤回操作
      final provider = Provider.of<AnswerProvider>(context, listen: false);
      final success = await provider.revokePrivacyConsent();

      if (!mounted) return;

      if (success) {
        setState(() {
          _isLoading = false;
          _isNavigating = true;
        });

        // 重置首次运行状态
        await FirstRunCheck.setFirstRun();

        if (!mounted) return;

        // 导航回引导页面
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition.welcomeToEula(page: const OnboardingScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        // 显示错误提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('撤回隐私协议同意失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('撤回隐私协议同意错误: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发生错误: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final List<Widget> settingItems = [
      _buildSection(
        '基本设置',
        [
          _SettingsCard(
            child: Column(
              children: [
                _SettingsItem(
                  title: '深色模式',
                  subtitle: settingsProvider.useSystemTheme ? '跟随系统' : '手动设置',
                  trailing: _CustomSwitch(
                    value: settingsProvider.isDarkMode,
                    onChanged: settingsProvider.useSystemTheme
                        ? null
                        : (value) => settingsProvider.setDarkMode(value),
                  ),
                ),
                _SettingsItem(
                  title: '跟随系统主题',
                  subtitle: '根据系统设置自动切换亮暗模式',
                  trailing: _CustomSwitch(
                    value: settingsProvider.useSystemTheme,
                    onChanged: (value) =>
                        settingsProvider.setUseSystemTheme(value),
                  ),
                ),
                _SettingsItem(
                  title: '自动检查更新',
                  subtitle: '有新版本时提醒',
                  trailing: _CustomSwitch(
                    value: settingsProvider.autoCheckUpdate,
                    onChanged: (value) {
                      settingsProvider.setAutoCheckUpdate(value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value ? '已开启自动检查更新' : '已关闭自动检查更新'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      _buildSection(
        '存储',
        [
          _SettingsCard(
            child: _SettingsItem(
              title: '清除缓存',
              subtitle: '清除所有已缓存的答案',
              onTap: _clearCache,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
      _buildSection(
        '文件访问',
        [
          _SettingsCard(
            child: _SettingsItem(
              title: '使用Shizuku模式',
              subtitle: '需要安装Shizuku应用',
              trailing: _CustomSwitch(
                value: _useShizuku,
                onChanged: _isShizukuLoading ? null : _toggleShizukuMode,
              ),
            ),
          ),
        ],
      ),
      _buildSection(
        '隐私与权限',
        [
          _SettingsCard(
            child: Column(
              children: [
                _SettingsItem(
                  title: '隐私政策',
                  subtitle: '查看应用的隐私政策',
                  icon: Icons.privacy_tip,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition.slide(
                        page: const EulaScreen(source: 'about'),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  title: '撤回隐私协议同意',
                  subtitle: '撤回同意并返回到首次运行状态',
                  icon: Icons.gpp_bad,
                  isWarning: true,
                  onTap: _showRevokePrivacyConfirmation,
                ),
              ],
            ),
          ),
        ],
      ),
      _buildSection(
        '关于',
        [
          _SettingsCard(
            child: Column(
              children: [
                _SettingsItem(
                  title: '版本信息',
                  subtitle: 'Eauxiliary 社区版 v$_version',
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition.slide(
                        page: const AboutScreen(),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  title: 'GitHub 仓库',
                  subtitle: '查看源代码和贡献指南',
                  onTap: () => _openGitHub(),
                ),
                _SettingsItem(
                  title: '问题反馈',
                  subtitle: '报告Bug或提出建议',
                  onTap: () => _openGitHubIssues(),
                ),
                _SettingsItem(
                  title: '社区讨论',
                  subtitle: '加入开发者社区',
                  onTap: () => _openGitHubDiscussions(),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_isNavigating) return false;
        _isNavigating = true;
        return true;
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FC),
        appBar: AppBar(
          title:
              const Text('设置', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor:
              isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FC),
          foregroundColor: isDark ? Colors.white : Colors.black,
        ),
        body: SafeArea(
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const ClampingScrollPhysics(),
              itemCount: settingItems.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: settingItems[index],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Builder(builder: (context) {
            return Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            );
          }),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Colors.grey.withOpacity(0.15);

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
      child: child,
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  final bool isWarning;

  const _SettingsItem({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final Color effectiveColor =
        isWarning ? Colors.red.shade400 : theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: effectiveColor.withOpacity(0.1),
        highlightColor: effectiveColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: effectiveColor, size: 24),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isWarning
                            ? effectiveColor
                            : (isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _CustomSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: primaryColor,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor:
          isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
      trackOutlineColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (!isDarkMode) {
          // This will remove the border in light mode
          return Colors.transparent;
        }
        return null; // Use default for dark mode
      }),
    );
  }
}
