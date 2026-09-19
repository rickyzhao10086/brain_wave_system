param(
    [string]$Version = '',
    [string]$BuildNumber = '',
    [string]$OutputDirectory = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AppRoot = Split-Path -Parent $PSScriptRoot
$PubspecPath = Join-Path $AppRoot 'pubspec.yaml'
$Pubspec = Get-Content -LiteralPath $PubspecPath -Raw
$VersionMatch = [regex]::Match(
    $Pubspec,
    '(?m)^version:\s+([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$'
)
if (-not $VersionMatch.Success) {
    throw "Could not read a version from $PubspecPath."
}
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = $VersionMatch.Groups[1].Value
}
if ([string]::IsNullOrWhiteSpace($BuildNumber)) {
    $BuildNumber = $VersionMatch.Groups[2].Value
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter was not found on PATH. Install Flutter and enable Windows desktop support first.'
}

Push-Location $AppRoot
try {
    & flutter build windows --release "--build-name=$Version" "--build-number=$BuildNumber"
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter Windows release build failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

$Bundle = Join-Path $AppRoot 'build\windows\x64\runner\Release'
$Executable = Join-Path $Bundle 'CerebroSync.exe'
if (-not (Test-Path -LiteralPath $Executable)) {
    throw "The release bundle is missing $Executable."
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $AppRoot 'dist\windows'
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$ArchiveName = "CerebroSync-windows-x64-v$Version.zip"
$ArchivePath = Join-Path $OutputDirectory $ArchiveName
$ChecksumPath = "$ArchivePath.sha256"
$StagingPath = Join-Path $OutputDirectory "CerebroSync-windows-x64-v$Version"

if (Test-Path -LiteralPath $StagingPath) {
    Remove-Item -LiteralPath $StagingPath -Recurse -Force
}
if (Test-Path -LiteralPath $ArchivePath) {
    Remove-Item -LiteralPath $ArchivePath -Force
}
if (Test-Path -LiteralPath $ChecksumPath) {
    Remove-Item -LiteralPath $ChecksumPath -Force
}

New-Item -ItemType Directory -Path $StagingPath -Force | Out-Null
Copy-Item -Path (Join-Path $Bundle '*') -Destination $StagingPath -Recurse -Force
Compress-Archive -Path (Join-Path $StagingPath '*') -DestinationPath $ArchivePath -CompressionLevel Optimal

$Hash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath $ChecksumPath -Value "$Hash  $ArchiveName" -Encoding ascii
Remove-Item -LiteralPath $StagingPath -Recurse -Force

Write-Host "Windows release: $ArchivePath"
Write-Host "SHA-256: $ChecksumPath"
