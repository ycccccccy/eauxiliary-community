import 'dart:async';
import 'dart:io';

import 'package:eauxiliary/models/folder_item.dart';
import 'package:eauxiliary/providers/answer_provider.dart';
import 'package:eauxiliary/screens/answer_screen.dart';
import 'package:eauxiliary/utils/helpers.dart';
import 'package:eauxiliary/utils/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- GroupCard Widget ---
/// 简化的试题组卡片组件
///
/// 专门用于显示深圳高中英语听说试题，不再支持复杂的名称匹配功能
class GroupCard extends StatefulWidget {
  final BuildContext parentContext;
  final ({List<FolderItem> group, String tag}) groupData;
  final bool isDarkMode;
  final Color primaryColor;

  const GroupCard({
    super.key,
    required this.parentContext,
    required this.groupData,
    required this.isDarkMode,
    required this.primaryColor,
  });

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  // --- UI State ---
  String _finalExamName = '';
  String? _determinedGradeId;
  String _relativeTime = '';
  bool _isTapped = false;

  // --- Status State ---
  Timer? _statusTimer;

  // --- Logic State ---
  late final String _fallbackExamCode;
  bool _nameFoundViaJson = false;

  @override
  void initState() {
    super.initState();
    _fallbackExamCode = _extractFallbackCode();
    // 直接使用简单的命名方式
    if (Platform.isWindows) {
      _finalExamName = '模拟试题$_fallbackExamCode';
    } else {
      _finalExamName = '模拟试题$_fallbackExamCode';
    }
    _updateRelativeTime();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _updateRelativeTime() {
    if (widget.groupData.group.isNotEmpty && mounted) {
      final folderItem = widget.groupData.group.first;
      final newTime = getRelativeTime(folderItem.lastModified);
      if (newTime != _relativeTime) {
        setState(() => _relativeTime = newTime);
      }
    }
  }

  String _extractFallbackCode() {
    if (widget.groupData.group.isNotEmpty) {
      final folderItem = widget.groupData.group.first;
      final fileName = folderItem.name.split(Platform.pathSeparator).last;

      // Windows端：从路径中提取纯数字标识
      if (Platform.isWindows) {
        // 查找路径中的纯数字标识
        final pathParts = folderItem.name.split(Platform.pathSeparator);
        for (final part in pathParts) {
          // 检查是否为纯数字（长度至少6位）
          if (RegExp(r'^\d{6,}$').hasMatch(part)) {
            return part;
          }
        }
        // 如果没有找到纯数字标识，使用文件名
        final parts = fileName.split('_');
        if (parts.isNotEmpty && parts.first.length >= 6) {
          return parts.first.substring(0, 6);
        }
      } else {
        // 非Windows端：保持原有逻辑
        final parts = fileName.split('_');
        if (parts.isNotEmpty && parts.first.length >= 6) {
          return parts.first.substring(0, 6);
        }
      }
    }
    return '000000';
  }

  String _formatGrade(String? gradeId) {
    if (gradeId == null) return '未知';
    const numberMap = {'1': '一', '2': '二', '3': '三'};
    final type = gradeId.startsWith('G') ? '高' : '初';
    final number = numberMap[gradeId.substring(1)] ?? '';
    return '$type$number';
  }

  void _navigateToAnswerScreen() async {
    // 检查是否为支持的题型
    if (widget.groupData.group.length != 3) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('社区版本仅支持深圳高中题型，当前题型不被支持'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final answerProvider =
        Provider.of<AnswerProvider>(widget.parentContext, listen: false);
    final fileGroup =
        widget.groupData.group.map((item) => File(item.path)).toList();

    await answerProvider.fetchAnswers(fileGroup);

    if (!widget.parentContext.mounted) return;

    final allAnswers = answerProvider.currentAnswers;
    if (allAnswers.isEmpty || allAnswers.startsWith('加载答案失败')) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text('无法加载答案: $allAnswers')),
      );
      return;
    }

    final cardRenderBox = context.findRenderObject() as RenderBox;
    final cardRect =
        cardRenderBox.localToGlobal(Offset.zero) & cardRenderBox.size;

    Navigator.of(widget.parentContext).push(
      PageTransition.scale(
        page: AnswerScreen(
          answers: allAnswers,
          title: _finalExamName,
          cardRect: cardRect,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) {
        setState(() => _isTapped = false);
        Future.delayed(
            const Duration(milliseconds: 100), _navigateToAnswerScreen);
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedScale(
        scale: _isTapped ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: _buildCardDecoration(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTitleSection(),
              const SizedBox(height: 12),
              _buildInfoTagsSection(),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(bool isDark) {
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final shadowColor =
        isDark ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.15);

    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20.0),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0.0, 0.2), end: Offset.zero)
                      .animate(animation),
                  child: child,
                ),
              );
            },
            child: Align(
              key: ValueKey<String>(_finalExamName),
              alignment: Alignment.centerLeft,
              child: Text(
                _finalExamName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: _buildStatusIndicator(),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return const SizedBox.shrink();
  }

  Widget _buildInfoTagsSection() {
    return Row(
      children: [
        if (_nameFoundViaJson) ...[
          _InfoTag(
            text: _formatGrade(_determinedGradeId),
            color: widget.primaryColor,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          '${widget.groupData.group.length} 个文件',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 12),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade400, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(
          _relativeTime,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String text;
  final Color color;
  const _InfoTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}
