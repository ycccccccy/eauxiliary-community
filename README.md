# Eauxiliary 社区版

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-lightgrey.svg)](https://flutter.dev/docs/development/tools/sdk/release-notes)
[![GitHub stars](https://img.shields.io/github/stars/ycccccccy/eauxiliary-community)](https://github.com/ycccccccy/eauxiliary-community/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ycccccccy/eauxiliary-community)](https://github.com/ycccccccy/eauxiliary-community/network)

![GitHub commit activity](https://img.shields.io/github/commit-activity/m/ycccccccy/eauxiliary-community)
![GitHub last commit](https://img.shields.io/github/last-commit/ycccccccy/eauxiliary-community)
![GitHub contributors](https://img.shields.io/github/contributors/ycccccccy/eauxiliary-community)

![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/ycccccccy/eauxiliary-community)
![GitHub repo size](https://img.shields.io/github/repo-size/ycccccccy/eauxiliary-community)
![GitHub language count](https://img.shields.io/github/languages/count/ycccccccy/eauxiliary-community)

专为E听说软件设计的辅助工具，快速获取试题答案。

如果你需要支持北京初中、高中和广东初中、高中的专业版，请访问 [EAuxiliary 官网](https://www.gzzx.top/) 获取更多信息和下载链接
</details>

##  主要特点

###  核心功能
- **智能答案解析**：能够自动识别题目类型，并以清晰的格式展示答案
- **简洁的用户界面**：采用现代化的Material Design设计，支持深色和浅色主题切换
- **跨平台支持**：同时支持Android和Windows平台，满足不同用户的使用需求

###  使用体验
- **即装即用**：无需复杂配置，安装后就能直接使用
- **灵活的访问方式**：支持自动访问和Shizuku访问两种方式
- **智能缓存机制**：自动缓存已解析的答案，提升后续访问速度

###  技术亮点
- **Flutter框架**：基于最新的Flutter技术构建，确保跨平台体验的一致性
- **Provider状态管理**：使用官方推荐的状态管理方案，代码结构清晰
- **响应式设计**：能够适配各种屏幕尺寸和设备类型

##  安装说明

### Android用户
1. 从[Releases页面](https://github.com/ycccccccy/eauxiliary-community/releases)下载最新的APK文件
2. 在设备上开启"未知来源"应用安装权限
3. 安装下载的APK文件

### Windows用户
1. 从[Releases页面](https://github.com/ycccccccy/eauxiliary-community/releases)下载Windows版本
2. 解压文件并运行可执行程序

##  使用指南

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

##  常见问题

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

##  开发环境

### 环境要求
- Flutter 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Android SDK
- Visual Studio

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


##  项目结构

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

##  参与贡献

我们非常欢迎并感谢每一位愿意为 Eauxiliary 社区版贡献力量的开发者！无论是修复一个微小的 Bug，还是实现一个全新的功能，您的每一次贡献都至关重要。

为了维护项目的稳定性和代码质量，我们采用了一套规范的贡献流程。请您在开始前仔细阅读以下指南。

### 核心开发流程

本项目有两个核心分支，各自承担不同职责：
-   `main` 分支：存放最稳定的、可随时发布的正式版本代码。此分支受到严格保护，只接受来自 `dev` 分支的合并。
-   `dev` 分支：日常开发和功能集成的分支。**所有的贡献都应提交到此分支**。

### 贡献步骤

我们采用标准的 **Fork & Pull Request** 工作流。具体步骤如下：

#### 1. Fork 本仓库
点击仓库页面右上角的 "Fork" 按钮，将本仓库复制到您自己的 GitHub 账户下。

#### 2. 克隆您的 Fork
将您 Fork 后的仓库克隆到您的本地电脑。
```bash
git clone https://github.com/YOUR_USERNAME/eauxiliary-community.git
cd eauxiliary-community
```

#### 3. 创建您的开发分支
请务必基于 dev 分支来创建您的新分支。这非常重要！

```bash
# 首次贡献，建议添加上游仓库方便同步
git remote add upstream https://github.com/ycccccccy/eauxiliary-community.git

# 从上游仓库拉取最新的 dev 分支状态
git fetch upstream

# 基于最新的 dev 分支创建您的新分支
git checkout -b feature/your-amazing-feature upstream/dev
```

请将 `feature/your-amazing-feature` 替换为您分支的描述性名称（例如 `fix/login-bug` 或 `feat/dark-mode-optimizations`）。

#### 4. 进行编码和提交
在您的新分支上进行代码修改。完成后，清晰地提交您的更改。

```bash
git add .
git commit -m "feat: Add some amazing feature"
```

#### 5. 推送到您的 Fork
将您的本地分支推送到您在 GitHub 上的 Fork 仓库。

```bash
git push origin feature/your-amazing-feature
```

#### 6. 创建 Pull Request (PR)
回到您在 GitHub 的 Fork 仓库页面，您会看到一个提示，引导您创建一个 Pull Request。

- 请确保您的 PR 是从您的 `feature/your-amazing-feature` 分支提交到本仓库 (`ycccccccy/eauxiliary-community`) 的 `dev` 分支。**请勿向 main 分支提交！**
- 在 PR 的描述中，请清晰地说明您做了哪些更改，以及为什么要这样做。

### 自动化审查

在您提交 PR 后，GitHub Actions 会自动运行一系列检查，包括代码格式化、静态分析 (CodeQL) 和安全扫描。请确保您的 PR 能够通过所有的自动化检查，这是代码被合并的前提。

### 代码规范
- 使用中文注释，让代码更容易理解
- 遵循Flutter官方的代码规范
- 确保代码能通过`flutter analyze`检查
- 为新功能添加适当的单元测试

##  社区信息

### 相关链接
- **问题反馈**：[Issues](https://github.com/ycccccccy/eauxiliary-community/issues)
- **功能讨论**：[Discussions](https://github.com/ycccccccy/eauxiliary-community/discussions)
- **贡献指南**：[CONTRIBUTING](CONTRIBUTING.md)

##  许可证

本项目采用MIT许可证开源 - 查看[LICENSE](LICENSE)文件了解具体条款。

##  致谢

感谢[Flutter团队](https://flutter.dev/)提供的优秀跨平台开发框架，以及所有为项目做出贡献的开发者。

##  获取帮助

如果你在使用过程中遇到问题或有建议，可以：

1. 查看[常见问题](https://github.com/ycccccccy/eauxiliary-community/wiki/FAQ)
2. 搜索现有的[Issues](https://github.com/ycccccccy/eauxiliary-community/issues)
3. 创建新的Issue详细描述你的问题
4. 在[Discussions](https://github.com/ycccccccy/eauxiliary-community/discussions)中寻求帮助

##  版本更新

### v1.0.1
- 修复了更新管道错误的问题


### v1.0.0 
-  专注深圳高中英语听说考试
-  简化用户界面，移除复杂功能
-  即装即用，无需激活
-  开源发布，欢迎社区参与

---

**重要提醒**：本工具仅供学习参考使用，请遵守相关考试规定和学校政策。