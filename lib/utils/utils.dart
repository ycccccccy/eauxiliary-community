// lib/utils/utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 设置状态栏文本颜色
void setStatusBarTextColor(bool isDark) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.dark : Brightness.light,
    ),
  );
}

void updateStatusBarTextColor(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  setStatusBarTextColor(brightness == Brightness.light);
}

// 改进HTML标签移除函数，更好地保留换行和格式
String removeHtmlTags(String htmlString) {
  try {
    if (htmlString.isEmpty) {
      return "";
    }

    // 替换HTML实体
    var result = htmlString
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // 确保<br>标签被正确替换为换行符
    result = result
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n')
        .replaceAll('<BR>', '\n')
        .replaceAll('<BR/>', '\n')
        .replaceAll('<BR />', '\n');

    // 移除其他所有HTML标签，保留内容
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');

    // 防止连续空行，但保留单个换行
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 移除多余空格但保留换行符
    result = result.replaceAll(RegExp(r' {2,}'), ' ');

    // 确保每个句子后有适当的空格
    result = result.replaceAll('. ', '.\n');

    return result.trim();
  } catch (e) {
    // 出错时返回简单处理的结果
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
