# Dropbox 路徑異動：影響掃描與修正對照

掃描日期：2026-09-07

## 一句話結論

Dropbox 已從個人帳號變成**團隊帳號**（`屏東縣慢性病防治整合計畫`），
個人資料整包被移到 **`/Lee Chunying/`** 這一層底下。
**資料一個都沒少**，但所有寫死舊路徑的地方都會找不到檔案。共 8 處需修，已全部修好或提供修正檔。

---

## 一、Dropbox 現況

連線身分：`Lee Chunying <june.lee@gap.kmu.edu.tw>`
團隊：`屏東縣慢性病防治整合計畫`
`root_namespace_id = 15056227667`（團隊空間） / `home_namespace_id = 141700646`（個人空間）

根目錄現在長這樣：

```
/
├── 114年屏東縣慢性病防治整合計畫/   ← 團隊資料夾（新增）
├── 115年屏東縣慢性病防治整合計畫/   ← 團隊資料夾（新增）
└── Lee Chunying/                    ← 你原本的個人 Dropbox 整包搬到這裡
    ├── secondbrain/                 （Obsidian vault）
    │   ├── 知識庫/
    │   ├── 個人履歷/
    │   ├── 專業思考庫/
    │   └── …
    ├── 重要待辦事項/                （邀約歸檔，`<MMDD> 題目` 命名）
    ├── 演講與寫作/
    └── .claude-sync/                （跨電腦同步腳本）
```

### 實測驗證

| 路徑 | 結果 |
|---|---|
| `/secondbrain`（舊） | ❌ `NOT_FOUND` |
| `/重要待辦事項`（舊） | ❌ `NOT_FOUND` |
| `/Lee Chunying/secondbrain` | ✅ 正常 |
| `/Lee Chunying/重要待辦事項` | ✅ 正常（最新項目 `1018 中山醫家醫科醫學會腦膜炎講師`，2026-09-03） |
| `/Lee Chunying/演講與寫作` | ✅ 正常 |
| `/Lee Chunying/secondbrain/個人履歷` | ✅ 正常（CV-主檔.md 等 7 個清單檔都在） |
| `/Lee Chunying/secondbrain/專業思考庫/家庭醫學科專科訓練計畫審查AI協作技能.md` | ✅ 正常 |

### 換算規則

| 舊寫法 | 新寫法 |
|---|---|
| Dropbox 連接器 `/secondbrain/…` | `/Lee Chunying/secondbrain/…` |
| Dropbox 連接器 `/重要待辦事項/…` | `/Lee Chunying/重要待辦事項/…` |
| Mac `~/Library/CloudStorage/Dropbox/secondbrain/…` | `~/Library/CloudStorage/Dropbox/Lee Chunying/secondbrain/…` |
| Mac `~/Dropbox/.claude-sync/…` | `~/Library/CloudStorage/Dropbox/Lee Chunying/.claude-sync/…` |

> 備用寫法：也可以用命名空間路徑 `ns:141700646//secondbrain/…`，
> 好處是就算日後「Lee Chunying」這個顯示名稱改了也不會失效。
> `演講與寫作/` 是獨立共享資料夾，自己的命名空間是 `ns:702622494//`。

---

## 二、需要修正的 8 處

### A. 技能檔（已在本次 session 修好，但需回寫到來源，見第三節）

| # | 檔案 | 行 | 改動 |
|---|---|---|---|
| 1 | `obsidian-knowledge-updater/SKILL.md` | 15 | vault 路徑補 `Lee Chunying/` |
| 2 | `personal-secretary/SKILL.md` | 106 | 個人履歷路徑補 `Lee Chunying/` |
| 3 | `invitation-intake/SKILL.md` | 25 | 連接器 `create_folder` 目標改 `/Lee Chunying/重要待辦事項/<MMDD> 題目` ← **最會出錯的一個**，雲端建資料夾會直接失敗 |
| 4 | `invitation-intake/scripts/gmail_attachments.py` | 11 | `--dest` 範例補 `Lee Chunying/` |
| 5 | `make-presentation/SKILL.md` | 40 | 素材位置標成 `/Lee Chunying/演講與寫作/` |
| 6 | `fm-residency-accreditation-review/SKILL.md` | 639 | 主檔改成完整路徑，避免相對路徑歧義 |

### B. Dropbox 裡的同步腳本 ✅ 已於 2026-09-07 部署

| # | 檔案 | 問題 | 處理 |
|---|---|---|---|
| 7 | `/Lee Chunying/.claude-sync/sync.sh` | 第 24 行 `SHARED="$HOME/Dropbox/.claude-sync"` 寫死舊路徑 → 整支腳本掛掉 | ✅ 已換成自動偵測版；舊檔留存為 `sync.sh.bak-20260907` |
| 8 | `/Lee Chunying/.claude-sync/README.md` | 安裝說明與進度筆記路徑都還是 `~/Dropbox/…` | ✅ 已更新；舊檔留存為 `README.md.bak-20260907` |

> 本資料夾的 `sync.sh` 與 `claude-sync-README.md` 即為實際部署的版本存檔。

**同步已停擺 5 個月**：雲端 `.claude-sync/data/` 的內容全部停在 2026-04
（最後一筆 `plans/tranquil-knitting-octopus.md` 是 2026-04-12），
與 `sync.sh` 失效的時間吻合。

`sync.sh` 的修法不是換一個新的寫死路徑，而是依序試 4 個候選位置
（CloudStorage 版 / 舊版、有無 `Lee Chunying/` 這層），
取第一個真的裝著 `.claude-sync/` 或 `secondbrain/` 的；
也可用 `export DROPBOX_HOME=…` 覆寫。已驗證三種佈局都挑得對，
日後 Dropbox 再調整掛載方式也不會再斷一次。

---

## 二之二、後續追加發現（2026-09-07）

Obsidian 開啟時掉回「選擇儲存庫」畫面，追下去發現路徑問題比原本盤點的更深一層：

| # | 位置 | 問題 |
|---|---|---|
| 9 | `~/.claude/settings.json` → `mcpServers.obsidian.args` | 寫死 `/Users/lichunying/Dropbox/secondbrain`，**兩層都錯**（缺 CloudStorage、缺 `Lee Chunying/`） |
| 10 | Obsidian 本身的 vault 設定 | 指著舊路徑，開不起來，退回歡迎畫面 |
| 11 | `~/.claude/projects/<路徑衍生名>/memory/` | **專案長期記憶用「路徑」當資料夾名**，路徑一改就整包被孤立 |

第 11 點是這次最容易被忽略的。雲端備份裡並排躺著兩代，正是前兩次搬家留下的：

```
-Users-_USER_-Dropbox-secondbrain                       ← ~/Dropbox 時代
-Users-_USER_-Library-CloudStorage-Dropbox-secondbrain  ← CloudStorage 時代（4/12，最新）
```

改成 `Lee Chunying/` 後會再生出第三代空資料夾，先前累積的記憶就接不上。

`mcpServers.obsidian-ide`（`mcp-remote http://localhost:22360/sse`）沒有路徑，
只要 Obsidian 把 vault 開回來就自動恢復，不用改。

### 修復腳本 `fix-paths.sh`

一次處理第 9、11 點並檢查第 10 點，已同時放在
`/Lee Chunying/.claude-sync/fix-paths.sh`，兩台 Mac 各跑一次：

```bash
bash ~/Library/CloudStorage/Dropbox/Lee\ Chunying/.claude-sync/fix-paths.sh --dry-run  # 先看
bash ~/Library/CloudStorage/Dropbox/Lee\ Chunying/.claude-sync/fix-paths.sh            # 再跑
```

設計原則：settings.json 先備份再改；記憶是**複製**不是搬移，舊資料夾原封不動；
可重複執行；指令失敗會停下來報錯而不是靜靜跳過。

已驗證：自動挑最新那代記憶、時間戳保留、內容逐檔比對一致、重跑不出錯。

---

## 三、不受影響的部分

- **Notion**（待辦 DB、演講 DB、Routine DB）、**Google Calendar**、**Gmail** — 與 Dropbox 無關，完全不受影響。
- **Obsidian MCP 的 `知識庫/`、`_模板/` 等路徑** — 這些是 **vault 相對路徑**，只要 Obsidian 本身開得起 vault 就沒事。
  但請確認一下 Obsidian 的 vault 位置有沒有跟著改（見下節第 3 點）。
- **secondbrain 內的資料** — 逐一抽查過，檔案都在、時間戳正常。

### 順手發現的小問題（非路徑問題）

`/Lee Chunying/secondbrain/個人履歷/` 有兩個中斷同步留下的殘檔，可以直接刪：
- `CV-主檔.md.tmp.10108.0eb46a7c4d54`
- `臨床試驗清單.md.tmp.10108.b335c669e693`

---

## 四、你要做的三件事

本次 session 改到的是雲端同步下來的**暫存副本**，容器收掉就沒了。
要讓修正長久生效，請把改動回寫到三個來源：

1. **claude.ai → Settings → Skills**（手機／瀏覽器版技能的真正來源）
   依第二節 A 表改那 6 個檔。

2. **Mac 上的 `~/.claude/skills/`**（Claude Code 桌機版）
   同樣 6 個檔；兩台 Mac 都要，或改完跑一次 `claude-sync`。

3. ~~把 `sync.sh` 和 `claude-sync-README.md` 寫回 Dropbox~~ ✅ **已完成**

   重跑前先確認本機 Dropbox 實際路徑：

   ```bash
   ls -d ~/Library/CloudStorage/Dropbox/*/ 2>/dev/null
   ```

   應該會看到 `Lee Chunying/`、`114年…/`、`115年…/`。
   若實際不同，`sync.sh` 的自動偵測仍會處理，或用 `DROPBOX_HOME` 指定。

   ⚠️ **第一次重跑請挑資料最新的那台 Mac**，讓它先把新狀態推上去；
   雲端停在 4 月，`rsync -au` 不會用舊蓋新，但雲端有、本機沒有的舊檔會被拉下來。

   另外注意：**這支腳本不同步技能檔**，所以第 1、2 點還是得自己做。

4. **確認 Obsidian vault 路徑**
   Obsidian 若還指著舊的 `…/Dropbox/secondbrain`，開啟時會找不到 vault。
   重新指向 `~/Library/CloudStorage/Dropbox/Lee Chunying/secondbrain` 即可。
