# Claude Code 跨電腦同步

> ⚠️ 2026-09 更新：Dropbox 改成團隊帳號（屏東縣慢性病防治整合計畫）後，
> 個人資料全部改掛在 **`Lee Chunying/`** 這一層底下，macOS 也改走
> `~/Library/CloudStorage/`。本文所有路徑已同步更新。

## 日常使用（兩台電腦都一樣）

工作前 → 開 Terminal 打：

```
claude-sync
```

工作後 → 同樣再打一次：

```
claude-sync
```

就這樣。同一個指令做雙向同步，較新者勝。

---

## 同步什麼

✅ 會同步：
- `~/.claude/settings.json`（MCP server 設定等）
- `~/.claude/projects/*/memory/`（每個專案的長期記憶）
- `~/.claude/plans/`（計畫文件，若有）

❌ 不同步：
- 對話紀錄 `*.jsonl`（每台電腦獨立，避免亂掉）
- sessions / shell-snapshots / telemetry / ide / tool-results

> Obsidian vault（`secondbrain/`）和進度筆記本來就在 Dropbox 裡，會自動同步，不需要這個腳本管。

---

## 第一次到一台新 Mac？

只要做一次：

```bash
echo "alias claude-sync='bash \"\$HOME/Library/CloudStorage/Dropbox/Lee Chunying/.claude-sync/sync.sh\"'" >> ~/.zshrc
source ~/.zshrc
claude-sync
```

完成。之後就跟另一台電腦一樣，每次工作前後打 `claude-sync`。

> 新版 `sync.sh` 會自己找 Dropbox 根目錄（依序試 CloudStorage 版、舊版 `~/Dropbox`、
> 有無 `Lee Chunying/` 這層），所以就算某台電腦的 Dropbox 佈局不一樣也不會斷。
> 真的都找不到時，可以自己指定：
>
> ```bash
> export DROPBOX_HOME="/你的/實際/Dropbox/個人根目錄"
> ```

---

## 安全保障

每次同步前，會自動把本機現況備份到：
```
~/Library/CloudStorage/Dropbox/Lee Chunying/.claude-sync/.backup/<電腦名稱>-<日期時間>/
```

備份保留 30 天，自動清理。如果同步出意外，可以從這裡還原。

---

## 接續 Dropbox 整理工作

在任一台電腦開新 Claude Code 對話後，說：

> 「請讀 secondbrain/Dropbox 整理進度.md 接續整理工作」

進度筆記在 `~/Library/CloudStorage/Dropbox/Lee Chunying/secondbrain/Dropbox 整理進度.md`，會跟著 Dropbox 同步。
