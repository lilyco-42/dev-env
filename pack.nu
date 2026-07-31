#!/usr/bin/env nu
# pack.nu — 自压缩打包工具
#
# 把 src/ 下的源码与资源压缩进单个文件; 产物运行时自解压到临时目录,
# 再调用 nushell 执行 install.nu。全平台同一个产物, 不依赖 pwsh/bash。
# 压缩格式: tar.gz (三平台自带 tar); 无 tar 时回退 base64 直存。
#
# 用法:
#   nu pack.nu                 # 生成 dist/dev-env.nu
#   nu pack.nu --no-compress   # 仅 base64 打包 (调试)
#   nu pack.nu --out build/dev-env.nu

const VERSION = "0.1.1"

def print-help [] {
  print "pack.nu — dev-env 自压缩打包工具"
  print ""
  print "用法:"
  print "  nu pack.nu [--src <dir>] [--out <file>] [--no-compress] [--verbose] [--help]"
  print ""
  print "选项:"
  print "  --src <dir>        源码目录 (默认: src)"
  print "  --out <file>       产物路径 (默认: dist/dev-env.nu)"
  print "  --no-compress      不压缩, 只做 base64 打包"
  print "  --verbose          打印详细过程"
  print "  --help             显示帮助"
}

def has-tar []: nothing -> bool {
  (which tar | is-not-empty)
}

def collect-files [src: path]: nothing -> list<path> {
  glob $"($src)/**/*"
    | where {|p| ($p | path type) == "file"}
    | sort
}

def copy-to-stage [files: list<path>, src: path, stage: path]: nothing -> list<string> {
  $files | each { |f|
    let rel = ($f | path relative-to ($src | path expand) | str replace -a "\\" "/")
    let dest = ($stage | path join $rel)
    mkdir ($dest | path dirname)
    cp $f $dest
    $rel
  }
}

# 把 base64 按宽度折行, 方便产物阅读
def wrap-b64 [s: string, width: int = 100]: nothing -> string {
  let n = ($s | str length)
  0..(($n // $width)) | each { |i|
    let start = ($i * $width)
    let stop = ([($start + $width - 1) ($n - 1)] | math min)
    $s | str substring $start..$stop
  } | str join "\n"
}

def build-targz [stage: path, rels: list<string>]: nothing -> string {
  let payload = ($stage | path join "payload.bin")
  run-external tar "-czf" $payload "-C" $stage ...$rels
  if $env.LAST_EXIT_CODE != 0 { error make { msg: "tar 打包失败" } }
  open --raw $payload | encode base64
}

def build-raw [stage: path, rels: list<string>]: nothing -> string {
  $rels | each { |rel|
    let b64 = (open --raw ($stage | path join $rel) | encode base64)
    $"($rel)\t($b64)"
  } | str join "\n" | encode base64
}

# 生成自解压产物 (模板 + 占位符替换)
def render [b64: string, format: string, out: path]: nothing -> record<size: int> {
  let wrapped = (wrap-b64 $b64)
  let tpl = "
#!/usr/bin/env nu
# dev-env — 自解压跨平台开发环境安装器 (由 pack.nu 生成, 请勿手改)
# 重新打包: nu pack.nu ; 查看内置源码: nu <本文件> --self-extract <目录>
const VERSION = \"__VERSION__\"
const PAYLOAD_FORMAT = \"__PAYLOAD_FORMAT__\"
const PAYLOAD_B64 = \"__PAYLOAD_B64__\"

def extract [dir: path] {
  let payload = ($dir | path join \"payload.bin\")
  ($PAYLOAD_B64
    | str replace -a \"\\r\" \"\"
    | str replace -a \"\\n\" \"\"
    | decode base64
    | save --raw $payload)
  if ($PAYLOAD_FORMAT == \"tar.gz\") {
    run-external tar \"-xzf\" $payload \"-C\" $dir
    if $env.LAST_EXIT_CODE != 0 { error make { msg: \"解压失败 (tar)\" } }
  } else {
    let manifest = (open --raw $payload | decode utf-8)
    for line in ($manifest | str trim | lines) {
      if ($line | is-empty) { continue }
      let parts = ($line | split row \"\t\")
      if ($parts | length) < 2 { continue }
      let dest = ($dir | path join ($parts | get 0))
      mkdir ($dest | path dirname)
      (($parts | get 1) | decode base64 | save --raw $dest)
    }
  }
  rm $payload
}

def main [
  --dry-run
  --no-neovim
  --no-tools
  --with-extra
  --with-parsers
  --version
  --help
  --self-extract: string
  ...rest: string
] {
  if $version {
    print $\"dev-env ($VERSION) — 自解压跨平台开发环境安装器\"
    return
  }
  if not ($self_extract | is-empty) {
    mkdir $self_extract
    extract $self_extract
    print $\"✓ 已解压到 ($self_extract)\"
    return
  }
  let tmp = (mktemp -d)
  let rc = (try {
    extract $tmp
    $env.DEVENV_ROOT = $tmp
    mut child_args = []
    if $dry_run { $child_args = ($child_args | append \"--dry-run\") }
    if $no_neovim { $child_args = ($child_args | append \"--no-neovim\") }
    if $no_tools { $child_args = ($child_args | append \"--no-tools\") }
    if $with_extra { $child_args = ($child_args | append \"--with-extra\") }
    if $with_parsers { $child_args = ($child_args | append \"--with-parsers\") }
    if $help { $child_args = ($child_args | append \"--help\") }
    $child_args = ($child_args | append $rest)
    run-external ($nu.current-exe) ($tmp | path join \"install.nu\") ...$child_args
    $env.LAST_EXIT_CODE
  } catch { |e|
    print -e $\"(ansi red)✗(ansi reset) 运行失败: ($e.msg)\"
    1
  })
  rm -rf $tmp
  exit $rc
}
"
  let content = ($tpl
    | str trim
    | str replace "__VERSION__" $VERSION
    | str replace "__PAYLOAD_FORMAT__" $format
    | str replace "__PAYLOAD_B64__" $wrapped)
  mkdir ($out | path dirname)
  $content | save --force --raw $out
  { size: ($content | str length) }
}

export def main [
  --src: path = "src"
  --out: path = "dist/dev-env.nu"
  --no-compress
  --verbose
  --help
] {
  if $help { print-help; return }
  let files = (collect-files $src)
  if ($files | is-empty) {
    print -e $"错误: ($src) 下没有可打包文件"
    exit 1
  }
  print $"打包 ($files | length) 个文件 → ($out)"
  let stage = (mktemp -d)
  let rc = (try {
    let rels = (copy-to-stage $files $src $stage)
    mut format = (if $no_compress { "raw" } else { "tar.gz" })
    if $format == "tar.gz" and not (has-tar) {
      print $"(ansi yellow)! 未找到 tar, 回退到 raw 模式(ansi reset)"
      $format = "raw"
    }
    let b64 = (if $format == "tar.gz" { build-targz $stage $rels } else { build-raw $stage $rels })
    let info = (render $b64 $format $out)
    let kb = (($info.size / 1024.0) | math round --precision 1)
    print $"(ansi green)✓ 已生成(ansi reset) ($out)  ($kb) KB, 格式=($format), 内含 ($rels | length) 个文件"
    0
  } catch { |e|
    print -e $"(ansi red)✗ 打包失败(ansi reset): ($e.msg)"
    1
  })
  rm -rf $stage
  exit $rc
}
