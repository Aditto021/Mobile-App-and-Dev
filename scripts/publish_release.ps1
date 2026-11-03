param([switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $env:GITHUB_TOKEN) { throw 'An authenticated GITHUB_TOKEN with Contents: write access is required.' }
& (Join-Path $projectRoot 'scripts\package_release.ps1') -SkipBuild:$SkipBuild
$folder = Join-Path $projectRoot 'release'
$feedPath = Join-Path $folder 'feriwala-update.json'
$feed = Get-Content -LiteralPath $feedPath -Raw | ConvertFrom-Json
$apk = Join-Path $folder "feriWala-v$($feed.versionName).apk"
$headers = @{ Authorization = "Bearer $env:GITHUB_TOKEN"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'FeriWala-Release' }
$api = 'https://api.github.com/repos/Aditto021/Mobile-App-and-Dev'
$repository = Invoke-RestMethod -Uri $api -Headers $headers
if ($repository.private) { throw 'A public release feed is required for phone updates. Repository visibility was not changed.' }
$previous = $null
try { $previous = Invoke-RestMethod -Uri "$api/releases/latest" -Headers $headers }
catch { if ($_.Exception.Response.StatusCode.value__ -ne 404) { throw } }
if ($previous) {
    $previousFeed = $previous.assets | Where-Object name -eq 'feriwala-update.json' | Select-Object -First 1
    if ($previousFeed) {
        $old = Invoke-RestMethod -Uri $previousFeed.browser_download_url
        if ([long]$old.versionCode -ge [long]$feed.versionCode) { throw 'Increase the version code before publishing a new update.' }
    }
}
$body = @{ tag_name = "v$($feed.versionName)"; name = "FeriWala $($feed.versionName)"; body = $feed.releaseNotes; draft = $true; prerelease = $false } | ConvertTo-Json
$release = Invoke-RestMethod -Uri "$api/releases" -Headers $headers -Method Post -ContentType 'application/json' -Body $body
$upload = ($release.upload_url -split '\{')[0]
Invoke-RestMethod -Uri "${upload}?name=$([System.IO.Path]::GetFileName($apk))" -Headers $headers -Method Post -ContentType 'application/vnd.android.package-archive' -InFile $apk | Out-Null
Invoke-RestMethod -Uri "${upload}?name=feriwala-update.json" -Headers $headers -Method Post -ContentType 'application/json' -InFile $feedPath | Out-Null
$published = Invoke-RestMethod -Uri "$api/releases/$($release.id)" -Headers $headers -Method Patch -ContentType 'application/json' -Body '{"draft":false,"make_latest":"true"}'
Write-Host "Published: $($published.html_url)"
