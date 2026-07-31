# install.nu — dev-env 入口
use ./util.nu *
use ./tools.nu *
use ./neovim.nu *

const VERSION = "0.1.1"

def print-banner [] {
  print ""
  print $"(ansi cyan)──────────────────────────────────────────────"
  print "  dev-env — nushell 跨平台一键开发环境"
  print "──────────────────────────────────────────────(ansi reset)"
}

def print-help [] {
  print "dev-env — nushell 跨平台一键开发环境搭建工具"
  print ""
  print "用法:"
  print "  nu dev-env.nu [选项]"
  print ""
  print "选项:"
  print "  --dry-run      预览将要执行的命令, 不真正安装"
  print "  --no-neovim    跳过 nvim / lazy.nvim"
  print "  --no-tools     跳过 ripgrep / yazi / mise"
  print "  --with-extra   额外安装 fd/bat/fzf/zoxide/eza/jq/lazygit/delta/starship/fastfetch"
  print "  --with-parsers 自动安装 cargo-binstall + tree-sitter CLI, 并编译 treesitter 解析器"
  print "  --version      显示版本"
  print "  --help         显示帮助"
  print ""
  print "自解压产物额外支持:"
  print "  --self-extract <dir>   只解压内置源码到目录 (调试用)"
}

def print-summary [ok: bool] {
  print ""
  print $"(ansi cyan)── 完成 ───────────────────────────────────(ansi reset)"
  if $ok {
    print $"(ansi green)✓ 环境搭建完成!(ansi reset)"
  } else {
    print $"(ansi yellow)! 部分步骤未完成, 请查看上方输出(ansi reset)"
  }
  print ""
  print "接下来:"
  print "  1. 打开 nvim, 首次启动会自动安装全部插件 (lazy.nvim)"
  print "  2. LSP 已按需预装: rust-analyzer / ts_ls / lua_ls 等 (:Mason 可查看)"
  print "  3. 用 mise 管理语言工具链:  mise use -g rust@stable  或  mise use -g node@lts"
  print ""
  print $"(ansi green)可以开始编辑你的 Rust + React 全栈项目了!(ansi reset)"
}

export def main [
  --dry-run
  --no-neovim
  --no-tools
  --with-extra
  --with-parsers
  --version
  --help
] {
  if $version {
    print $"dev-env ($VERSION) — nushell 跨平台一键开发环境"
    return
  }
  if $help { print-help; return }
  $env.DEVENV_DRY_RUN = (if $dry_run { "1" } else { "0" })
  let root = ($env.DEVENV_ROOT? | default $env.FILE_PWD)
  let mgr = (pkg-manager)
  let mgr_txt = (if ($mgr | is-empty) { "未检测到 (将使用 GitHub 下载)" } else { $mgr })
  print-banner
  print $"  平台: ($nu.os-info.name) / ($nu.os-info.arch) / 内核 ($nu.os-info.kernel_version)"
  print $"  包管理器: ($mgr_txt)"
  if $dry_run { print $"(ansi yellow)  当前为预览模式 (--dry-run), 仅打印命令(ansi reset)" }
  print ""
  let ok_tools = (if $no_tools { true } else { install-tools --with-extra=$with_extra })
  let ok_nvim = (if $no_neovim { true } else {
    let a = (install-neovim)
    let b = (setup-lazynvim $root)
    $a and $b
  })
  let ok_parsers = (if $with_parsers {
    if $no_neovim { print "(提示) --with-parsers 依赖 nvim, 仅安装编译工具链" }
    let a = (ensure-tree-sitter-cli)
    let b = (if $no_neovim { true } else { install-treesitter-parsers })
    $a and $b
  } else { true })
  print-summary ($ok_tools and $ok_nvim and $ok_parsers)
}
