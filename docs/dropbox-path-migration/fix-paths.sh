#!/usr/bin/env bash
# fix-paths.sh — Dropbox 改團隊帳號後的一次性路徑修復
#
# 做三件事（都會先備份，不刪任何東西）：
#   1. 修 ~/.claude/settings.json 裡 Obsidian MCP 寫死的 vault 路徑
#   2. 把舊路徑的專案長期記憶「複製」到新路徑對應的資料夾（內容不動）
#   3. 檢查 Obsidian vault 資料夾在不在，並印出接下來要點什麼
#
# 用法：bash fix-paths.sh          # 實際執行
#       bash fix-paths.sh --dry-run # 只看會做什麼，不動任何檔案

set -euo pipefail
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8   # 中文路徑用，見 dropbox_path_gotchas.md

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1 && echo "🔍 DRY RUN — 不會實際修改任何檔案"

say()  { echo "$@"; }
# mtime：先偵測一次用哪種 stat（GNU 是 -c %Y，macOS/BSD 是 -f %m）。
# 注意不能靠「-f 失敗就換 -c」判斷：GNU 的 -f 是「檔案系統資訊」，會成功但吐錯東西。
if stat -c %Y . >/dev/null 2>&1; then _STAT_MTIME="stat -c %Y"; else _STAT_MTIME="stat -f %m"; fi
mtime() { $_STAT_MTIME "$1" 2>/dev/null || echo 0; }
newest_mtime() {
  local best=0 t f
  while IFS= read -r f; do t=$(mtime "$f"); [ "${t:-0}" -gt "$best" ] && best=$t; done \
    < <(find "$1" -type f 2>/dev/null)
  echo "$best"
}
do_it() {
  if [ $DRY -eq 1 ]; then echo "      (dry-run，略過)"; return 0; fi
  if ! eval "$@"; then
    echo "   ❌ 指令失敗：$*" >&2
    echo "      沒有東西被刪除，可安全重跑。" >&2
    exit 1
  fi
}

# ── 找 Dropbox 個人根目錄 ────────────────────────────────
find_dropbox_home() {
  local c
  for c in \
    "${DROPBOX_HOME:-}" \
    "$HOME/Library/CloudStorage/Dropbox/Lee Chunying" \
    "$HOME/Dropbox/Lee Chunying" \
    "$HOME/Library/CloudStorage/Dropbox" \
    "$HOME/Dropbox"
  do
    [ -n "$c" ] || continue
    if [ -d "$c/.claude-sync" ] || [ -d "$c/secondbrain" ]; then printf '%s' "$c"; return 0; fi
  done
  return 1
}

if ! DBX=$(find_dropbox_home); then
  echo "❌ 找不到 Dropbox 個人根目錄。請先確認 Dropbox 有同步下來，或："
  echo "   export DROPBOX_HOME=\"/你的/實際/路徑\" && bash fix-paths.sh"
  exit 1
fi

VAULT="$DBX/secondbrain"
say "📂 Dropbox 根目錄：$DBX"
say "📓 Obsidian vault：$VAULT"
say ""

# ── 1. 修 settings.json 的 Obsidian MCP 路徑 ─────────────
say "── 1. 修 ~/.claude/settings.json 的 Obsidian MCP 路徑 ──"
SETTINGS="$HOME/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  say "   ⚠️  找不到 $SETTINGS，略過（可能這台沒設過 MCP）"
else
  if [ $DRY -eq 0 ]; then
    cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"
  fi
  VAULT="$VAULT" python3 - "$SETTINGS" "$DRY" <<'PY'
import json, os, re, sys
path, dry = sys.argv[1], sys.argv[2] == "1"
vault = os.environ["VAULT"]
data = json.load(open(path, encoding="utf-8"))
# 任何長得像 .../Dropbox/.../secondbrain 的參數，一律指回正確的 vault
pat = re.compile(r"^.*/Dropbox/(?:[^/]+/)*secondbrain/?$")
changed = []
for name, srv in (data.get("mcpServers") or {}).items():
    args = srv.get("args")
    if not isinstance(args, list):
        continue
    for i, a in enumerate(args):
        if isinstance(a, str) and pat.match(a) and a.rstrip("/") != vault.rstrip("/"):
            changed.append(f"     {name}: {a}\n            → {vault}")
            args[i] = vault
if not changed:
    print("   ✅ 沒有需要修改的路徑（可能已經是對的）")
else:
    print("   需要修改：")
    for c in changed:
        print(c)
    if dry:
        print("      (dry-run，略過)")
    else:
        json.dump(data, open(path, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        print("   ✅ 已寫入（原檔已備份為 settings.json.bak-*）")
PY
fi
say ""

# ── 2. 把舊專案記憶接到新路徑 ────────────────────────────
say "── 2. 把長期專案記憶接到新的 vault 路徑（複製，不搬不刪）──"
PROJ="$HOME/.claude/projects"
NEW_KEY="$(printf '%s' "$VAULT" | sed 's|/|-|g')"
say "   新路徑對應的資料夾名：$NEW_KEY"
if [ ! -d "$PROJ" ]; then
  say "   ⚠️  找不到 $PROJ，略過"
else
  # 找出所有舊的 secondbrain 專案資料夾（依 memory 最後修改時間，取最新的那個）
  BEST=""; BEST_T=0
  while IFS= read -r d; do
    [ -d "$d/memory" ] || continue
    b=$(basename "$d")
    [ "$b" = "$NEW_KEY" ] && continue
    t=$(newest_mtime "$d/memory")
    if [ "$t" -gt "$BEST_T" ]; then BEST_T=$t; BEST="$d"; fi
  done < <(find "$PROJ" -maxdepth 1 -type d -name '*secondbrain')

  if [ -z "$BEST" ]; then
    say "   ℹ️  沒找到舊的 secondbrain 記憶資料夾，不需要搬"
  else
    say "   來源（最新的舊記憶）：$(basename "$BEST")"
    say "   目標：$NEW_KEY"
    say "   檔案數：$(find "$BEST/memory" -type f | wc -l | tr -d ' ')"
    do_it "mkdir -p \"$PROJ/$NEW_KEY/memory\""
    if command -v rsync >/dev/null 2>&1; then
      # -a 保留時間戳，-u 只補新的、不覆蓋目標較新的檔；不加 --delete，絕不刪東西
      do_it "rsync -au \"$BEST/memory/\" \"$PROJ/$NEW_KEY/memory/\""
    else
      say "   ℹ️  沒有 rsync，改用 cp -Rpn（不覆蓋既有檔案）"
      do_it "cp -Rpn \"$BEST/memory/.\" \"$PROJ/$NEW_KEY/memory/\" 2>/dev/null || true"
    fi
    if [ $DRY -eq 0 ]; then
      n=$(find "$PROJ/$NEW_KEY/memory" -type f | wc -l | tr -d " ")
      say "   ✅ 已複製 $n 個檔案（舊資料夾原封不動留著）"
    fi
  fi
fi
say ""

# ── 3. 檢查 vault 並印出後續步驟 ─────────────────────────
say "── 3. Obsidian vault 檢查 ──"
if [ -d "$VAULT/.obsidian" ]; then
  say "   ✅ vault 設定資料夾在：$VAULT/.obsidian"
  say "      （代表外觀、外掛、快捷鍵都會原封不動回來）"
elif [ -d "$VAULT" ]; then
  say "   ⚠️  找得到 $VAULT，但裡面沒有 .obsidian/ — 確認一下 Dropbox 同步完了沒"
else
  say "   ❌ 找不到 $VAULT — Dropbox 可能還沒同步下來"
fi
say ""
say "════════════════════════════════════════════════════"
say "接下來在 Obsidian 手動做一次（腳本沒辦法代點）："
say ""
say "  1. 點「開啟資料夾為儲存庫」的〔開啟〕"
say "     ⚠️ 不要點「建立新的儲存庫」，那會建出一個空的"
say "  2. 檔案選擇視窗跳出後，按 Cmd + Shift + G"
say "  3. 貼上這一行然後 Enter："
say ""
say "     $VAULT"
say ""
say "  4. 選這個資料夾 →〔開啟〕。筆記和設定就全回來了。"
say ""
say "做完後重開 Claude Code，讓新的 settings.json 生效。"
say "════════════════════════════════════════════════════"
