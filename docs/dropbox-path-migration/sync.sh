#!/usr/bin/env bash
# claude-sync — 雙向同步 Claude Code 設定、記憶與計畫
#
# 用法：在任何一台電腦執行 `claude-sync` 即可。
# 邏輯：較新者勝（rsync -au），同步前先在 Dropbox 留一份本機備份。
#
# 會同步：
#   - ~/.claude/settings.json
#   - ~/.claude/projects/*/memory/   （每個專案的長期記憶）
#   - ~/.claude/plans/                （計畫文件，若有）
#
# 不同步：
#   - 對話紀錄 *.jsonl   （每台電腦獨立）
#   - sessions / shell-snapshots / telemetry / ide / backups
#   - tool-results / session-env
#
# 跨使用者名稱：
#   雲端用 `_USER_` 佔位符取代本機使用者名稱，所以兩台 Mac 即使
#   帳號名稱不同（例：chun-yinglee vs lichunying）也能正確對應。
#
# 2026-09 修正：Dropbox 改為團隊帳號後，個人資料改掛在「Lee Chunying」
#   這層底下，且 macOS 走 ~/Library/CloudStorage/。原本寫死的
#   $HOME/Dropbox/.claude-sync 會找不到路徑，改為自動偵測，
#   避免日後 Dropbox 再次調整掛載方式時又整個斷掉。

set -e

# ── 自動偵測 Dropbox 個人根目錄 ─────────────────────────────
# 依序試常見位置，取第一個真的裝著 .claude-sync 或 secondbrain 的。
# 可用環境變數 DROPBOX_HOME 覆寫（例：export DROPBOX_HOME=/path/to/dropbox）。
find_dropbox_home() {
  local c
  for c in \
    "$DROPBOX_HOME" \
    "$HOME/Library/CloudStorage/Dropbox/Lee Chunying" \
    "$HOME/Dropbox/Lee Chunying" \
    "$HOME/Library/CloudStorage/Dropbox" \
    "$HOME/Dropbox"
  do
    [ -n "$c" ] || continue
    if [ -d "$c/.claude-sync" ] || [ -d "$c/secondbrain" ]; then
      printf '%s' "$c"
      return 0
    fi
  done
  return 1
}

if ! DROPBOX_ROOT=$(find_dropbox_home); then
  echo "❌ 找不到 Dropbox 個人根目錄（裡面應該要有 .claude-sync/ 或 secondbrain/）。" >&2
  echo "   已試過：" >&2
  echo "     ~/Library/CloudStorage/Dropbox/Lee Chunying" >&2
  echo "     ~/Dropbox/Lee Chunying" >&2
  echo "     ~/Library/CloudStorage/Dropbox" >&2
  echo "     ~/Dropbox" >&2
  echo "   若路徑不同，請設定後重跑：export DROPBOX_HOME=\"/你的/實際/路徑\"" >&2
  exit 1
fi

SHARED="$DROPBOX_ROOT/.claude-sync"
DATA="$SHARED/data"
LOCAL="$HOME/.claude"
HOST=$(hostname -s)
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="$SHARED/.backup/$HOST-$STAMP"

# 使用者名稱與佔位符（用於專案目錄名稱的轉換）
LOCAL_USER=$(whoami)
USER_PREFIX="-Users-${LOCAL_USER}-"
PLACEHOLDER="-Users-_USER_-"

echo "🔄 Claude Code 同步中（$HOST，使用者：$LOCAL_USER）..."
echo "   📂 Dropbox：$DROPBOX_ROOT"

mkdir -p "$DATA/projects" "$SHARED/.backup" "$BACKUP"

# ── 1. 備份本機現況到 Dropbox（保險用，可隨時還原）──────────
[ -f "$LOCAL/settings.json" ] && cp "$LOCAL/settings.json" "$BACKUP/settings.json" 2>/dev/null || true

if [ -d "$LOCAL/projects" ]; then
  for proj in "$LOCAL/projects"/*/; do
    [ -d "${proj}memory" ] || continue
    name=$(basename "$proj")
    mkdir -p "$BACKUP/projects/$name"
    rsync -a "${proj}memory/" "$BACKUP/projects/$name/memory/" 2>/dev/null || true
  done
fi

[ -d "$LOCAL/plans" ] && rsync -a "$LOCAL/plans/" "$BACKUP/plans/" 2>/dev/null || true

# 若備份目錄是空的，移除（避免堆積空殼）
if [ -z "$(find "$BACKUP" -mindepth 1 -print -quit 2>/dev/null)" ]; then
  rmdir "$BACKUP" 2>/dev/null || true
  BACKUP=""
fi

# ── 2. 拉取雲端最新版（cloud → local，雲端佔位符 → 本機使用者）──
echo "  📥 拉取雲端 → 本機"
[ -f "$DATA/settings.json" ] && rsync -au "$DATA/settings.json" "$LOCAL/settings.json"

if [ -d "$DATA/projects" ]; then
  for proj in "$DATA/projects"/*/; do
    [ -d "${proj}memory" ] || continue
    cloud_name=$(basename "$proj")
    # 把 _USER_ 佔位符換成本機真正的使用者名稱
    local_name="${cloud_name/$PLACEHOLDER/$USER_PREFIX}"
    mkdir -p "$LOCAL/projects/$local_name/memory"
    rsync -au "${proj}memory/" "$LOCAL/projects/$local_name/memory/"
  done
fi

if [ -d "$DATA/plans" ]; then
  mkdir -p "$LOCAL/plans"
  rsync -au "$DATA/plans/" "$LOCAL/plans/"
fi

# ── 3. 推送本機最新版（local → cloud，本機使用者 → 佔位符）─────
echo "  📤 推送本機 → 雲端"
[ -f "$LOCAL/settings.json" ] && rsync -au "$LOCAL/settings.json" "$DATA/settings.json"

if [ -d "$LOCAL/projects" ]; then
  for proj in "$LOCAL/projects"/*/; do
    [ -d "${proj}memory" ] || continue
    local_name=$(basename "$proj")
    # 把本機使用者名稱換成 _USER_ 佔位符
    cloud_name="${local_name/$USER_PREFIX/$PLACEHOLDER}"
    mkdir -p "$DATA/projects/$cloud_name/memory"
    rsync -au "${proj}memory/" "$DATA/projects/$cloud_name/memory/"
  done
fi

[ -d "$LOCAL/plans" ] && mkdir -p "$DATA/plans" && rsync -au "$LOCAL/plans/" "$DATA/plans/"

# ── 4. 自動清理 30 天前的備份 ─────────────────────────────
find "$SHARED/.backup" -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true

echo "✅ 同步完成"
[ -n "$BACKUP" ] && echo "   📦 本機備份：$BACKUP"
echo "   ℹ️  下一台電腦：等 Dropbox 同步完成後執行 \`claude-sync\` 即可"
