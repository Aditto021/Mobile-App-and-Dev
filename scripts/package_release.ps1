param([switch]$SkipBuild, [string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $projectRoot 'release' }
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$version = [regex]::Match((Get-Content (Join-Path $projectRoot 'pubspec.yaml') -Raw), '(?m)^version:\s*([^\s+]+)\+(\d+)')
if (-not $version.Success) { throw 'Set versionName+buildNumber in pubspec.yaml first.' }
$versionName = $version.Groups[1].Value
$versionCode = [long]$version.Groups[2].Value
Push-Location $projectRoot
try {
    if (-not $SkipBuild) {
        flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
        flutter analyze
        if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed.' }
        flutter test
        if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
        # Direct-download build: original certificate + in-app updater.
        flutter build apk --release -P sideload=true --dart-define=SIDELOAD=true
        if ($LASTEXITCODE -ne 0) { throw 'Release build failed.' }
    }
    $sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { $env:ANDROID_HOME }
    if (-not $sdk) { throw 'Set ANDROID_SDK_ROOT to the Android SDK directory.' }
    $buildTools = Get-ChildItem (Join-Path $sdk 'build-tools') -Directory |
        Where-Object Name -Match '^\d+\.\d+\.\d+$' |
        Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
    if (-not $buildTools) { throw 'Android build tools are missing.' }
    $source = Join-Path $projectRoot 'build\app\outputs\apk\release\app-release.apk'
    $signature = & (Join-Path $buildTools.FullName 'apksigner.bat') verify --print-certs $source
    if ($LASTEXITCODE -ne 0 -or ($signature -join "`n") -notmatch '615742c8bf47f4e1dd6bee94cd0492605cbc45fbb717c0061a7769e41b758bef') {
        throw 'APK must use the existing FeriWala signing certificate.'
    }
    $badging = (& (Join-Path $buildTools.FullName 'aapt.exe') dump badging $source) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $badging -notmatch "package: name='com.feriwala.app' versionCode='$versionCode' versionName='$([regex]::Escape($versionName))'") {
        throw 'APK package/version does not match pubspec.yaml.'
    }
    & (Join-Path $buildTools.FullName 'zipalign.exe') -c -P 16 4 $source
    if ($LASTEXITCODE -ne 0) { throw 'APK alignment verification failed.' }
    New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
    $name = "feriWala-v$versionName.apk"
    $destination = Join-Path $OutputDirectory $name
    Copy-Item -LiteralPath $source -Destination $destination -Force
    $hash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -LiteralPath "$destination.sha256" -Value "$hash  $name" -Encoding ascii
    $metadata = [ordered]@{
        packageId = 'com.feriwala.app'; versionName = $versionName; versionCode = $versionCode
        apkUrl = "https://github.com/Aditto021/Mobile-App-and-Dev/releases/download/v$versionName/$name"
        sha256 = $hash; sizeBytes = (Get-Item -LiteralPath $destination).Length
        releaseNotes = '210 real products from Bangladeshi shops, online accounts that sync your cart and wishlist, server-checked orders, account deletion and a privacy policy.'
    }
    [System.IO.File]::WriteAllText((Join-Path $OutputDirectory 'feriwala-update.json'), ($metadata | ConvertTo-Json), [System.Text.UTF8Encoding]::new($false))
    # Delete only obsolete distributable files in this exact output directory.
    Get-ChildItem -LiteralPath $OutputDirectory -File | Where-Object {
        $_.Name -match '\.apk(\.sha256)?$' -and $_.FullName -ne $destination -and $_.FullName -ne "$destination.sha256"
    } | ForEach-Object { Remove-Item -LiteralPath $_.FullName }
    Write-Host "Verified APK: $destination"
} finally { Pop-Location }
