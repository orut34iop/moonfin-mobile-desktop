$ErrorActionPreference = "Stop"

$flutterVersion = "3.41.2"
$url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_${flutterVersion}-stable.zip"
$destBase = "$env:LOCALAPPDATA\flutter_sdk"
$zipPath = "$env:TEMP\flutter_sdk.zip"

if (-not (Test-Path $destBase)) {
    New-Item -ItemType Directory -Path $destBase -Force | Out-Null
}

Write-Host "Downloading Flutter SDK $flutterVersion from Google..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing

Write-Host "Extracting to $destBase..."
Expand-Archive -Path $zipPath -DestinationPath $destBase -Force
Remove-Item $zipPath -Force

$flutterExe = "$destBase\flutter\bin\flutter.bat"
if (Test-Path $flutterExe) {
    Write-Host "Flutter installed to: $destBase"

    # Add to user PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $flutterBin = "$destBase\flutter\bin"
    if ($userPath -notlike "*$flutterBin*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterBin", "User")
        Write-Host "Added $flutterBin to user PATH"
    }

    # Run flutter doctor
    & $flutterExe doctor
}
else {
    Write-Error "Installation failed: $flutterExe not found"
    exit 1
}
