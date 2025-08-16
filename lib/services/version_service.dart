import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class VersionService {
  // 版本号地址
  static const String versionCheckUrl =
      'https://gitee.com/asdasasdasdasfsdf/version-check/raw/master/version.json';

  // 添加请求超时时间
  static const Duration timeoutDuration = Duration(seconds: 5);

  static Future<Map<String, dynamic>> checkVersion() async {
    // 获取当前版本
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // 执行版本检查
    try {
      // 获取服务器版本信息
      final response = await http.get(
        Uri.parse(versionCheckUrl),
        headers: {'Accept-Charset': 'utf-8'},
      ).timeout(timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception('无法获取版本信息: 状态码 ${response.statusCode}');
      }

      // 解析JSON - 确保正确处理UTF-8编码
      String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> versionData = jsonDecode(responseBody);
      final serverVersion = versionData['version'] ?? '';
      final List<dynamic> changelogItems = versionData['changelog'] ?? [];

      // 提取更新日志
      List<String> changelog =
          changelogItems.map((item) => item.toString()).toList();

      // 比较版本号
      final needsUpdate = _compareVersions(currentVersion, serverVersion) < 0;

      return {
        'currentVersion': currentVersion,
        'serverVersion': serverVersion,
        'needsUpdate': needsUpdate,
        'changelog': changelog,
        'downloadUrl': versionData['downloadUrl'] ?? '',
      };
    } catch (e) {
      debugPrint('版本检查失败: $e');
      return {
        'error': e.toString(),
        'currentVersion': currentVersion,
        'serverVersion': '',
        'needsUpdate': false,
        'changelog': [],
      };
    }
  }

  // 比较版本号，返回 -1 表示需要更新，0 表示相同，1 表示当前版本更新
  static int _compareVersions(String current, String server) {
    List<int> currentParts =
        current.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    List<int> serverParts =
        server.split('.').map((part) => int.tryParse(part) ?? 0).toList();

    // 确保两个列表长度相同
    while (currentParts.length < 3) currentParts.add(0);
    while (serverParts.length < 3) serverParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (currentParts[i] < serverParts[i]) return -1;
      if (currentParts[i] > serverParts[i]) return 1;
    }

    return 0;
  }
}
