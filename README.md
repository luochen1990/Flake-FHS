Flake FHS
=========
**Flake Filesystem Hierarchy Standard**

Flake FHS 是一个面向 Nix flake 的文件系统层级规范，它同时提供一个默认的 `flake.nix` 实现（`mkFlake`）。
用户几乎不需要自己编写 `flake.nix`。只需将 Nix 代码放置在约定的目录结构中，Flake FHS 就会自动映射并生成所有对应的 flake outputs。

它是一个 **“约定优于配置”** 的 flake 项目布局标准。

Flake FHS 致力于解决以下核心问题：

- 项目之间 flake 结构差异过大，难以理解与复用
- 为每个项目重复编写大量 `flake.nix` boilerplate
- 工具无法推断目录语义，导致自动化困难

Flake FHS 提供：

1. 一个 **固定、可预测、可扩展** 的 flake 项目目录规范
2. 一个 **自动生成 flake outputs** 的默认实现

---

## 🚀 快速开始

使用 Flake FHS 时典型项目**目录结构**如下：

```
.
├── pkgs/       # flake-output.packages
├── modules/    # flake-output.nixosModules
├── profiles/   # flake-output.nixosConfigurations
├── shells/     # flake-output.devShells
├── apps/       # flake-output.apps
├── utils/      # flake-output.lib (工具函数目录)
├── checks/     # flake-output.checks
└── templates/  # flake-output.templates
```

Flake FHS 提供了若干模板来快速启动不同类型的项目：

```bash
# 创建简单项目
nix flake init --template github:luochen1990/flake-fhs#simple-project

# 创建完整功能项目
nix flake init --template github:luochen1990/flake-fhs#full-featured
```

这将直接为你生成一个简洁并且合法的 flake.nix 文件：

```nix
{
  inputs.fhs.url = "github:luochen1990/flake-fhs";

  outputs = { fhs, ... }:
    fhs.mkFlake { root = [ ./. ]; };
}
```

之后你只需要在对应的目录里添加配置即可，**无需手写 flake outputs**

详细用法见: [使用手册](./docs/manual.md)

## 许可证

MIT License

<!--
Copyright © 2025 罗宸 (luochen1990@gmail.com)
-->
