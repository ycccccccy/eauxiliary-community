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

### 提交代码

#### 准备工作
1. Fork本仓库到你的GitHub账户
2. 克隆Fork的仓库到本地
3. 设置开发环境（见README中的开发部分）

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

## 📝 代码规范

### 通用规范
- **语言**：所有注释、文档、变量名使用中文
- **格式**：使用`flutter format`格式化代码
- **分析**：确保`flutter analyze`无错误
- **测试**：为新功能编写测试

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
```

### 编写测试
- 为新功能编写单元测试
- 为UI组件编写Widget测试
- 为完整流程编写集成测试

## 📚 文档

### 更新文档
如果你的更改影响了：
- API或功能行为：更新README
- 配置或安装：更新相关文档
- 新功能：添加使用说明

### 文档规范
- 使用中文编写
- 保持简洁明了
- 包含代码示例
- 更新目录和链接

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

## 🎯 优先级领域

我们特别欢迎以下方面的贡献：

### 高优先级
- **Bug修复**：修复现有功能问题
- **性能优化**：提升应用响应速度
- **用户体验**：改善界面交互
- **文档完善**：补充使用说明

### 中优先级
- **代码重构**：提高代码质量
- **测试覆盖**：增加测试用例
- **无障碍支持**：改善可访问性
- **国际化**：支持其他语言

### 低优先级
- **新功能**：需要先讨论必要性
- **大型重构**：需要详细设计文档

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
