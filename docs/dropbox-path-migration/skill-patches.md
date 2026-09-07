# 技能檔逐行修正對照

6 個檔案、6 行。用編輯器搜尋「舊」那行、換成「新」那行即可。
兩個來源都要改：**claude.ai → Settings → Skills**，以及 Mac 的 `~/.claude/skills/`。

---

### 1. `obsidian-knowledge-updater/SKILL.md`（第 15 行）

舊：
```
`/Users/lichunying/Library/CloudStorage/Dropbox/secondbrain/`
```
新：
```
`/Users/lichunying/Library/CloudStorage/Dropbox/Lee Chunying/secondbrain/`
```

---

### 2. `personal-secretary/SKILL.md`（第 106 行）

舊：
```
- 路徑：`/Users/lichunying/Library/CloudStorage/Dropbox/secondbrain/個人履歷/`
```
新：
```
- 路徑：`/Users/lichunying/Library/CloudStorage/Dropbox/Lee Chunying/secondbrain/個人履歷/`
```

---

### 3. `invitation-intake/SKILL.md`（第 25 行）★ 最優先

這行是雲端／手機建歸檔資料夾的實際目標路徑，不改的話 `create_folder` 會直接失敗。

舊：
```
`create_folder` 建 `/重要待辦事項/<MMDD> 題目`
```
新：
```
`create_folder` 建 `/Lee Chunying/重要待辦事項/<MMDD> 題目`
```

---

### 4. `invitation-intake/scripts/gmail_attachments.py`（第 11 行）

舊：
```
      --dest "/Users/lichunying/Library/CloudStorage/Dropbox/重要待辦事項/0712 高齡肥胖管理"
```
新：
```
      --dest "/Users/lichunying/Library/CloudStorage/Dropbox/Lee Chunying/重要待辦事項/0712 高齡肥胖管理"
```

---

### 5. `make-presentation/SKILL.md`（第 40 行）

舊：
```
2. **時長與素材**：幾分鐘；素材在哪（Dropbox `演講與寫作/`、Obsidian 知識庫、上傳檔案、先前講過的版本）
```
新：
```
2. **時長與素材**：幾分鐘；素材在哪（Dropbox `/Lee Chunying/演講與寫作/`、Obsidian 知識庫、上傳檔案、先前講過的版本）
```

---

### 6. `fm-residency-accreditation-review/SKILL.md`（第 639 行）

原本是相對路徑，本身不算壞，但補成完整路徑可避免歧義。

舊：
```
  `secondbrain/專業思考庫/家庭醫學科專科訓練計畫審查AI協作技能.md` 為準。
```
新：
```
  `/Lee Chunying/secondbrain/專業思考庫/家庭醫學科專科訓練計畫審查AI協作技能.md` 為準。
```

---

## 檢查有沒有漏

改完在 Mac 上跑這行，應該要沒有任何輸出：

```bash
grep -rn 'Dropbox/secondbrain\|Dropbox/重要待辦事項' ~/.claude/skills/
```

有輸出就是還有漏網之魚（正確的寫法中間會夾著 `Lee Chunying/`）。
