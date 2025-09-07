# Eauxiliary 社区版

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-lightgrey.svg)](https://flutter.dev/docs/development/tools/sdk/release-notes)
[![GitHub stars](https://img.shields.io/github/stars/ycccccccy/eauxiliary-community)](https://github.com/ycccccccy/eauxiliary-community/stargazers)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

专为E听说软件设计的辅助工具，快速获取试题答案。

> **专业版提醒**: 如果您需要支持北京初中、高中和广东初中、高中的版本，请访问 [EAuxiliary 官网](https://www.gzzx.top/) 获取。

> **注意**: 由于Android系统的方案基于原生的Fileservice漏洞实现读取，部分Android12-与15+的系统可能无法正常使用

---

##  主要特点

- **智能答案解析**：自动识别题目类型，并以清晰的格式展示答案。
- **简洁的用户界面**：采用现代化的 Material Design，支持深色和浅色主题。
- **跨平台支持**：同时支持 Android 和 Windows 平台。
- **即装即用**：无需复杂配置，安装后即可直接使用。
- **智能缓存机制**：自动缓存已解析的答案，提升后续访问速度。

##  安装说明

### Android
1. 前往 [Releases 页面](https://github.com/ycccccccy/eauxiliary-community/releases)下载最新的 `.apk` 文件。
2. 在设备上开启“允许安装未知来源应用”的权限。
3. 点击下载的 APK 文件进行安装。

### Windows
1. 前往 [Releases 页面](https://github.com/ycccccccy/eauxiliary-community/releases)下载最新的 Windows 版本压缩包。
2. 解压文件，并运行其中的可执行程序。

##  使用指南

### 首次启动
1. **启动应用**：首次启动会进入引导页面，请根据提示完成授权。
2. **选择访问方式**：
   - **自动选择目录**：推荐大多数用户使用，操作简单。
   - **使用 Shizuku**：需要额外配置，但能获得更完整的访问权限。

### 查看答案
1. 主页面会自动列出最新的试题组。
2. 点击任意试题卡片即可进入答案详情页面。

<details>
<summary><b>👉 点击查看 Shizuku 的配置方法</b></summary>

1. 在您的设备上安装 [Shizuku 应用](https://github.com/RikkaApps/Shizuku)。
2. 根据 Shizuku 的官方说明启动服务（通常需要通过无线调试或 Root 权限）。
3. 返回 Eauxiliary，在引导页或设置中选择“使用 Shizuku 访问”并完成授权。
</details>

## ❓ 常见问题 (FAQ)

- **应用无法启动？**
  - 确保设备支持 Flutter 应用，并尝试重新安装。
- **找不到试题文件？**
  - 确认E听说软件已下载试题并且保存在设备上，或尝试使用 Shizuku 方式访问。
- **答案显示异常？**
  - 尝试在应用内清除缓存，然后重新选择试题目录。

## 🛠️ 参与开发

我们欢迎任何形式的贡献！无论是代码提交、功能建议还是 Bug 反馈，都对项目至关重要。

### 开发环境
- Flutter 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Android SDK / Visual Studio

### 运行项目
```bash
# 1. 克隆仓库
git clone https://github.com/ycccccccy/eauxiliary-community.git
cd eauxiliary-community

# 2. 安装依赖
flutter pub get

# 3. 运行应用
flutter run # 运行 Android 版本
flutter run -d windows # 运行 Windows 版本
```

### 贡献流程
我们采用标准的 `Fork & Pull Request` 工作流，所有开发都在 `dev` 分支进行。
1. **Fork** 本仓库。
2. 基于 `dev` 分支创建您的新特性分支 (`git checkout -b feature/my-new-feature upstream/dev`)。
3. 提交您的代码。
4. 创建一个 Pull Request，目标分支请务必选择本仓库的 `dev` 分支。

> 详细流程请参考 [**贡献指南**](CONTRIBUTING.md)。

## 📁 项目结构

<details>
<summary><b>👉 点击展开查看项目文件结构</b></summary>

```
lib/
├── main.dart                 # 应用入口点
├── models/                   # 数据模型
├── providers/                # 状态管理
├── screens/                  # 页面组件
├── services/                 # 业务服务
├── utils/                    # 工具类
└── widgets/                  # 可复用组件
```
</details>

## 💬 社区与支持

- **反馈问题**: [提交 Issue](https://github.com/ycccccccy/eauxiliary-community/issues)
- **参与讨论**: [前往 Discussions](https://github.com/ycccccccy/eauxiliary-community/discussions)
- **查看版本更新**: [Releases](https://github.com/ycccccccy/eauxiliary-community/releases)

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源。

---
**重要提醒**：本工具仅供学习参考使用，请遵守相关考试规定和学校政策。
