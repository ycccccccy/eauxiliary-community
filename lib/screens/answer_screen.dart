import 'package:eauxiliary/providers/answer_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eauxiliary/widgets/loading_indicator.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class AnswerScreen extends StatefulWidget {
  final String answers;
  final String title;
  final Rect cardRect;

  const AnswerScreen({
    super.key,
    required this.answers,
    required this.title,
    required this.cardRect,
  });

  @override
  _AnswerScreenState createState() => _AnswerScreenState();
}

class _AnswerScreenState extends State<AnswerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  // 保存所有答案
  List<Map<String, dynamic>> _allAnswers = [];
  // 截图控制器
  final ScreenshotController _screenshotController = ScreenshotController();
  // 加载状态
  bool _isGeneratingImage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

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

    // 延迟一帧启动动画，避免加载卡顿
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });

    // 添加调试日志，检查传入的答案内容
    debugPrint("AnswerScreen: 初始化，答案长度: ${widget.answers.length}");
    debugPrint(
        "AnswerScreen: 答案前100个字符: ${widget.answers.substring(0, widget.answers.length > 100 ? 100 : widget.answers.length)}");

    // 解析所有答案
    if (widget.answers.isNotEmpty) {
      _allAnswers = _formatAllAnswerText(widget.answers);
      debugPrint("AnswerScreen: 格式化后的答案数量: ${_allAnswers.length}");
    } else {
      debugPrint("AnswerScreen: 答案为空，无法格式化");
    }

    // 移除单答案模式相关初始化
  }

  Future<void> _precacheQrCode() async {
    final imageProvider = const AssetImage('assets/images/qrcode.png');
    await precacheImage(imageProvider, context);
    debugPrint("AnswerScreen: 二维码图片预缓存完成");
  }

  bool _didPrecacheQrCode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didPrecacheQrCode) {
      _precacheQrCode();
      _didPrecacheQrCode = true;
    }
  }

  Future<bool> _onWillPop() async {
    await _controller.reverse();
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF2196F3);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDarkMode ? Colors.white : Colors.black87,
              size: 20,
            ),
            onPressed: _navigateBack,
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: isWideScreen, // 宽屏时居中，窄屏时左对齐
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // 只保留分享按钮
            IconButton(
              icon: _isGeneratingImage
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.white : primaryColor),
                      ))
                  : Icon(
                      Icons.share,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      size: 20,
                    ),
              onPressed: _isGeneratingImage ? null : _generateAndShareImage,
              tooltip: '保存并分享答案图片',
            ),
          ],
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
            child: Screenshot(
              controller: _screenshotController,
              child: Container(
                color: isDarkMode ? Colors.black : Colors.white,
                child: Column(
                  children: [
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          primaryColor),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '加载答案中...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildFormattedText(context),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // 获取可以显示的答案（不包括模仿朗读）
  List<Map<String, dynamic>> _getDisplayableAnswers(
      List<Map<String, dynamic>> allAnswers) {
    // 过滤掉模仿朗读相关内容
    final filteredAnswers = allAnswers
        .where((item) =>
            item['type'] != 'mimicry' &&
            item['type'] != 'mimicry_title' &&
            !(item['content'] as String).contains('【模仿朗读】'))
        .toList();

    debugPrint("AnswerScreen: 过滤掉模仿朗读后答案总数量: ${filteredAnswers.length}");

    // 直接返回过滤后的结果
    return filteredAnswers;
  }

  Widget _buildFormattedText(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF2196F3); // 使用清新的蓝色

    try {
      return Consumer<AnswerProvider>(
        builder: (context, answerProvider, child) {
          debugPrint(
              "AnswerScreen: Consumer重建，Provider答案长度: ${answerProvider.currentAnswers.length}");
          debugPrint("AnswerScreen: Widget答案长度: ${widget.answers.length}");

          if (answerProvider.isLoading) {
            return const LoadingIndicator(
              message: "答案加载中...",
              color: primaryColor,
            );
          }

          // 优先使用widget.answers，如果为空再使用provider的答案
          final String answerText = widget.answers.isNotEmpty
              ? widget.answers
              : answerProvider.currentAnswers;

          debugPrint("AnswerScreen: 最终使用的答案长度: ${answerText.length}");

          if (answerText.isNotEmpty) {
            // 如果_allAnswers为空，重新格式化
            if (_allAnswers.isEmpty) {
              _allAnswers = _formatAllAnswerText(answerText);
              debugPrint("AnswerScreen: 重新格式化后的答案数量: ${_allAnswers.length}");
            }

            // 使用_allAnswers中的可显示答案
            final displayedAnswers = _getDisplayableAnswers(_allAnswers);
            debugPrint("AnswerScreen: 可显示答案数量: ${displayedAnswers.length}");

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: displayedAnswers.isEmpty
                    ? Column(
                        children: [
                          Text(
                            '答案解析错误',
                            style: TextStyle(
                              fontSize: 18.0,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              answerText.substring(
                                  0,
                                  answerText.length > 500
                                      ? 500
                                      : answerText.length),
                              style: TextStyle(
                                fontSize: 14.0,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _formatAnswerContent(
                        displayedAnswers, isDarkMode, primaryColor),
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: isDarkMode ? Colors.white38 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '答案为空',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint("AnswerScreen: SettingsProvider错误: $e");
      // 如果Provider不可用，返回一个使用默认设置的版本
      return Consumer<AnswerProvider>(
        builder: (context, answerProvider, child) {
          if (answerProvider.isLoading) {
            return const LoadingIndicator(
              message: "答案加载中...",
              color: primaryColor,
            );
          }

          final String answerText = widget.answers.isNotEmpty
              ? widget.answers
              : answerProvider.currentAnswers;

          if (answerText.isNotEmpty) {
            if (_allAnswers.isEmpty) {
              _allAnswers = _formatAllAnswerText(answerText);
            }

            final displayedAnswers = _getDisplayableAnswers(_allAnswers);

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: displayedAnswers.isEmpty
                    ? Center(
                        child: Text(
                          '答案解析错误',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : _formatAnswerContent(
                        displayedAnswers, isDarkMode, primaryColor),
              ),
            );
          } else {
            return Center(
              child: Text(
                '没有可显示的答案',
                style: TextStyle(
                  fontSize: 16.0,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            );
          }
        },
      );
    }
  }

  // 为截屏构建格式化文本，避免Provider依赖
  Widget _buildScreenshotFormattedText(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF2196F3);

    // 直接使用widget.answers，不依赖Provider
    final String answerText = widget.answers.isNotEmpty ? widget.answers : "";

    if (answerText.isEmpty) {
      return Center(
        child: Text(
          '没有可显示的答案',
          style: TextStyle(
            fontSize: 16.0,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      );
    }

    // 直接格式化答案，不使用Consumer
    if (_allAnswers.isEmpty) {
      _allAnswers = _formatAllAnswerText(answerText);
    }

    final displayedAnswers = _getDisplayableAnswers(_allAnswers);

    // 截屏时不需要滚动容器，直接返回内容
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 16.0,
      ),
      child: displayedAnswers.isEmpty
          ? Center(
              child: Text(
                '答案解析错误',
                style: TextStyle(
                  fontSize: 18.0,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : _formatAnswerContent(displayedAnswers, isDarkMode, primaryColor),
    );
  }

  // 生成并分享图片
  Future<void> _generateAndShareImage() async {
    if (_isGeneratingImage) return;

    setState(() {
      _isGeneratingImage = true;
    });

    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      // 为截屏创建独立的内容，避免Provider依赖
      final screenshotFormattedText = _buildScreenshotFormattedText(context);

      final screenshotContent = await _buildScreenshotContent(
        context,
        widget.title,
        screenshotFormattedText,
        isDarkMode,
      );

      // 使用 captureFromLongWidget 来处理长截图
      // 为截屏提供完整的Widget层级结构，包括所有必要的inherited widgets
      final mediaQuery = MediaQuery.of(context);
      final screenshotWidget = MediaQuery(
        data: mediaQuery,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: mediaQuery.size.width,
              ),
              child: screenshotContent,
            ),
          ),
        ),
      );

      final Uint8List? imageBytes =
          await _screenshotController.captureFromLongWidget(
        screenshotWidget,
        delay: const Duration(milliseconds: 300),
        pixelRatio: MediaQuery.of(context).devicePixelRatio * 1.5,
      );

      if (imageBytes == null) {
        throw Exception("截图失败，无法生成图片。");
      }

      // 根据平台保存图片
      if (Platform.isAndroid) {
        try {
          await Gal.putImageBytes(imageBytes,
              name:
                  'Eauxiliary-Answer-${DateTime.now().millisecondsSinceEpoch}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('图片已保存到相册')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('图片保存失败')),
            );
          }
        }
      } else if (Platform.isWindows) {
        final downloadsDirectory = await getDownloadsDirectory();
        if (downloadsDirectory != null) {
          final imagePath =
              '${downloadsDirectory.path}/Eauxiliary-Answer-${DateTime.now().millisecondsSinceEpoch}.png';
          await File(imagePath).writeAsBytes(imageBytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('图片已保存到下载目录: $imagePath')),
            );
          }
        }
      } else {
        // 对于其他平台，可以保留分享或只提示不支持
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('当前平台不支持直接保存图片')),
          );
        }
      }
    } catch (e) {
      debugPrint("截图或分享时出错: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成分享图片时出错: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingImage = false;
        });
      }
    }
  }

  // 构建用于截图的内容
  Future<Widget> _buildScreenshotContent(BuildContext context, String title,
      Widget formattedText, bool isDarkMode) async {
    final footer = await _buildFooter(isDarkMode);

    // 返回一个包含所有需要截图内容的Column
    // 这里的内容应该与屏幕上显示的内容完全一致
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min, // 确保Column包裹内容
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              title,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 答案内容
          formattedText,
          // 页脚
          footer,
        ],
      ),
    );
  }

  // 格式化所有答案文本
  List<Map<String, dynamic>> _formatAllAnswerText(String text) {
    final List<Map<String, dynamic>> formattedText = [];
    final RegExp titleRegExp = RegExp(r'【.+?】');
    final RegExp dividerRegExp = RegExp(r'-{5,}');
    final RegExp mimicryRegExp = RegExp(r'【模仿朗读】', caseSensitive: false);

    final lines = text.split('\n');
    StringBuffer currentText = StringBuffer();
    String currentType = 'text';
    bool isMimicry = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // 检测是否是模仿朗读
      if (mimicryRegExp.hasMatch(line)) {
        isMimicry = true;
      }

      if (titleRegExp.hasMatch(line)) {
        if (currentText.isNotEmpty) {
          formattedText.add({
            'type': isMimicry ? 'mimicry' : currentType,
            'content': currentText.toString().trim(),
          });
          currentText.clear();
          isMimicry = false;
        }

        // 检查新标题是否是模仿朗读
        isMimicry = mimicryRegExp.hasMatch(line);

        formattedText.add({
          'type': isMimicry ? 'mimicry_title' : 'title',
          'content': line,
        });
        currentType = 'text';
      } else if (dividerRegExp.hasMatch(line)) {
        if (currentText.isNotEmpty) {
          formattedText.add({
            'type': isMimicry ? 'mimicry' : currentType,
            'content': currentText.toString().trim(),
          });
          currentText.clear();
        }

        formattedText.add({
          'type': 'divider',
          'content': '',
        });
        currentType = 'text';
      } else if (line.isNotEmpty) {
        if (RegExp(r'^\d+\.\s').hasMatch(line) && currentText.isEmpty) {
          currentType = 'answer';
        }

        if (currentText.isNotEmpty) {
          currentText.write('\n');
        }
        currentText.write(line);
      }
    }

    if (currentText.isNotEmpty) {
      formattedText.add({
        'type': isMimicry ? 'mimicry' : currentType,
        'content': currentText.toString().trim(),
      });
    }

    return formattedText;
  }

  // 格式化答案内容为Widget
  Widget _formatAnswerContent(List<Map<String, dynamic>> formattedText,
      bool isDarkMode, Color primaryColor) {
    final List<Widget> widgets = [];

    for (int i = 0; i < formattedText.length; i++) {
      var item = formattedText[i];

      switch (item['type']) {
        case 'title':
          widgets.add(
            Container(
              margin: const EdgeInsets.only(top: 16.0, bottom: 12.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey.shade800
                      : const Color(0xFFDDEEFF),
                  width: 1.0,
                ),
                boxShadow: isDarkMode
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                item['content'],
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                  height: 1.3,
                ),
              ),
            ),
          );
          break;
        case 'answer':
          // 检查内容是否包含<br>标签，用于处理听选信息
          if (item['content'].contains('<br>')) {
            // 分割问题和选项
            final parts = item['content'].split('<br>');
            final question = parts[0].trim();
            final options = parts
                .sublist(1)
                .map((option) => option.trim())
                .where((option) => option.isNotEmpty)
                .toList();

            // 创建问题卡片
            widgets.add(
              Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : const Color(0xFFDDEEFF),
                    width: 1.0,
                  ),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: SelectableText(
                  question,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            );

            // 如果有选项，创建选项卡片
            if (options.isNotEmpty) {
              widgets.add(
                Container(
                  margin:
                      const EdgeInsets.only(bottom: 16.0, top: 4.0, left: 16.0),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : const Color(0xFFDDEEFF),
                      width: 1.0,
                    ),
                    boxShadow: isDarkMode
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: options
                        .map((option) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: SelectableText(
                                option,
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              );
            }
          } else {
            // 原始的内容处理方式
            widgets.add(
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : const Color(0xFFDDEEFF),
                    width: 1.0,
                  ),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: SelectableText(
                  item['content'],
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            );
          }
          break;
        case 'divider':
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.1),
                            primaryColor.withOpacity(0.3),
                            primaryColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;
        case 'text':
        default:
          // 检查内容是否包含<br>标签，用于处理听选信息
          if (item['content'].contains('<br>')) {
            // 分割问题和选项
            final parts = item['content'].split('<br>');
            final question = parts[0].trim();
            final options = parts
                .sublist(1)
                .map((option) => option.trim())
                .where((option) => option.isNotEmpty)
                .toList();

            // 创建问题卡片
            widgets.add(
              Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : const Color(0xFFDDEEFF),
                    width: 1.0,
                  ),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: SelectableText(
                  question,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            );

            // 如果有选项，创建选项卡片
            if (options.isNotEmpty) {
              widgets.add(
                Container(
                  margin:
                      const EdgeInsets.only(bottom: 16.0, top: 4.0, left: 16.0),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : const Color(0xFFDDEEFF),
                      width: 1.0,
                    ),
                    boxShadow: isDarkMode
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: options
                        .map((option) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: SelectableText(
                                option,
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              );
            }
          } else {
            // 原始的内容处理方式
            widgets.add(
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : const Color(0xFFDDEEFF),
                    width: 1.0,
                  ),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: SelectableText(
                  item['content'],
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            );
          }
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  // 构建页脚
  Future<Widget> _buildFooter(bool isDarkMode) async {
    // 加载二维码图片
    final imageProvider = const AssetImage('assets/images/qrcode.png');

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '此答案由 Eauxiliary 创建',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '扫描右侧二维码访问网站',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image(
              image: imageProvider,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
