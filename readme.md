<div align="center">
  <h1>⚡ dev-env</h1>
  <p>nushell 跨平台一键开发环境搭建 — 单文件自解压, 无 pwsh / bash 双份脚本</p>

  ![License](https://img.shields.io/badge/license-MIT-blue)
  ![Nushell](https://img.shields.io/badge/nushell-0.114-blue)
  ![Platform](https://img.shields.io/badge/platform-windows%20%7C%20macos%20%7C%20linux-lightgrey)
  ![Size](https://img.shields.io/badge/single%20file-~15KB-success)
</div>

---

## ✨ 特性

- **单一脚本语言: nushell** — 逻辑只有一份, Windows / Linux / macOS 通用,
  不再出现"Windows 写 pwsh、其他平台写 bash"的两份脚本。
- **自压缩单文件产物** — `pack.nu` 把源码 gzip 压缩后嵌入单个 `dev-env.nu`,
  运行时自解压到临时目录再执行 (类似 shc / shar 的自解压归档)。
- **压缩/解压只依赖 `tar`** — Windows 10+ 内置 bsdtar, 无需额外安装。
- **按需工具链** — 核心 (ripgrep / yazi / mise) + 可选
  (fd / bat / fzf / zoxide / eza / jq / lazygit / delta / starship / fastfetch)。
- **自动补齐 treesitter 编译链** — `--with-parsers` 自动安装 cargo-binstall,
  用其下载预编译 tree-sitter CLI, 再 headless 编译全部解析器。
- **轻量 nvim 配置** — lazy.nvim 按需加载, 无动效插件, 状态栏用 mini 系;
  LSP (rust-analyzer / ts_ls / lua_ls 等) 由 Mason 自动管理。
- **安全可重入** — 写入配置前自动备份 (`init.lua` → `init.lua.bak`),
  全部步骤可 `--dry-run` 预览, 重复执行幂等。

## 🚀 快速开始

唯一依赖: [nushell](https://www.nushell.sh) (建议 0.114+):

```sh
winget install nushell        # Windows
brew install nushell          # macOS
cargo install nu              # 通用 (有 Rust 时)
```

下载单文件产物 (或从源码打包, 见下文), 然后:

```sh
# 先预览将要执行的命令
nu dev-env.nu --dry-run

# 正式安装 (核心工具 + nvim + lazy.nvim)
nu dev-env.nu

# 完整安装: 自动装 cargo-binstall + tree-sitter CLI 并编译解析器
nu dev-env.nu --with-parsers

# 连可选工具一起装 (fd/bat/fzf/zoxide/eza/jq/lazygit/delta/starship/fastfetch)
nu dev-env.nu --with-extra --with-parsers
```

安装完成后运行 `nvim`, 首次启动自动安装插件; 打开任意文件时 Mason 自动补齐 LSP。

## 🔧 参数

| 参数 | 说明 |
| --- | --- |
| `--dry-run` | 只预览将执行的命令, 不真正安装 |
| `--no-neovim` | 跳过 nvim / lazy.nvim |
| `--no-tools` | 跳过 ripgrep / yazi / mise |
| `--with-extra` | 额外安装 fd/bat/fzf/zoxide/eza/jq/lazygit/delta/starship/fastfetch |
| `--with-parsers` | 自动装 cargo-binstall + tree-sitter CLI, 并编译 treesitter 解析器 |
| `--version` / `--help` | 版本 / 帮助 |
| `--self-extract <dir>` | 只把内置源码解压到目录 (调试用) |

## 📦 工具清单

| 分类 | 工具 | 说明 |
| --- | --- | --- |
| 核心 | ripgrep / yazi / mise | 搜索 / 终端文件管理 / 运行时版本管理 (原 rtx) |
| 可选 | fd / bat / fzf | 查找 / 高亮 cat / 模糊过滤 |
| 可选 | zoxide / eza / jq | 智能 cd / ls 替代 / JSON 处理 |
| 可选 | lazygit / delta | TUI git 客户端 / git diff 高亮 (自动配置 pager) |
| 可选 | starship / fastfetch | 提示符 / 系统信息 |
| LSP | rust-analyzer / ts_ls / lua_ls / html / cssls / jsonls / yamlls / tailwindcss | Mason 自动安装 |

安装策略: 优先包管理器 (scoop / winget / choco / brew / apt / dnf / pacman / apk),
失败或缺失时自动回退 GitHub Release 下载 (资产命名规则经真实 Release 数据校验)。

## 🧬 自压缩机制

```text
pack.nu          # 自压缩打包工具: 读 src/ → gzip → base64 → 单文件产物
  │
  ▼
dev-env.nu       # 运行时: 解压到临时目录 → 调用 nushell 执行 install.nu
```

```sh
nu pack.nu                          # 生成 dist/dev-env.nu (tar.gz 压缩)
nu pack.nu --no-compress            # 仅 base64 直存 (调试)
nu dist/dev-env.nu --self-extract <目录>   # 查看内置源码, 验证产物
```

## 🛠 开发

```text
src/install.nu       # 入口 (参数解析 + 流程编排)
src/util.nu          # 跨平台工具函数 (包管理器 / 提权 / 运行)
src/tools.nu         # 工具安装 (含 GitHub Release 兜底下载)
src/neovim.nu        # nvim 安装 + lazy.nvim 配置 + treesitter 编译链
src/assets/init.lua  # nvim 配置模板 (lazy.nvim 引导 + 精简插件)
```

开发模式直接跑源码: `nu src/install.nu --dry-run`

## 🌐 对标 oh-my-termux

工具清单与"非交互一键安装"的体验参照
[air-plus/oh-my-termux](https://github.com/air-plus/oh-my-termux),
本项目把它的 Termux 专用工具映射为跨平台等价物:

| oh-my-termux | 本项目对应 | 状态 |
| --- | --- | --- |
| Zsh + Zimfw (shell) | nushell (本项目本身就是) | ✓ 内建 |
| Neovim + LazyVim | Neovim + lazy.nvim (轻量精简版) | ✓ 核心 |
| Git + Lazygit + Delta | 同左, 自动配置 git pager/别名 | ✓ `--with-extra` |
| Starship 提示符 | 同左 | ✓ `--with-extra` |
| Yazi 文件管理器 | 同左 | ✓ 核心 |
| Zellij 终端复用 | 暂未收录 (Windows 支持有限) | ⏳ 待定 |
| eza / fd / ripgrep / bat | 同左 | ✓ |
| zoxide / fzf / jq | 同左 | ✓ |
| Fastfetch 信息展示 | 同左 | ✓ `--with-extra` |
| htop / Stow | 平台相关, 暂不收录 | — |

## ❓ FAQ

<details>
  <summary>Windows 上 treesitter 解析器装不上?</summary>

> 新版 nvim-treesitter 需要 `tree-sitter` CLI 与 C 编译器。
> 使用 `--with-parsers` 会自动完成: 先装 cargo-binstall, 再下载预编译
> tree-sitter CLI (已实测 17/17 解析器编译通过)。
</details>

<details>
  <summary>会覆盖我已有的 nvim 配置吗?</summary>

> 会写入 `init.lua`, 但原文件会自动备份为 `init.lua.bak`。
> 安装前建议先 `--dry-run` 预览。
</details>

<details>
  <summary>为什么是 nushell 而不是 pwsh + bash?</summary>

> 一份逻辑, 三平台通用, 避免双脚本维护与行为漂移。
> nushell 是跨平台 shell, 唯一前置依赖。
</details>

<details>
  <summary>GitHub 下载受限怎么办?</summary>

> 工具优先走系统包管理器; Release 兜底下载的资产命名按官方 release 数据
> 维护。若网络受限, 可配置镜像后重试, 或改用包管理器手动安装。
</details>

## 📄 License

[MIT](LICENSE)
