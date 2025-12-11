# NixOS Module Package Template

这是一个展示如何使用 Flake FHS 创建 NixOS 模块的模板，遵循模块化设计原则。

## 项目结构

```
.
├── modules/
│   └── my-service/         # NixOS 模块
│       ├── options.nix     # 模块选项定义
│       └── config.nix      # 模块配置
└── profiles/
    └── example/            # 使用该模块的系统配置
        └── configuration.nix
```

## 模块设计原则

- **options.nix** - 定义模块的配置选项和类型
- **config.nix** - 实现模块的具体配置逻辑
- 自动生成 `my-service.enable` 选项
- 自动创建 `services.my-service.*` 选项路径

## 使用方法

```bash
# 复制模板到新项目
nix flake init --template <flake-fhs-url>#package-module

# 构建 NixOS 配置
nixos-rebuild switch --flake .#example

# 查看可用模块
nix eval .#nixosModules
```

## 模块特性

- ✅ 部分加载机制 - 只有启用时才加载配置
- ✅ 类型安全的选项定义
- ✅ 自动选项路径生成
- ✅ 与 NixOS 生态兼容
- ✅ 支持模块组合