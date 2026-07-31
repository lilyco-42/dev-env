# neovim.nu — nvim 安装 + lazy.nvim 配置
use ./util.nu *

const NVIM_PKG = {
  windows: { scoop: "neovim", winget: "Neovim.Neovim", choco: "neovim" }
  macos: "neovim"
  linux: { "apt-get": "neovim", dnf: "neovim", pacman: "neovim", zypper: "neovim", apk: "neovim", "nix-env": "neovim" }
}

# nvim 配置目录: %LOCALAPPDATA%\nvim 或 ~/.config/nvim
export def nvim-config-dir []: nothing -> path {
  if (is-windows) { return ($env.LOCALAPPDATA | path join "nvim") }
  (($env.XDG_CONFIG_HOME? | default ($env.HOME? | default "" | path join ".config"))) | path join "nvim"
}

# nvim 数据目录: %LOCALAPPDATA%\nvim-data 或 ~/.local/share/nvim
export def nvim-data-dir []: nothing -> path {
  if (is-windows) { return ($env.LOCALAPPDATA | path join "nvim-data") }
  (($env.XDG_DATA_HOME? | default ($env.HOME? | default "" | path join ".local" "share"))) | path join "nvim"
}

export def install-neovim []: nothing -> bool {
  if (print-installed nvim) { return true }
  print ""
  print $"(ansi cyan)── Neovim ─────────────────────────────(ansi reset)"
  let entry = ($NVIM_PKG | get (os))
  let pkg = (if ($entry | describe) =~ "record" {
    let mgr = (pkg-manager)
    if ($mgr | is-empty) { "" } else { ($entry | get -o $mgr | default "") }
  } else { $entry })
  if ($pkg | is-empty) {
    print -e "未找到可用的包管理器, 请手动安装 neovim 后重试"
    return false
  }
  if (package-install $pkg) and (print-installed nvim) {
    print $"(ansi green)✓(ansi reset) nvim 安装完成"
    return true
  }
  print $"(ansi yellow)! nvim 安装后可能需重启终端才能进入 PATH(ansi reset)"
  true
}

# 安装 lazy.nvim 并写入 init.lua
export def setup-lazynvim [root: path]: nothing -> bool {
  if not (has git) {
    print -e "缺少 git, 无法安装 lazy.nvim"
    return false
  }
  let conf = (nvim-config-dir)
  let data = (nvim-data-dir)
  let lazy = ($data | path join "lazy" "lazy.nvim")
  if (is-dry-run) {
    print "  (预览) 将克隆 lazy.nvim 并写入 init.lua"
    print $"          → ($conf | path join "init.lua")"
    return true
  }
  mkdir $conf $data
  if ($lazy | path exists) {
    print "  · 更新 lazy.nvim"
    let _ = (run-cmd [git -C $lazy pull --ff-only origin stable])
  } else {
    print "  · 克隆 lazy.nvim"
    let _ = (run-cmd [git clone --filter=blob:none --branch stable https://github.com/folke/lazy.nvim.git $lazy])
  }
  let src = ($root | path join "assets" "init.lua")
  if not ($src | path exists) {
    print -e $"缺少配置文件: ($src)"
    return false
  }
  let target = ($conf | path join "init.lua")
  if ($target | path exists) {
    cp $target ($conf | path join "init.lua.bak")
    print $"  · 原配置已备份 → ($conf | path join "init.lua.bak")"
  }
  cp $src $target
  print $"(ansi green)✓(ansi reset) 配置已写入: ($target)"
  true
}

# 确保 cargo-binstall 可用 (优先包管理器, 其次 cargo 编译)
export def ensure-cargo-binstall []: nothing -> bool {
  if (has cargo-binstall) { return true }
  print "  · 安装 cargo-binstall ..."
  if (is-dry-run) {
    print "    (预览) 将通过包管理器或 cargo 安装 cargo-binstall"
    return true
  }
  let mgr = (pkg-manager)
  mut ok = false
  if $mgr == "scoop" {
    $ok = (run-cmd [scoop install cargo-binstall])
  } else if $mgr == "winget" {
    $ok = (run-cmd [winget install --id cargo-bins.cargo-binstall --silent --accept-package-agreements --accept-source-agreements])
  } else if $mgr == "choco" {
    $ok = (run-cmd [choco install -y cargo-binstall])
  } else if $mgr == "brew" {
    $ok = (run-cmd [brew install cargo-binstall])
  }
  if $ok { return true }
  if (has cargo) { return (run-cmd [cargo install cargo-binstall --locked]) }
  print -e "    无法自动安装 cargo-binstall, 请手动安装后重试"
  false
}

# 用 cargo-binstall 下载预编译的 tree-sitter CLI
export def ensure-tree-sitter-cli []: nothing -> bool {
  if (has tree-sitter) { return true }
  print "  · 下载 tree-sitter CLI ..."
  if (is-dry-run) {
    print "    (预览) 将用 cargo-binstall 下载预编译 tree-sitter-cli"
    return true
  }
  if not (ensure-cargo-binstall) { return false }
  let dir = (bin-dir)
  mkdir $dir
  let ok = (run-cmd [cargo binstall tree-sitter-cli --no-confirm --install-path $dir])
  if $ok { ensure-bin-in-path }
  $ok
}

# headless 安装插件并编译 treesitter 解析器
export def install-treesitter-parsers []: nothing -> bool {
  if not (has nvim) {
    print -e "缺少 nvim, 跳过解析器安装"
    return false
  }
  if (is-dry-run) {
    print "  (预览) 将 headless 安装插件并编译 14 个 treesitter 解析器"
    return true
  }
  let parsers = ["lua" "vim" "vimdoc" "rust" "typescript" "tsx" "javascript" "html" "css" "json" "yaml" "toml" "markdown"]
  let parsers_lua = ($parsers | each {|p| $"'($p)'" } | str join ",")
  let lua = ([
    "+lua require('lazy').load({ plugins = { 'nvim-treesitter' } }); require('nvim-treesitter.install').install({"
    $parsers_lua
    "}, {summary=true, force=true})"
  ] | str join "")
  print "  · 安装 nvim 插件 (headless) ..."
  run-cmd [nvim --headless "+Lazy! install" +qa]
  print "  · 编译 treesitter 解析器 (最多 8 轮 × 60 秒) ..."
  let parser_dir = ((nvim-data-dir) | path join "site" "parser")
  let work = (mktemp -d)
  let old = ($env.PWD)
  cd $work
  mut done = false
  mut round = 0
  let count0 = (if ($parser_dir | path exists) { (ls $parser_dir | where type == file | length) } else { 0 })
  if $count0 >= 14 {
    print "    解析器已全部安装 (14/14)"
    $done = true
  }
  while (not $done) and ($round < 8) {
    $round += 1
    let _ = (run-cmd [nvim --headless $lua "+sleep 60" +qa])
    let count = (if ($parser_dir | path exists) { (ls $parser_dir | where type == file | length) } else { 0 })
    print $"    解析器进度: ($count)/14, 第 ($round)/8 轮"
    if $count >= 14 { $done = true }
  }
  cd $old
  rm -rf $work
  $done
}
