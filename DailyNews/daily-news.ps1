param([Switch]$Test)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$webhookUrl = $env:DISCORD_WEBHOOK_URL
$apiKey = $env:OPENROUTER_API_KEY
$dateStr = Get-Date -Format "yyyy/MM/dd"

Add-Type -AssemblyName System.Web.Extensions

$feeds = @{
    CNAWorld   = @{ url = "https://feeds.feedburner.com/rsscna/intworld";   max = 20 }
    CNATaiwan  = @{ url = "https://feeds.feedburner.com/rsscna/politics";    max = 20 }
    CNATech    = @{ url = "https://feeds.feedburner.com/rsscna/technology";  max = 20 }
    CNAFinance = @{ url = "https://feeds.feedburner.com/rsscna/finance";     max = 20 }
}

$now = Get-Date
$today0700 = Get-Date -Year $now.Year -Month $now.Month -Day $now.Day -Hour 7 -Minute 0 -Second 0
$yesterday0700 = $today0700.AddDays(-1)

function Get-NodeText($node) {
    if ($node -is [System.Xml.XmlElement]) { return $node.InnerText }
    return "$node"
}

function Get-RssItems($url, $count = 20) {
    try { $xml = [System.Xml.XmlDocument]::new(); $xml.Load($url); return $xml.rss.channel.item | Select-Object -First $count }
    catch { return @() }
}

function Clean-Text($text) {
    return ($text -replace '<[^>]+>', '' -replace '\s+', ' ').Trim()
}

function IsInTimeWindow($pubDateStr) {
    try {
        $dt = [DateTime]::ParseExact($pubDateStr, "ddd, dd MMM yyyy HH:mm:ss zzz", [System.Globalization.CultureInfo]::InvariantCulture)
        return ($dt -ge $yesterday0700 -and $dt -le $today0700)
    } catch { return $true }
}

function Build-NewsList($items) {
    $result = ""
    $i = 1
    foreach ($item in $items) {
        $title = Clean-Text (Get-NodeText $item.title)
        $desc = Clean-Text (Get-NodeText $item.description)
        $title = $title -replace '^（中央社[^）]*）', ''
        $desc = $desc -replace '^（中央社[^）]*）', ''
        $result += "[$i] $title   $desc`n"
        $i++
    }
    return $result
}

function Escape-Json($s) {
    $r = $s -replace '\\', '\\'
    $r = $r -replace '"', '\"'
    $r = $r -replace "`n", '\n'
    $r = $r -replace "`r", '\r'
    return $r
}

function Send-Discord($text) {
    $escaped = Escape-Json $text
    $json = '{"content":"' + $escaped + '"}'
    $utf8 = [System.Text.Encoding]::UTF8.GetBytes($json)
    Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType "application/json; charset=utf-8" -Body $utf8
}

Write-Host "Fetching RSS feeds (time window: $yesterday0700 ~ $today0700)..."
$worldItems = Get-RssItems $feeds["CNAWorld"].url $feeds["CNAWorld"].max | Where-Object { IsInTimeWindow "$($_.pubDate)" }
$taiwanItems = Get-RssItems $feeds["CNATaiwan"].url $feeds["CNATaiwan"].max | Where-Object { IsInTimeWindow "$($_.pubDate)" }
$aiItems = Get-RssItems $feeds["CNATech"].url $feeds["CNATech"].max | Where-Object { IsInTimeWindow "$($_.pubDate)" }
$financeItems = Get-RssItems $feeds["CNAFinance"].url $feeds["CNAFinance"].max | Where-Object { IsInTimeWindow "$($_.pubDate)" }

Write-Host "  World:$($worldItems.Count) Taiwan:$($taiwanItems.Count) AI:$($aiItems.Count) Finance:$($financeItems.Count)"

$prompt = @"
你是新聞總編輯。以下是過去24小時的大量新聞，請從中挑選最重要、最有影響力的，排除彩券開獎等無意義新聞。

輸出格式（台灣繁體中文）：

🔥 **國際頭條**
▸ 標題 / 一句白話摘要 / 一句為什麼重要
（共3則）

🏠 **台灣頭條**
▸ 標題 / 一句白話摘要 / 一句為什麼重要
（共3則）

🤖 **AI 重點**
▸ 標題 / 一句白話摘要 / 一句為什麼重要
（共3則）

💰 **台股財經**
▸ 標題 / 一句白話摘要 / 一句為什麼重要
（共4則）

📊 **今日觀察**
3~5句總結

規則：只輸出上述格式，用 ▸ 開頭，不要編號，不要多餘說明。

=== 國際新聞 ===
$(Build-NewsList $worldItems)
=== 台灣新聞 ===
$(Build-NewsList $taiwanItems)
=== AI/科技 ===
$(Build-NewsList $aiItems)
=== 財經新聞 ===
$(Build-NewsList $financeItems)
"@

Write-Host "Sending to AI..."
$payload = (@{ model = "deepseek/deepseek-v4-flash"; messages = @(@{ role = "user"; content = $prompt }) } | ConvertTo-Json -Depth 5)
$payload | Out-File -FilePath "$scriptPath\_payload.json" -Encoding UTF8 -Force

$env:OPENROUTER_KEY = $apiKey
cmd.exe /c "curl.exe -s -X POST `"https://openrouter.ai/api/v1/chat/completions`" -H `"Content-Type: application/json`" -H `"Authorization: Bearer %OPENROUTER_KEY%`" -d `"@$scriptPath\_payload.json`" -o `"$scriptPath\_response.json`" 2>&1" | Out-Null

$respText = [System.IO.File]::ReadAllText("$scriptPath\_response.json", [System.Text.Encoding]::UTF8)

# Use proper JSON parser to correctly decode escape sequences (like \n → real newline)
$jss = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$jss.MaxJsonLength = 1000000
$obj = $jss.DeserializeObject($respText)
$aiContent = [string]$obj['choices'][0]['message']['content']

$timeLabel = $yesterday0700.ToString("MM/dd HH:mm") + "~" + $today0700.ToString("HH:mm")
$header = ":newspaper: **早安新聞 | $dateStr** ($timeLabel, AI 精選)"
$fullText = $header + "`n" + $aiContent

if ($fullText.Length -gt 1900) {
    $fullText = $fullText.Substring(0, 1900) + "`n`n...(內容過長已截斷)"
}

if ($Test) {
    Write-Host "========== PREVIEW =========="
    [System.IO.File]::WriteAllText("$scriptPath\_preview.txt", $fullText, [System.Text.Encoding]::UTF8)
    Write-Host "Preview saved to _preview.txt ($($fullText.Length) chars)"
    return
}

Send-Discord $fullText
Write-Host "Sent successfully!"
