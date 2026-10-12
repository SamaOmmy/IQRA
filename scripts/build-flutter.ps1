# Builds the Flutter app: Windows installer + portable zip, and Android APKs, into iqra_app\dist.
#
#   scripts\build-flutter.ps1            public build: the licensed Madani mushaf fonts and glyph data are left OUT
#   scripts\build-flutter.ps1 -Local     personal build: includes them (never publish this one; see NOTICE.md)
#   -SkipAndroid / -SkipWindows          build only one target
param([switch]$Local, [switch]$SkipAndroid, [switch]$SkipWindows)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'iqra_app'
$env:Path = "C:\src\flutter\bin;" + $env:Path
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = 'C:\src\jdk' }
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = 'C:\src\android-sdk' }

$version = ((Select-String -Path (Join-Path $app 'pubspec.yaml') -Pattern '^version:\s*([\d\.]+)').Matches[0].Groups[1].Value)
$tag = if ($Local) { 'local' } else { 'public' }
$dist = Join-Path $app "dist-$tag"
New-Item -ItemType Directory -Force $dist | Out-Null

$fontDir = Join-Path $app 'assets\fonts\mushaf'
$qcf = Join-Path $app 'assets\qcf\qcf.json'
$stash = Join-Path $env:TEMP 'iqra-licensed-stash'
$moved = $false

try {
  if (-not $Local) {
    New-Item -ItemType Directory -Force $stash | Out-Null
    Get-ChildItem $fontDir -Filter *.ttf -ErrorAction SilentlyContinue | ForEach-Object { Move-Item $_.FullName (Join-Path $stash $_.Name) -Force }
    if (Test-Path $qcf) { Move-Item $qcf (Join-Path $stash 'qcf.json') -Force }
    $moved = $true
  }
  Set-Location $app

  if (-not $SkipWindows) {
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'windows build failed' }
    $rel = Join-Path $app 'build\windows\x64\runner\Release'
    if (-not $Local) {
      $leak = Get-ChildItem (Join-Path $rel 'data\flutter_assets\assets') -Recurse -File | Where-Object { $_.FullName -match 'fonts\\mushaf\\.*\.ttf$' -or $_.Name -eq 'qcf.json' }
      if ($leak) { throw "licensed files found in the public build: $($leak.Name -join ', ')" }
    }
    $zip = Join-Path $dist "IQRA-$version-windows-portable.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path (Join-Path $rel '*') -DestinationPath $zip
    $nsis = Get-ChildItem "$env:LOCALAPPDATA\electron-builder\Cache\nsis-3.0.4.1" -Recurse -Filter makensis.exe | Where-Object { $_.FullName -notmatch '\\Bin\\' } | Select-Object -First 1
    if ($nsis) {
      $out = Join-Path $dist "IQRA-Setup-$version.exe"
      & $nsis.FullName "/DSRC=$rel" "/DVERSION=$version" "/DOUT=$out" (Join-Path $PSScriptRoot 'installer.nsi')
      if ($LASTEXITCODE -ne 0) { throw 'installer build failed' }
    } else { Write-Warning 'makensis not found: only the portable zip was made' }
  }

  if (-not $SkipAndroid) {
    flutter build apk --release --split-per-abi
    if ($LASTEXITCODE -ne 0) { throw 'apk build failed' }
    Get-ChildItem (Join-Path $app 'build\app\outputs\flutter-apk') -Filter *.apk | ForEach-Object {
      Copy-Item $_.FullName (Join-Path $dist ("IQRA-$version-" + ($_.Name -replace '^app-', ''))) -Force
    }
  }
  Write-Host "Done: $dist"
  Get-ChildItem $dist | Select-Object Name, @{n = 'MB'; e = { [math]::Round($_.Length / 1MB, 1) } }
}
finally {
  if ($moved) {
    Get-ChildItem $stash -Filter *.ttf -ErrorAction SilentlyContinue | ForEach-Object { Move-Item $_.FullName (Join-Path $fontDir $_.Name) -Force }
    if (Test-Path (Join-Path $stash 'qcf.json')) { Move-Item (Join-Path $stash 'qcf.json') $qcf -Force }
  }
}
