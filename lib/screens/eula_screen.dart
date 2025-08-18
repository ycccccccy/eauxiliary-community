//eula_screen.dart
import 'package:eauxiliary/providers/answer_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class EulaScreen extends StatefulWidget {
  final String source;
  final bool canReturnToMain;

  const EulaScreen({
    super.key,
    required this.source,
    this.canReturnToMain = true,
  });

  @override
  _EulaScreenState createState() => _EulaScreenState();
}

class _EulaScreenState extends State<EulaScreen> with SingleTickerProviderStateMixin {
  bool _hasRead = false;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _reachedBottom = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.2, 0.0, 0.0, 1.0),
    ));

    _controller.forward();
    
    // 添加滚动监听
    _scrollController.addListener(_onScroll);

    // 检查是否已阅读过隐私政策
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AnswerProvider>(context, listen: false);
      setState(() {
        _hasRead = provider.hasReadPrivacyPolicy;
      });
    });
  }

  void _onScroll() {
    // 检查是否滚动到底部
    if (_scrollController.hasClients && 
        _scrollController.offset >= _scrollController.position.maxScrollExtent - 100 &&
        !_reachedBottom) {
      setState(() {
        _reachedBottom = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final surfaceColor = isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    return WillPopScope(
      onWillPop: () async {
        return _handleBackAction();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            '隐私政策',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _handleBackAction();
            },
          ),
        ),
        body: AnimatedBuilder(
          animation: _controller,
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
          child: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // 标题和介绍
                      Text(
                        '隐私政策',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '最后更新日期：2025年3月15日',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '感谢你使用我们的应用。本隐私政策旨在告知您我们如何收集、使用和保护你的个人信息。',
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                      _buildDivider(),
                      
                      // 内容部分
                      _buildSectionTitle('我们收集的信息', textColor),
                      _buildParagraph(
                        '我们会收集以下类型的信息：\n\n'
                        '• 设备信息：我们收集你的设备类型、操作系统版本和设备标识符，以便为你提供更好的服务和解决可能出现的技术问题。\n\n'
                        '• 使用信息：我们会收集你如何使用我们的应用程序的信息，例如你访问的功能、你的互动以及你在应用程序中的设置偏好。',
                        subtitleColor,
                      ),
                      
                      _buildDivider(),
                      _buildSectionTitle('我们如何使用信息', textColor),
                      _buildParagraph(
                        '我们使用收集到的信息来：\n\n'
                        '• 提供、维护和改进我们的服务\n'
                        '• 响应你的请求和查询\n'
                        '• 发送服务相关通知\n'
                        '• 分析使用模式以改进用户体验\n'
                        '• 调查并解决技术问题',
                        subtitleColor,
                      ),
                      
                      _buildDivider(),
                      _buildSectionTitle('信息的共享和披露', textColor),
                      _buildParagraph(
                        '我们不会出售你的个人信息。我们可能在以下情况下共享信息：\n\n'
                        '• 经你同意\n'
                        '• 与我们的服务提供商共享，他们帮助我们提供服务\n'
                        '• 出于法律原因，如遵守法律义务或保护我们的权利',
                        subtitleColor,
                      ),
                      
                      _buildDivider(),
                      _buildSectionTitle('数据存储', textColor),
                      _buildParagraph(
                        '我们在设备本地存储的所有数据仅用于应用功能，不会上传至任何服务器。你可以随时通过设备设置或应用内选项删除这些数据。',
                        subtitleColor,
                      ),
                      
                      _buildDivider(),
                      _buildSectionTitle('你的权利', textColor),
                      _buildParagraph(
                        '你有权：\n\n'
                        '• 访问你的个人信息\n'
                        '• 更正不准确的信息\n'
                        '• 删除你的信息\n'
                        '• 撤回你的同意\n\n'
                        '如需行使这些权利，请通过应用中的设置或联系我们。',
                        subtitleColor,
                      ),
                      
                      _buildDivider(),
                      _buildSectionTitle('政策更改', textColor),
                      _buildParagraph(
                        '我们可能会不时更新本隐私政策。更新后的政策将在应用内公布，并标明更新日期。',
                        subtitleColor,
                      ),
                      
                      _buildDivider(),
                      _buildSectionTitle('联系我们', textColor),
                      _buildParagraph(
                        '如果你对本隐私政策有任何疑问，请联系我们：\n\nyccccccy@proton.me',
                        subtitleColor,
                      ),
                      const SizedBox(height: 100), // 底部间距
                    ],
                  ),
                ),
                // 底部操作栏
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _reachedBottom ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black38
                                : Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _reachedBottom ? () {
                              setState(() {
                                _hasRead = !_hasRead;
                              });
                            } : null,
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _hasRead 
                                          ? primaryColor 
                                          : isDarkMode 
                                              ? Colors.white54 
                                              : Colors.black38,
                                      width: 1.5,
                                    ),
                                    color: _hasRead 
                                        ? primaryColor
                                        : Colors.transparent,
                                  ),
                                  child: _hasRead 
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '我已阅读并同意隐私政策',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _isLoading
                              ? SizedBox(
                                  width: 100,
                                  height: 44,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 44,
                                  width: 100,
                                  child: ElevatedButton(
                                    onPressed: (_hasRead && _reachedBottom) ? _onAgree : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      disabledBackgroundColor: 
                                          isDarkMode 
                                              ? Colors.grey[800] 
                                              : Colors.grey[300],
                                      disabledForegroundColor: 
                                          isDarkMode 
                                              ? Colors.grey[700] 
                                              : Colors.grey[400],
                                    ),
                                    child: const Text(
                                      '确认',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 如果未到底部，显示提示
                if (!_reachedBottom)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: subtitleColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '请滚动至底部以便完成阅读',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
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

  Widget _buildDivider() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Divider(
        color: isDarkMode ? Colors.white12 : Colors.black12,
        height: 1,
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildParagraph(String content, Color textColor) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: textColor,
      ),
    );
  }

  Future<void> _onAgree() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 保存用户的同意状态
      final provider = Provider.of<AnswerProvider>(context, listen: false);
      await provider.setPrivacyPolicyRead(true);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 返回到上一页面，并传递已同意状态
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发生错误: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 处理返回按钮逻辑
  bool _handleBackAction() {
    // 无论什么情况下，从引导流程打开的都直接返回上一级
    if (widget.source == 'OnboardingActivity') {
      Navigator.pop(context, _hasRead);
      return false;
    }
    
    // 其他情况下，如果已同意或者允许返回主页，直接返回
    if (_hasRead || widget.canReturnToMain) {
      Navigator.pop(context, _hasRead);
      return false;
    } else {
      // 显示对话框提示用户必须同意才能使用应用
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('警告'),
          content: const Text('您必须先同意隐私政策才能使用本应用。如果不同意，应用将退出。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回阅读'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 关闭对话框
                Navigator.pop(context, false); // 返回上一页，并传递未同意状态
              },
              child: const Text('退出应用'),
            ),
          ],
        ),
      );
      return false;
    }
  }
}