import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eauxiliary/services/file_service.dart';
import 'package:provider/provider.dart';
import 'package:eauxiliary/providers/answer_provider.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugInfo = "加载调试信息中...";
  String _directoryPath = "";
  List<String> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final buffer = StringBuffer();
      
      // 获取共享首选项信息
      final prefs = await SharedPreferences.getInstance();
      final storedPath = prefs.getString('directory_uri') ?? "未设置";
      final hasReadEula = prefs.getBool('hasReadPrivacyPolicy') ?? false;
      
      buffer.writeln("## 应用状态");
      buffer.writeln("- 存储路径: $storedPath");
      buffer.writeln("- 是否阅读EULA: $hasReadEula");
      
      // 设置当前目录路径
      _directoryPath = storedPath;

      // 尝试读取目录内容
      if (_directoryPath != "未设置") {
        final directory = Directory(_directoryPath);
        if (await directory.exists()) {
          buffer.writeln("\n## 目录内容");
          buffer.writeln("路径: $_directoryPath");
          
          try {
            // 列出目录内容
            final entities = await directory.list().toList();
            final fileNames = <String>[];
            
            buffer.writeln("发现 ${entities.length} 个项目:");
            for (var entity in entities) {
              final type = entity is Directory ? "目录" : "文件";
              final name = entity.path.split('/').last;
              fileNames.add("$type: $name (${entity.path})");
              buffer.writeln("- $type: $name");
            }
            
            setState(() {
              _files = fileNames;
            });
          } catch (e) {
            buffer.writeln("无法读取目录内容: $e");
          }
        } else {
          buffer.writeln("\n目录不存在: $_directoryPath");
        }
      }

      // 检查Android/data路径
      try {
        const zeroWidthSpace = "\u200B";
        const targetPath = '/storage/emulated/0/A${zeroWidthSpace}ndroid/data/com.ets100.secondary';
        final alternativeDir = Directory(targetPath);
        
        buffer.writeln("\n## 替代路径检查");
        buffer.writeln("路径: $targetPath");
        
        if (await alternativeDir.exists()) {
          buffer.writeln("目录存在");
          try {
            final contents = await alternativeDir.list().toList();
            buffer.writeln("内容数量: ${contents.length}");
          } catch (e) {
            buffer.writeln("无法读取内容: $e");
          }
        } else {
          buffer.writeln("目录不存在");
        }
      } catch (e) {
        buffer.writeln("检查替代路径时出错: $e");
      }

      setState(() {
        _debugInfo = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = "加载调试信息时出错: $e";
        _isLoading = false;
      });
    }
  }

  // 尝试读取指定路径的内容
  Future<void> _exploreDirectory(String path) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        final entities = await directory.list().toList();
        final fileNames = <String>[];
        
        for (var entity in entities) {
          final type = entity is Directory ? "目录" : "文件";
          final name = entity.path.split('/').last;
          fileNames.add("$type: $name (${entity.path})");
        }
        
        setState(() {
          _directoryPath = path;
          _files = fileNames;
        });
      } else {
        setState(() {
          _files = ["目录不存在: $path"];
        });
      }
    } catch (e) {
      setState(() {
        _files = ["读取目录时出错: $e"];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 强制重新加载文件夹列表
  Future<void> _reloadFolders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final folders = await FileService.getSortedResourceFolders();
      final folderInfo = StringBuffer();
      
      folderInfo.writeln("## 刷新结果");
      folderInfo.writeln("发现 ${folders.length} 个文件夹:");
      
      for (var folder in folders) {
        folderInfo.writeln("- 名称: ${folder.name.split('/').last}");
        folderInfo.writeln("  - 路径: ${folder.name}");
        folderInfo.writeln("  - 修改时间: ${folder.lastModified}");
      }

      // 在Provider中刷新数据
      await Provider.of<AnswerProvider>(context, listen: false).loadGroupedFolders();
      
      folderInfo.writeln("\n刷新完成，请返回主界面查看");

      setState(() {
        _debugInfo = folderInfo.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = "刷新文件夹时出错: $e";
        _isLoading = false;
      });
    }
  }

  // 手动设置目录路径
  void _setDirectoryPath() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("手动设置路径"),
        content: TextField(
          decoration: const InputDecoration(
            hintText: "输入目录路径",
          ),
          onChanged: (value) {
            _directoryPath = value;
          },
          controller: TextEditingController(text: _directoryPath),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // 保存路径到SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('directory_uri', _directoryPath);
              
              // 重新加载调试信息
              await _loadDebugInfo();
              
              // 显示提示
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("已保存路径")),
              );
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }
  
  // 清除EULA状态
  Future<void> _clearEulaStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasReadPrivacyPolicy');
      
      // 重新加载调试信息
      await _loadDebugInfo();
      
      // 显示提示
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("已清除EULA状态")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("清除EULA状态失败: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("调试模式"),
        backgroundColor: Colors.deepPurple, // 特殊颜色表示这是调试界面
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
            tooltip: '刷新信息',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 调试信息显示
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "调试信息",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _debugInfo,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 文件浏览器
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "文件浏览器",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: _setDirectoryPath,
                                tooltip: '编辑路径',
                              ),
                            ],
                          ),
                          Text("当前路径: $_directoryPath"),
                          const SizedBox(height: 8),
                          if (_files.isEmpty)
                            const Text("无文件或目录")
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _files.length,
                              itemBuilder: (context, index) {
                                final fileInfo = _files[index];
                                final isDirectory = fileInfo.startsWith("目录");
                                
                                return ListTile(
                                  leading: Icon(
                                    isDirectory ? Icons.folder : Icons.insert_drive_file,
                                    color: isDirectory ? Colors.amber : Colors.blue,
                                  ),
                                  title: Text(fileInfo),
                                  onTap: isDirectory
                                      ? () {
                                          final path = fileInfo.split('(')[1].split(')')[0];
                                          _exploreDirectory(path);
                                        }
                                      : null,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("刷新文件夹"),
                onPressed: _reloadFolders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text("清除EULA状态"),
                onPressed: _clearEulaStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 