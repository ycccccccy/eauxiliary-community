# Eauxiliary 社区版

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-lightgrey.svg)](https://flutter.dev/docs/development/tools/sdk/release-notes)
[![GitHub stars](https://img.shields.io/github/stars/ycccccccy/eauxiliary-community)](https://github.com/ycccccccy/eauxiliary-community/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ycccccccy/eauxiliary-community)](https://github.com/ycccccccy/eauxiliary-community/network)

专为E听说软件设计的辅助工具，快速获取试题答案。

## 📊 项目统计

### 代码活跃度
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/ycccccccy/eauxiliary-community)
![GitHub last commit](https://img.shields.io/github/last-commit/ycccccccy/eauxiliary-community)
![GitHub contributors](https://img.shields.io/github/contributors/ycccccccy/eauxiliary-community)

### 代码统计
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/ycccccccy/eauxiliary-community)
![GitHub repo size](https://img.shields.io/github/repo-size/ycccccccy/eauxiliary-community)
![GitHub language count](https://img.shields.io/github/languages/count/ycccccccy/eauxiliary-community)

### 近期更新


![GitHub commit activity graph](https://github-readme-activity-graph.vercel.app/graph?username=ycccccccy&repo=eauxiliary-community&theme=github-compact&hide_border=true)

#### 语言分布
![Top Languages](https://github-readme-stats.vercel.app/api/top-langs/?username=ycccccccy&repo=eauxiliary-community&layout=compact&theme=github-compact&hide_border=true)


</details>

## 🌟 主要特点

### 🎯 核心功能
- **智能答案解析**：能够自动识别题目类型，并以清晰的格式展示答案
- **简洁的用户界面**：采用现代化的Material Design设计，支持深色和浅色主题切换
- **跨平台支持**：同时支持Android和Windows平台，满足不同用户的使用需求

### 📱 使用体验
- **即装即用**：无需复杂配置，安装后就能直接使用
- **灵活的访问方式**：支持自动访问和Shizuku访问两种方式
- **智能缓存机制**：自动缓存已解析的答案，提升后续访问速度

### 🔧 技术亮点
- **Flutter框架**：基于最新的Flutter技术构建，确保跨平台体验的一致性
- **Provider状态管理**：使用官方推荐的状态管理方案，代码结构清晰
- **响应式设计**：能够适配各种屏幕尺寸和设备类型

## 📦 安装说明

### Android用户
1. 从[Releases页面](https://github.com/ycccccccy/eauxiliary-community/releases)下载最新的APK文件
2. 在设备上开启"未知来源"应用安装权限
3. 安装下载的APK文件

### Windows用户
1. 从[Releases页面](https://github.com/ycccccccy/eauxiliary-community/releases)下载Windows版本
2. 解压文件并运行可执行程序

## 🚀 使用指南

### 第一次使用
1. **启动应用**：首次启动会进入引导页面
2. **选择访问方式**：
   - **自动选择目录**：适合大多数用户，操作简单
   - **使用Shizuku**：需要额外配置，但能获得更完整的访问权限

### 自动选择目录方式
1. 只需要按照应用内提示即可自动确认目录

### 使用Shizuku
1. 安装[Shizuku应用](https://github.com/RikkaApps/Shizuku)
2. 按照Shizuku的说明启动服务（需要ADB或Root权限）
3. 返回本应用，点击"使用Shizuku访问"

### 查看答案
1. 主页面会显示最新的试题组
2. 点击试题卡片进入答案详情页面

## 🔍 常见问题

### 应用无法启动
- 确保设备支持Flutter应用
- 检查是否授予了必要的权限
- 尝试重新安装应用

### 找不到试题文件
- 确认文件路径是否正确
- 检查文件是否完整复制
- 尝试使用Shizuku方式访问

### 答案显示异常
- 清除应用缓存
- 重新选择试题目录
- 检查试题文件格式

### 性能问题
- 关闭其他后台应用
- 清理设备存储空间
- 重启应用

## 🏗️ 开发环境

### 环境要求
- Flutter 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Android SDK (开发Android版本时需要)
- Visual Studio (开发Windows版本时需要)

### 获取项目代码
```bash
git clone https://github.com/ycccccccy/eauxiliary-community.git
cd eauxiliary-community
```

### 安装项目依赖
```bash
flutter pub get
```

### 运行项目
```bash
# Android版本
flutter run

# Windows版本
flutter run -d windows
```

### 构建发布版本
```bash
# Android APK
flutter build apk --release

# Windows版本
flutter build windows --release
```

## 🏛️ 技术架构

### 整体架构
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   用户界面层     │    │   业务逻辑层     │    │   数据访问层     │
│   (UI Layer)    │◄──►│ (Business Layer)│◄──►│ (Data Layer)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 数据
1. 用户选择试题目录
2. 文件服务扫描并解析试题文件
3. 答案数据存储到本地缓存
4. 用户界面展示解析后的答案

## 📊 性能特点

### 响应速度
- **冷启动时间**：< 1秒
- **文件解析速度**：< 1秒（标准试题组）
- **答案加载速度**：< 500ms（已缓存）

### 兼容性
- **Android版本**：12.0+
- **Windows版本**：Windows 10+

## 📁 项目结构

```
lib/
├── main.dart                 # 应用入口点
├── models/                   # 数据模型
│   ├── folder_item.dart     # 文件夹项目模型
│   └── user.dart           # 用户模型
├── providers/               # 状态管理
│   ├── answer_provider.dart # 答案数据管理
│   └── settings_provider.dart # 设置管理
├── screens/                 # 页面组件
│   ├── main_screen.dart    # 主页面
│   ├── answer_screen.dart  # 答案显示页面
│   ├── settings_screen.dart # 设置页面
│   └── onboarding/         # 引导页面
├── services/               # 业务服务
│   ├── file_service.dart   # 文件操作服务
│   └── api_service.dart    # API服务
├── utils/                  # 工具类
│   ├── helpers.dart        # 辅助函数
│   └── utils.dart         # 通用工具
└── widgets/               # 可复用组件
    ├── group_card.dart    # 试题组卡片
    └── loading_indicator.dart # 加载指示器
```

## 🤝 参与贡献

我们欢迎社区成员的参与！如果你有好的想法或发现了问题，请按照以下步骤参与：

1. Fork 本仓库到你的GitHub账户
2. 创建特性分支：`git checkout -b feature/your-feature-name`
3. 提交你的更改：`git commit -m 'Add some amazing feature'`
4. 推送到分支：`git push origin feature/your-feature-name`
5. 提交Pull Request

### 代码规范
- 使用中文注释，让代码更容易理解
- 遵循Flutter官方的代码规范
- 确保代码能通过`flutter analyze`检查
- 为新功能添加适当的单元测试

### 贡献类型
- 🐛 **Bug修复**：修复现有功能问题
- ✨ **新功能**：添加有用的新特性
- 📚 **文档改进**：完善使用说明和开发文档
- 🎨 **界面优化**：改善用户体验
- ⚡ **性能提升**：优化应用性能

## 🌐 社区信息

### 相关链接
- **问题反馈**：[Issues](https://github.com/ycccccccy/eauxiliary-community/issues)
- **功能讨论**：[Discussions](https://github.com/ycccccccy/eauxiliary-community/discussions)
- **更新日志**：[CHANGELOG](CHANGELOG.md)
- **贡献指南**：[CONTRIBUTING](CONTRIBUTING.md)

## 📄 许可证

本项目采用MIT许可证开源 - 查看[LICENSE](LICENSE)文件了解具体条款。

## 🙏 致谢

感谢[Flutter团队](https://flutter.dev/)提供的优秀跨平台开发框架，以及所有为项目做出贡献的开发者。

## 📞 获取帮助

如果你在使用过程中遇到问题或有建议，可以：

1. 查看[常见问题](https://github.com/ycccccccy/eauxiliary-community/wiki/FAQ)
2. 搜索现有的[Issues](https://github.com/ycccccccy/eauxiliary-community/issues)
3. 创建新的Issue详细描述你的问题
4. 在[Discussions](https://github.com/ycccccccy/eauxiliary-community/discussions)中寻求帮助

## 🔄 版本更新

### v1.0.0 
- ✨ 专注深圳高中英语听说考试
- ✨ 简化用户界面，移除复杂功能
- ✨ 即装即用，无需激活
- ✨ 开源发布，欢迎社区参与

---

**重要提醒**：本工具仅供学习参考使用，请遵守相关考试规定和学校政策。