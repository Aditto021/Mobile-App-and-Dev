# Google Play build: a signed Android App Bundle (.aab) ready to upload.
#   ./scripts/build_play.ps1 -ApiUrl https://your-api.example.com
# Without -ApiUrl the app runs without a server (accounts stay on the phone).
param([string]$ApiUrl, [switch]$SkipChecks)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Push-Location $projectRoot
try {
    if (-not (Test-Path 'android/key.properties')) {
        throw 'android/key.properties is missing. Create the upload key first (README: Google Play).'
    }
    if ($ApiUrl -and $ApiUrl -notmatch '^https://') {
        throw 'Store builds only talk to the server over https://.'
    }
    if (-not $ApiUrl) {
        Write-Warning 'No -ApiUrl given: this build runs without a server.'
    }
    $version = [regex]::Match((Get-Content 'pubspec.yaml' -Raw), '(?m)^version:\s*([^\s+]+)\+(\d+)')
    if (-not $version.Success) { throw 'Set versionName+buildNumber in pubspec.yaml first.' }
    $versionName = $version.Groups[1].Value
    $versionCode = $version.Groups[2].Value

    if (-not $SkipChecks) {
        flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
        flutter analyze
        if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed.' }
        flutter test
        if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
    }
    $buildArgs = @('build', 'appbundle', '--release')
    if ($ApiUrl) { $buildArgs += "--dart-define=API_URL=$ApiUrl" }
    flutter @buildArgs
    if ($LASTEXITCODE -ne 0) { throw 'App bundle build failed.' }

    $aab = Join-Path $projectRoot 'build\app\outputs\bundle\release\app-release.aab'
    $cert = (& keytool -printcert -jarfile $aab) -join "`n"
    if ($LASTEXITCODE -ne 0 -or -not $cert) { throw 'The bundle is not signed.' }
    if ($cert -match 'CN=Android Debug') { throw 'The bundle is debug-signed; Google Play will refuse it.' }

    # Play must never see the self-update permission.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($aab)
    try {
        $entry = $zip.GetEntry('base/manifest/AndroidManifest.xml')
        $reader = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::ASCII)
        $manifest = $reader.ReadToEnd(); $reader.Close()
    } finally { $zip.Dispose() }
    if ($manifest -match 'REQUEST_INSTALL_PACKAGES|usesCleartextTraffic') {
        throw 'The bundle still asks to install packages or allows plain http.'
    }

    $out = Join-Path $projectRoot 'release\play'
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    $name = "feriWala-v$versionName-$versionCode.aab"
    Copy-Item -LiteralPath $aab -Destination (Join-Path $out $name) -Force
    Write-Host "Ready for Google Play: release\play\$name"
    Write-Host ($cert -split "`n" | Select-String 'Owner:|SHA256:' | Select-Object -First 2)
} finally { Pop-Location }
