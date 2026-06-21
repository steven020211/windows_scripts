# 早安新聞 DailyNews

每天早上 07:00 自動整理新聞，發送到 Discord，完成後關機。

## 檔案說明

| 檔案 | 用途 |
|---|---|
| `daily-news.ps1` | 主程式，抓 RSS → AI 摘要 → 送 Discord |
| `setup-task.ps1` | 一鍵安裝 Windows 排程（執行時會請你輸入 key） |
| `opencode.json.example` | OpenCode 環境變數範本（選用） |

## 安裝步驟（一般使用者）

### 方法一：使用安裝腳本（推薦）

```powershell
.\DailyNews\setup-task.ps1
```

依照提示輸入你的 **Discord Webhook URL** 和 **OpenRouter API Key** 即可。
安裝後每天 07:00 自動執行，成功發送後 60 秒自動關機。

### 方法二：手動設定

```powershell
# 1. 設定環境變數
$env:DISCORD_WEBHOOK_URL = "你的 Discord Webhook URL"
$env:OPENROUTER_API_KEY = "你的 OpenRouter API Key"

# 2. 預覽測試（不會發送）
.\DailyNews\daily-news.ps1 -Test

# 3. 正式執行
.\DailyNews\daily-news.ps1
```

### 方法三：用 OpenCode 執行

將 `DailyNews\opencode.json.example` 複製成 `DailyNews\opencode.json`，填入你的 key，
然後用 OpenCode 開啟該資料夾即可。

---

**取消關機：** 關機前 60 秒內在命令提示字元執行 `shutdown /a`

## 資料來源

- 中央社即時新聞（國際、政治、科技、產經證券）
- AI 模型：DeepSeek V4 Flash（透過 OpenRouter）
