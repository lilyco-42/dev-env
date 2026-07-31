# util.nu — 跨平台工具函数
#
# 原则: 只用 nushell 原语与三平台通用的外部命令,
#       不出现 pwsh / bash 专用逻辑。所有平台共享同一份代码。

export def os []: nothing -> string {
  $nu.os-info.name
}

export def is-windows []: nothing -> bool { (os) == "windows" }
export def is-macos []: nothing -> bool { (os) == "macos" }
export def is-linux []: nothing -> bool { (os) == "linux" }

# Termux (Android) 检测: $PREFIX 指向 com.termux 目录
export def is-termux []: nothing -> bool {
  ((($env.PREFIX? | default "") | str contains "com.termux") or (($env.TERMUX_VERSION? | default "") | is-not-empty))
}

# 命令是否可用
export def has [cmd: string]: nothing -> bool {
  (which $cmd | is-not-empty)
}

# 是否以 root 运行 (仅 unix 有意义)
export def is-root []: nothing -> bool {
  if (is-windows) { return false }
  try {
    ((do -i { run-external id "-u" } | str trim | into int) == 0)
  } catch { false }
}

export def is-dry-run []: nothing -> bool {
  ($env.DEVENV_DRY_RUN? | default "0") == "1"
}

# 检测可用的包管理器 (按优先级)
export def pkg-manager []: nothing -> string {
  if (is-termux) {
    if (has pkg) { return "pkg" }
    if (has apt-get) { return "apt-get" }
    return ""
  }
  if (is-windows) {
    for p in ["scoop" "winget" "choco"] {
      if (has $p) { return $p }
    }
    return ""
  }
  if (is-macos) {
    if (has brew) { return "brew" }
    return ""
  }
  for p in ["apt-get" "dnf" "pacman" "zypper" "apk" "nix-env"] {
    if (has $p) { return $p }
  }
  ""
}

# 运行命令并返回是否成功 (dry-run 时仅打印)
export def run-cmd [cmd: list<string>]: nothing -> bool {
  print $"(ansi cyan)»(ansi reset) ($cmd | str join ' ')"
  if (is-dry-run) { return true }
  do -i { run-external ($cmd.0) ...($cmd | skip 1) }
  $env.LAST_EXIT_CODE == 0
}

# 需要提权时自动加 sudo (root 或 Windows 不加)
export def run-sudo [cmd: list<string>]: nothing -> bool {
  if (is-windows) { return (run-cmd $cmd) }
  if (is-termux) { return (run-cmd $cmd) }
  if (is-root) { return (run-cmd $cmd) }
  run-cmd (["sudo"] | append $cmd)
}

# 通过当前平台包管理器安装一个包
export def package-install [pkg: string]: nothing -> bool {
  let mgr = (pkg-manager)
  if (is-windows) {
    if $mgr == "scoop" { return (run-cmd [scoop install $pkg]) }
    if $mgr == "winget" {
      return (run-cmd [winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements])
    }
    if $mgr == "choco" { return (run-cmd [choco install -y $pkg]) }
    return false
  }
  if (is-macos) {
    return (if (pkg-manager) == "brew" { run-cmd [brew install $pkg] } else { false })
  }
  match $mgr {
    "pkg" => (run-cmd [pkg install -y $pkg])
    "apt-get" => { let _ = (run-sudo [apt-get update]); run-sudo [apt-get install -y $pkg] }
    "dnf" => (run-sudo [dnf install -y $pkg])
    "pacman" => (run-sudo [pacman -S --noconfirm $pkg])
    "zypper" => (run-sudo [zypper install -y $pkg])
    "apk" => (run-sudo [apk add $pkg])
    "nix-env" => (run-cmd [nix-env -iA nixpkgs $pkg])
    _ => false
  }
}

# 用户级 bin 目录
export def bin-dir []: nothing -> path {
  if (is-windows) { return ($env.LOCALAPPDATA | path join "bin") }
  ($env.HOME? | default "") | path join ".local" "bin"
}

# 把 bin-dir 加入当前会话 PATH (持久化由用户自行配置)
export def ensure-bin-in-path []: nothing -> bool {
  let dir = (bin-dir)
  let sep = (char esep)
  let parts = ($env.PATH | split row $sep)
  if ($parts | any {|p| ($p | str trim | str lowercase) == ($dir | str lowercase) }) {
    return true
  }
  $env.PATH = ($parts | prepend $dir | str join $sep)
  true
}

# 工具已安装时打印位置
export def print-installed [tool: string]: nothing -> bool {
  let w = (which $tool)
  if ($w | is-empty) { return false }
  print $"(ansi green)✓(ansi reset) ($tool) 已可用: ($w.0.path)"
  true
}
