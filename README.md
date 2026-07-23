# 約診日期推算 · Clinic Date Planner

家醫科門診用的「約診日期推算」小工具 —— 在月曆點選處方起始日、選回診間隔（週數或天數），推算「預估藥物用完日」（含星期、民國年）。有最短間隔限制的藥（如 Prolia ≥ 180 天）直接用天數填 180。

**線上使用（可加到手機主畫面）：** https://june23lee-spec.github.io/clinic-date-planner/

## 特色

- 純前端單頁工具，**零資料**：所有運算只在瀏覽器本地跑，不上傳、不儲存。
- **PWA**：可「加入主畫面」變成 App、**離線可用**、免登入。
- 全繁體中文，手機／電腦皆可。

## 檔案

| 檔案 | 用途 |
|---|---|
| `index.html` | 工具本體（HTML＋CSS＋vanilla JS，無外部相依） |
| `manifest.webmanifest` | PWA 身分證（名稱、icon、全螢幕） |
| `sw.js` | service worker（離線快取；改版時把 `CACHE` 版本號 +1） |
| `icon-*.png` / `app-icon.svg` | App icon（`app-icon.svg` 為原始檔，可重新產 PNG） |

## 改版流程

1. 改 `index.html`。
2. 若動到快取內容，把 `sw.js` 的 `CACHE` 版本號往上加（`cdp-v3` → `cdp-v4`）。
3. `git commit` + `git push` → GitHub Pages 自動更新。使用者下次開啟即是最新版。

## 部署

GitHub Pages（main 分支根目錄）。無需建置步驟。
