// lib/widgets/folder_list_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class FolderListItem extends StatelessWidget {
  final List<File> group;
  final String tag;
  final VoidCallback onTap;

  const FolderListItem({
    super.key,
    required this.group,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final folderName =
        group.firstOrNull?.path.split('/').last.substring(0, 6) ?? "文件夹";

    // 使用真实的修改时间
    final formattedDate = group.firstOrNull != null
        ? DateFormat('yyyy/MM/dd HH:mm:ss').format(
            DateTime.fromMillisecondsSinceEpoch(
                group.firstOrNull!.statSync().modified.millisecondsSinceEpoch))
        : "未知时间";

    return Card(
      elevation: isDarkMode ? 2 : 4,
      shadowColor: isDarkMode ? Colors.black54 : Colors.black45,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : const Color(0xFF99BBDD),
          width: isDarkMode ? 1.0 : 2.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            // 使用 Row 横向布局
            children: [
              Expanded(
                // 使用 Expanded 让标题占据剩余空间
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '模考 $folderName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '时间: $formattedDate',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
