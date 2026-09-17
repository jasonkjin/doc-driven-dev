#!/usr/bin/env bash
# 安装 doc-driven-dev:把 skill 与命令拷进 Claude Code 的配置目录。
# 已存在的同名文件会先备份到 <文件>.bak.<时间戳>。
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILL_DIR="$CLAUDE_DIR/skills/ddd"
CMD_DIR="$CLAUDE_DIR/commands"
STAMP="$(date +%Y%m%d%H%M%S)"

mkdir -p "$SKILL_DIR" "$CMD_DIR"

install_file() {
  local src="$1" dst="$2"
  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
    cp "$dst" "$dst.bak.$STAMP"
    echo "  备份 $dst -> $dst.bak.$STAMP"
  fi
  cp "$src" "$dst"
  echo "  安装 $dst"
}

echo "安装 skill 到 $SKILL_DIR"
for f in "$SRC"/skills/ddd/*.md; do
  install_file "$f" "$SKILL_DIR/$(basename "$f")"
done

echo "安装命令到 $CMD_DIR"
for f in "$SRC"/commands/ddd-*.md; do
  install_file "$f" "$CMD_DIR/$(basename "$f")"
done

cat <<'TIP'

完成。下一步:
  1. 在工作区目录启动 Claude Code,通过 settings 或 --add-dir 授权业务仓库目录
  2. /ddd-init <repo别名> <仓库路径>   为每个仓库建一次长期档案
  3. /ddd-spec <槽位名>                 开始第一个任务

工作区 ~/ddd/ 由 /ddd-init 首次运行时自动建立,建议初始化为私有 git 仓库用于版本追溯与备份。
TIP
