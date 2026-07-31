# tools.nu — 跨平台开发工具安装
# 核心: ripgrep / yazi / mise ; 可选: 对标 oh-my-termux 的完整工具集
use ./util.nu *

# 各工具在常见包管理器中的包名
const PKG = {
  ripgrep: {
    windows: { scoop: "ripgrep", winget: "BurntSushi.ripgrep.MSVC", choco: "ripgrep" }
    macos: "ripgrep"
    linux: { "apt-get": "ripgrep", dnf: "ripgrep", pacman: "ripgrep", zypper: "ripgrep", apk: "ripgrep" }
  }
  yazi: {
    windows: { scoop: "yazi", winget: "sxyazi.yazi", choco: "yazi" }
    macos: "yazi"
    linux: { "apt-get": "yazi", dnf: "yazi", pacman: "yazi", zypper: "yazi", apk: "yazi" }
  }
  mise: {
    windows: { scoop: "mise", winget: "jdx.mise", choco: "mise" }
    macos: "mise"
    linux: { "apt-get": "mise", dnf: "mise", pacman: "mise", zypper: "mise", apk: "mise" }
  }
  fd: {
    windows: { scoop: "fd", winget: "sharkdp.fd", choco: "fd" }
    macos: "fd"
    linux: { "apt-get": "fd-find", dnf: "fd-find", pacman: "fd", zypper: "fd", apk: "fd" }
  }
  bat: {
    windows: { scoop: "bat", winget: "sharkdp.bat", choco: "bat" }
    macos: "bat"
    linux: { "apt-get": "bat", dnf: "bat", pacman: "bat", zypper: "bat", apk: "bat" }
  }
  fzf: {
    windows: { scoop: "fzf", winget: "junegunn.fzf", choco: "fzf" }
    macos: "fzf"
    linux: { "apt-get": "fzf", dnf: "fzf", pacman: "fzf", zypper: "fzf", apk: "fzf" }
  }
  zoxide: {
    windows: { scoop: "zoxide", winget: "ajeetdsouza.zoxide", choco: "zoxide" }
    macos: "zoxide"
    linux: { "apt-get": "zoxide", dnf: "zoxide", pacman: "zoxide", zypper: "zoxide", apk: "zoxide" }
  }
  eza: {
    windows: { scoop: "eza", winget: "eza-community.eza", choco: "eza" }
    macos: "eza"
    linux: { "apt-get": "eza", dnf: "eza", pacman: "eza", zypper: "eza", apk: "eza" }
  }
  jq: {
    windows: { scoop: "jq", winget: "jqlang.jq", choco: "jq" }
    macos: "jq"
    linux: { "apt-get": "jq", dnf: "jq", pacman: "jq", zypper: "jq", apk: "jq" }
  }
  lazygit: {
    windows: { scoop: "lazygit", winget: "JesseDuffield.lazygit", choco: "lazygit" }
    macos: "lazygit"
    linux: { "apt-get": "lazygit", dnf: "lazygit", pacman: "lazygit", zypper: "lazygit", apk: "lazygit" }
  }
  delta: {
    windows: { scoop: "delta", winget: "dandavison.delta", choco: "delta" }
    macos: "delta"
    linux: { "apt-get": "delta", dnf: "delta", pacman: "delta", zypper: "delta", apk: "delta" }
  }
  starship: {
    windows: { scoop: "starship", winget: "Starship.Starship", choco: "starship" }
    macos: "starship"
    linux: { "apt-get": "starship", dnf: "starship", pacman: "starship", zypper: "starship", apk: "starship" }
  }
  fastfetch: {
    windows: { scoop: "fastfetch", winget: "Fastfetch-cli.Fastfetch", choco: "fastfetch" }
    macos: "fastfetch"
    linux: { "apt-get": "fastfetch", dnf: "fastfetch", pacman: "fastfetch", zypper: "fastfetch", apk: "fastfetch" }
  }
}

# GitHub Release 兜底下载信息 (jq 只有裸二进制, 不走下载兜底)
const RELEASES = {
  ripgrep: { repo: "BurntSushi/ripgrep", bin: "rg" }
  yazi: { repo: "sxyazi/yazi", bin: "yazi" }
  mise: { repo: "jdx/mise", bin: "mise" }
  fd: { repo: "sharkdp/fd", bin: "fd" }
  bat: { repo: "sharkdp/bat", bin: "bat" }
  fzf: { repo: "junegunn/fzf", bin: "fzf" }
  zoxide: { repo: "ajeetdsouza/zoxide", bin: "zoxide" }
  eza: { repo: "eza-community/eza", bin: "eza" }
  lazygit: { repo: "jesseduffield/lazygit", bin: "lazygit" }
  delta: { repo: "dandavison/delta", bin: "delta" }
  starship: { repo: "starship/starship", bin: "starship" }
  fastfetch: { repo: "fastfetch-cli/fastfetch", bin: "fastfetch" }
}

# 部分发行版包名与二进制名不一致 (apt 的 fd 叫 fdfind)
const BIN_ALIASES = { fd: ["fdfind"] }

# GitHub Release 资产后缀 (2026-07 经 gh api 实测的命名规则)
const SUFFIX = {
  ripgrep: {
    windows: { x64: "x86_64-pc-windows-msvc", arm: "aarch64-pc-windows-msvc" }
    macos: { x64: "x86_64-apple-darwin", arm: "aarch64-apple-darwin" }
    linux: { x64: "x86_64-unknown-linux-musl", arm: "aarch64-unknown-linux-musl" }
  }
  yazi: {
    windows: { x64: "x86_64-pc-windows-msvc", arm: "aarch64-pc-windows-msvc" }
    macos: { x64: "x86_64-apple-darwin", arm: "aarch64-apple-darwin" }
    linux: { x64: "x86_64-unknown-linux-gnu", arm: "aarch64-unknown-linux-gnu" }
  }
  mise: {
    windows: { x64: "windows-x64", arm: "windows-arm64" }
    macos: { x64: "macos-x64", arm: "macos-arm64" }
    linux: { x64: "linux-x64", arm: "linux-arm64" }
  }
  fd: {
    windows: { x64: "x86_64-pc-windows-msvc", arm: "aarch64-pc-windows-msvc" }
    macos: { x64: "x86_64-apple-darwin", arm: "aarch64-apple-darwin" }
    linux: { x64: "x86_64-unknown-linux-gnu", arm: "aarch64-unknown-linux-gnu" }
  }
  bat: {
    windows: { x64: "x86_64-pc-windows-msvc", arm: "aarch64-pc-windows-msvc" }
    macos: { x64: "x86_64-apple-darwin", arm: "aarch64-apple-darwin" }
    linux: { x64: "x86_64-unknown-linux-gnu", arm: "aarch64-unknown-linux-gnu" }
  }
  fzf: {
    windows: { x64: "windows_amd64", arm: "windows_arm64" }
    macos: { x64: "darwin_amd64", arm: "darwin_arm64" }
    linux: { x64: "linux_amd64", arm: "linux_arm64" }
  }
  zoxide: {
    windows: { x64: "x86_64-pc-windows-msvc", arm: "aarch64-pc-windows-msvc" }
    macos: { x64: "x86_64-apple-darwin", arm: "aarch64-apple-darwin" }
    linux: { x64: "x86_64-unknown-linux-musl", arm: "aarch64-unknown-linux-musl" }
  }
  eza: {
    windows: { x64: "x86_64-pc-windows-gnu", arm: "x86_64-pc-windows-gnu" }
    macos: { x64: "", arm: "" }
    linux: { x64: "x86_64-unknown-linux-gnu", arm: "aarch64-unknown-linux-gnu" }
  }
  lazygit: {
    windows: { x64: "windows_x86_64", arm: "windows_arm64" }
    macos: { x64: "darwin_x86_64", arm: "darwin_arm64" }
    linux: { x64: "linux_x86_64", arm: "linux_arm64" }
  }
  delta: {
    windows: { x64: "x86_64-pc-windows-msvc", arm: "" }
    macos: { x64: "x86_64-apple-darwin", arm: "aarch64-apple-darwin" }
    linux: { x64: "x86_64-unknown-linux-gnu", arm: "aarch64-unknown-linux-gnu" }
  }
  starship: {
    windows: { x64: "x86_64-pc-windows-msvc", arm: "aarch64-pc-windows-msvc" }
    macos: { x64: "x86_64-apple-darwin", arm: "aarch64-apple-darwin" }
    linux: { x64: "x86_64-unknown-linux-gnu", arm: "aarch64-unknown-linux-musl" }
  }
  fastfetch: {
    windows: { x64: "windows-amd64", arm: "windows-aarch64" }
    macos: { x64: "macos-amd64", arm: "macos-aarch64" }
    linux: { x64: "linux-amd64", arm: "linux-aarch64" }
  }
}

# 归档扩展名白名单 (排除 .deb/.rpm/.msi/.7z 等)
const ARCH_EXT = ["zip" "tar.gz" "tar.xz" "tar.zst"]

# 安装核心工具 + 可选 extras
export def install-tools [--with-extra]: nothing -> bool {
  print ""
  print $"(ansi cyan)── 开发工具 ──────────────────────────(ansi reset)"
  let mgr = (pkg-manager)
  if ($mgr | is-empty) {
    print $"(ansi yellow)! 未检测到包管理器, 将全部走 GitHub Release 下载(ansi reset)"
  }
  let core = (["ripgrep" "yazi" "mise"] | each {|t| install-one $t } | all {|x| $x })
  let extra = (if $with_extra {
    print $"(ansi cyan)── 可选工具: 对标 oh-my-termux ────────(ansi reset)"
    let list = (["fd" "bat" "fzf" "zoxide" "eza" "jq" "lazygit" "delta" "starship" "fastfetch"])
    let ok = ($list | each {|t| install-one $t } | all {|x| $x })
    let git_ok = (setup-git-extras)
    $ok and $git_ok
  } else { true })
  $core and $extra
}

# 安装单个工具: 先查包管理器, 失败则 GitHub Release
export def install-one [tool: string]: nothing -> bool {
  let meta = ($RELEASES | get -o $tool)
  let names = ((if ($meta | is-empty) { [$tool] } else { [$tool $meta.bin] | uniq })
    | append ($BIN_ALIASES | get -o $tool | default [])) | uniq
  if ($names | any {|n| print-installed $n }) { return true }
  print $"  · 安装 ($tool) ..."
  if (is-dry-run) {
    print "    (预览) 将通过包管理器或 GitHub Release 安装"
    return true
  }
  let pkg = (package-name $tool)
  if ($pkg | is-not-empty) and (package-install $pkg) and ($names | any {|n| (which $n | is-not-empty) }) {
    return true
  }
  print $"(ansi yellow)! 包管理器安装未成功, 尝试 GitHub Release(ansi reset)"
  if (github-fallback $tool) {
    print $"(ansi green)✓(ansi reset) ($tool) 安装完成 (GitHub Release)"
    return true
  }
  print $"(ansi red)✗(ansi reset) 无法自动安装 ($tool), 请手动安装后重试"
  false
}

# 查当前平台包名
def package-name [tool: string]: nothing -> string {
  let entry = ($PKG | get -o $tool)
  if ($entry | is-empty) { return "" }
  let os_entry = ($entry | get -o (os))
  if ($os_entry | is-empty) { return "" }
  if ($os_entry | describe) =~ "record" {
    let mgr = (pkg-manager)
    if ($mgr | is-empty) { return "" }
    ($os_entry | get -o $mgr | default "")
  } else {
    $os_entry
  }
}

# GitHub Release 资产后缀 (按平台/架构)
def release-suffix [tool: string]: nothing -> string {
  let entry = ($SUFFIX | get -o $tool)
  if ($entry | is-empty) { return "" }
  let os_entry = ($entry | get -o (os))
  if ($os_entry | is-empty) { return "" }
  let a = ($nu.os-info.arch)
  let key = (if (($a | str contains "aarch") or ($a | str contains "arm")) { "arm" } else { "x64" })
  ($os_entry | get -o $key | default "")
}

# 从 GitHub Release 下载、解压、安装到用户 bin 目录
export def github-fallback [tool: string]: nothing -> bool {
  let meta = ($RELEASES | get -o $tool)
  if ($meta | is-empty) { return false }
  let suffix = (release-suffix $tool)
  if ($suffix | is-empty) {
    print -e $"    ($tool) 暂无当前平台的 Release 资产, 请改用包管理器安装"
    return false
  }
  let url = $"https://api.github.com/repos/($meta.repo)/releases/latest"
  let rel = (try {
    (http get --full $url).content | from json
  } catch {
    |e| print -e $"    GitHub API 请求失败: ($e.msg)"
    return false
  })
  let assets = ($rel.assets | where {|a|
    ($a.name | str contains $suffix) and ($ARCH_EXT | any {|e| $a.name | str ends-with $e })
  })
  if ($assets | is-empty) {
    print -e $"    未找到包含 '($suffix)' 的归档资产"
    return false
  }
  let asset = ($assets | first)
  print $"  · 下载 ($asset.name)"
  let tmp = (mktemp)
  let dl = (try {
    http get $asset.browser_download_url | save --raw $tmp
    true
  } catch { |e|
    print -e $"    下载失败: ($e.msg)"
    false
  })
  if not $dl { return false }
  let ex = (mktemp -d)
  do -i { run-external tar "-xf" $tmp "-C" $ex }
  if $env.LAST_EXIT_CODE != 0 {
    print -e "    解压失败"
    rm -rf $ex $tmp
    return false
  }
  let ext = (if (is-windows) { ".exe" } else { "" })
  let found = (ls ($ex | path join "**" $"($meta.bin)($ext)") | where type == file | get name)
  if ($found | is-empty) {
    print -e $"    压缩包内未找到 ($meta.bin)"
    rm -rf $ex $tmp
    return false
  }
  let bindir = (bin-dir)
  mkdir $bindir
  cp ($found | first) ($bindir | path join $meta.bin)
  ensure-bin-in-path
  rm -rf $ex $tmp
  true
}

# Git + Delta + Lazygit 联动 (对标 oh-my-termux 的版本控制组合)
export def setup-git-extras []: nothing -> bool {
  if not (has git) { return true }
  if not (has delta) and not (has lazygit) { return true }
  print $"(ansi cyan)── Git 集成: delta + lazygit ──────────(ansi reset)"
  mut ok = true
  if (has delta) {
    if not (run-cmd [git config --global core.pager delta]) { $ok = false }
    if not (run-cmd [git config --global delta.navigate "true"]) { $ok = false }
    if not (run-cmd [git config --global interactive.diffFilter "delta --color-only"]) { $ok = false }
  }
  if (has lazygit) {
    if not (run-cmd [git config --global alias.lg lazygit]) { $ok = false }
  }
  $ok
}
