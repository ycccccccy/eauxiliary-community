# 贡献指南

欢迎为Eauxiliary社区版做出贡献！我们很高兴看到社区成员的参与。

## 🤝 如何参与贡献

### 报告问题
如果你发现了bug或有功能建议，请：

1. 先搜索[现有Issues](https://github.com/ycccccccy/eauxiliary-community/issues)确认问题未被报告
2. 创建新Issue，使用适当的模板
3. 提供详细的问题描述，包括：
   - 设备信息（Android版本、Windows版本等）
   - 重现步骤
   - 预期行为 vs 实际行为
   - 相关截图或日志
   - 应用版本号

### 提交代码

#### 准备工作
1. Fork本仓库到你的GitHub账户
2. 克隆Fork的仓库到本地
3. 设置开发环境（见下文开发环境设置）

#### 开发流程
1. 创建新分支：`git checkout -b feature/your-feature-name`
2. 进行开发，遵循代码规范
3. 编写或更新测试
4. 提交更改：`git commit -m "feat: 添加新功能"`
5. 推送到你的Fork：`git push origin feature/your-feature-name`
6. 创建Pull Request

#### Pull Request要求
- 清晰的标题和描述
- 关联相关的Issue
- 通过所有测试
- 遵循代码规范
- 更新相关文档
- 确保代码能通过`flutter analyze`检查

## 🛠️ 开发环境设置

### 环境要求
- **Flutter**: 3.0+ 
- **Dart**: 3.0+
- **IDE**: Android Studio / VS Code
- **Android SDK**: API 21+ (Android 5.0+)
- **Windows**: Windows 10+

### 环境配置步骤

#### 1. 安装Flutter
```bash
# 下载Flutter SDK
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"

# 验证安装
flutter doctor
```

#### 2. 克隆项目
```bash
# 克隆你的Fork
git clone https://github.com/YOUR_USERNAME/eauxiliary-community.git
cd eauxiliary-community

# 添加上游仓库
git remote add upstream https://github.com/ycccccccy/eauxiliary-community.git
```

#### 3. 安装依赖
```bash
flutter pub get
```

#### 4. 运行项目
```bash
# Android版本
flutter run

# Windows版本
flutter run -d windows
```

## 📝 代码规范

### 通用规范
- **语言**：所有注释、文档、变量名使用中文
- **格式**：使用`flutter format`格式化代码
- **分析**：确保`flutter analyze`无错误
- **测试**：为新功能编写测试
- **分支命名**：使用描述性名称，如`feature/dark-mode`、`fix/login-bug`

### Dart代码规范
```dart
/// 函数或类的中文注释
/// 
/// 详细描述功能和用途
class ExampleClass {
  /// 私有变量的中文注释
  final String _privateVariable;
  
  /// 公共方法的中文注释
  /// 
  /// [parameter] 参数说明
  /// 返回值说明
  String publicMethod(String parameter) {
    // 行内注释使用中文
    return '处理结果';
  }
}
```

### 文件命名规范
- **Dart文件**: 使用小写字母和下划线，如`user_profile.dart`
- **目录名**: 使用小写字母和下划线，如`user_management/`
- **类名**: 使用大驼峰命名法，如`UserProfile`
- **变量名**: 使用小驼峰命名法，如`userName`
- **常量名**: 使用小写字母和下划线，如`max_retry_count`

### 提交信息规范
使用[约定式提交](https://www.conventionalcommits.org/zh-hans/v1.0.0/)格式：

```
<类型>: <描述>

[可选的正文]

[可选的脚注]
```

类型包括：
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动
- `perf`: 性能优化
- `ci`: CI/CD相关

示例：
```
feat: 添加深色模式支持

为应用添加完整的深色模式支持，包括：
- 主题切换功能
- 所有页面的深色适配
- 用户偏好保存

Closes #123
```

## 🧪 测试

### 运行测试
```bash
# 单元测试
flutter test

# 集成测试
flutter test integration_test/

# 代码覆盖率
flutter test --coverage
```

### 编写测试
- 为新功能编写单元测试
- 为UI组件编写Widget测试
- 为完整流程编写集成测试
- 测试覆盖率应达到80%以上

### 测试文件命名
- 单元测试：`test/`目录下，文件名以`_test.dart`结尾
- Widget测试：`test/widget_test/`目录下
- 集成测试：`integration_test/`目录下

## 📚 文档

### 更新文档
如果你的更改影响了：
- API或功能行为：更新README
- 配置或安装：更新相关文档
- 新功能：添加使用说明
- 代码结构：更新项目结构说明

### 文档规范
- 使用中文编写
- 保持简洁明了
- 包含代码示例
- 更新目录和链接
- 使用Markdown格式

## 🏷️ 发布流程

### 版本号规范
遵循[语义化版本](https://semver.org/lang/zh-CN/)：
- `主版本号.次版本号.修订号`
- 主版本号：不兼容的API修改
- 次版本号：向下兼容的功能性新增
- 修订号：向下兼容的问题修正

### 发布检查清单
- [ ] 所有测试通过
- [ ] 文档已更新
- [ ] CHANGELOG已更新
- [ ] 版本号已更新
- [ ] 创建发布标签
- [ ] 代码审查完成
- [ ] 性能测试通过

## 🎯 优先级领域

我们特别欢迎以下方面的贡献：

### 高优先级
- **Bug修复**：修复现有功能问题
- **性能优化**：提升应用响应速度
- **用户体验**：改善界面交互
- **文档完善**：补充使用说明
- **测试覆盖**：增加测试用例

### 中优先级
- **代码重构**：提高代码质量
- **无障碍支持**：改善可访问性
- **错误处理**：完善异常处理机制
- **日志系统**：改进调试信息

### 低优先级
- **新功能**：需要先讨论必要性
- **大型重构**：需要详细设计文档
- **国际化**：支持其他语言

## 🔄 贡献工作流

### 标准工作流
1. **Fork仓库** → 克隆到本地
2. **创建分支** → 基于`dev`分支
3. **开发功能** → 遵循代码规范
4. **编写测试** → 确保功能正确性
5. **提交代码** → 使用规范提交信息
6. **推送分支** → 到你的Fork
7. **创建PR** → 提交到`dev`分支
8. **代码审查** → 等待维护者审查
9. **合并代码** → 审查通过后合并

### 分支策略
- `main`: 生产环境，只接受来自`dev`的合并
- `dev`: 开发分支，接受所有贡献
- `feature/*`: 功能开发分支
- `fix/*`: 问题修复分支
- `docs/*`: 文档更新分支

## 💬 交流渠道

- **GitHub Issues**：bug报告和功能请求
- **GitHub Discussions**：一般讨论和问答
- **Pull Request**：代码审查和讨论

## 📄 许可证

通过贡献代码，你同意你的贡献将在[MIT许可证](LICENSE)下发布。

## 🙏 感谢

感谢每一位贡献者！你的参与让Eauxiliary变得更好。

---

有问题？请随时通过Issue或Discussion与我们联系！
