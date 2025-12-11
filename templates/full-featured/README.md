# Full-Featured Project Template

这是一个完整功能的 Flake FHS 项目模板，展示了所有支持的功能和最佳实践。

## 项目结构

```
.
├── pkgs/           # 包定义
├── modules/        # NixOS 模块
├── profiles/       # NixOS 系统配置
├── shells/         # 开发环境
├── apps/           # 应用程序
├── lib/            # 工具函数库
├── checks/         # 检查和测试
└── templates/      # 子模板
```

## 功能特性

- 📦 **包管理** - 自动包发现和构建
- 🏗️ **模块系统** - 带部分加载的 NixOS 模块
- 💻 **系统配置** - 多个 NixOS 系统配置
- 🔧 **开发环境** - 多语言开发环境
- 🚀 **应用程序** - 可执行应用封装
- 📚 **工具库** - 可复用的函数库
- ✅ **质量检查** - 自动化测试和检查

## 使用方法

```bash
# 复制模板到新项目
nix flake init --template <flake-fhs-url>#full-featured

# 构建所有输出
nix flake check

# 构建包
nix build .#<package-name>

# 开发环境
nix develop .#<shell-name>

# 运行应用
nix run .#<app-name>

# 构建系统
nixos-rebuild switch --flake .#<profile-name>
```

## 扩展指南

1. **添加包** - 在 `pkgs/<name>/package.nix` 中定义
2. **创建模块** - 在 `modules/<name>/` 中添加 `options.nix` 和 `config.nix`
3. **系统配置** - 在 `profiles/<name>/configuration.nix` 中定义
4. **开发环境** - 在 `shells/<name>.nix` 中创建
5. **应用** - 在 `apps/<name>/default.nix` 中定义

## 最佳实践

- 遵循约定的目录结构
- 使用类型安全的选项定义
- 实现部分加载机制
- 添加适当的测试和检查
- 保持模块的独立性