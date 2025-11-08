# version 0.1.0

$appName = "game"
$require = @(
    "main.lua"
)

$buildFolder = "build"
if (!(Test-Path -Path $buildFolder)) {
    New-Item -ItemType Directory -Path $buildFolder | Out-Null
}

$versionsFolder = Join-Path -Path $buildFolder -ChildPath "version"
if (!(Test-Path -Path $versionsFolder)) {
    New-Item -ItemType Directory -Path $versionsFolder | Out-Null
}

$releaseFolder = Join-Path -Path $buildFolder -ChildPath "release"

$loveZip = Join-Path -Path $releaseFolder -ChildPath "${appName}.love"

$love2dVersion = "11.5"
$buildWindows = $true
$buildLinux = $true

# Define OS-specific build paths
$basePath = Join-Path -Path $versionsFolder -ChildPath $love2dVersion
$binaries = @{
    "windows" = Join-Path -Path $basePath -ChildPath "windows"
    "linux"   = Join-Path -Path $basePath -ChildPath "linux.AppImage"
}

# Prepare game.love
if (Test-Path $loveZip) {
    Remove-Item $loveZip
}

Add-Type -AssemblyName "System.IO.Compression.FileSystem"
$zip = [System.IO.Compression.ZipFile]::Open($loveZip, 'Create')

foreach ($file in $require)
{
    if (Test-Path $file)
    {
        # Forward slashes for consistency
        #
        # Remove ./ prefix when adding it to the
        # archive because LOVE2D will search in
        # working directory if string in code has
        # ./ prefix e.g ./src/bot.lua
        $zipEntryName = ($file -replace '\\', '/') -replace '^\./', ''

        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file, $zipEntryName) | Out-Null
    }
}
$zip.Dispose()

function appendGameToFile($filePath, $releaseFolder, $name) {
    $outPath = Join-Path -Path $releaseFolder -ChildPath "$name.exe"
    Write-Host "Processing $outPath"
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    $gameBytes = [System.IO.File]::ReadAllBytes($loveZip)
    [System.IO.File]::WriteAllBytes($outPath, $fileBytes + $gameBytes)
    Write-Host "$appName.love --> $outPath"
}

if ($buildWindows) {
    Write-Host "Building for Windows..."

    # check windows files
    if (!(Test-Path -Path $binaries["windows"])) {
        New-Item -ItemType Directory -Path $binaries["windows"] | Out-Null
    }

    $necessaryFiles = @(
        "game.ico",
        "license.txt", # mhm yes you need the license
        "love.dll",
        "love.exe",
        "love.ico",
        "lovec.exe",
        "lua51.dll",
        "mpg123.dll",
        "msvcp120.dll",
        "msvcr120.dll",
        "OpenAL32.dll",
        "SDL2.dll"
    )

    foreach ($file in $necessaryFiles) {
        $filePath = Join-Path -Path $binaries["windows"] -ChildPath $file
        if (!(Test-Path -Path $filePath)) {
            Write-Warning "Missing required Windows file: $file"
            Write-Warning "Exiting early..."
            return
        }
    }

    # prepare windows build folder
    $folder = Join-Path -Path $releaseFolder -ChildPath "windows"
    if (Test-Path -Path $folder) {
        Remove-Item -Path $folder -Recurse -Force
        Write-Host "Cleared previous Windows build."
    }

    New-Item -ItemType Directory -Path $folder | Out-Null
    Write-Host "Created new folder."

    # copy dlls
    $windowsPath = $binaries["windows"]
    if (Test-Path $windowsPath) {
        foreach ($file in (Get-ChildItem -Path $windowsPath -Exclude "*.exe" -File -Recurse)) {
            Copy-Item $file.FullName -Destination $folder -Force
            Write-Host "Copied $($file.Name) to $folder"
        }
    } else {
        Write-Warning "Windows binaries path not found: $windowsPath"
    }

    # process love.exe then lovec.exe
    if (Test-Path (Join-Path -Path $binaries["windows"] -ChildPath "love.exe")) {
        appendGameToFile (Join-Path -Path $binaries["windows"] -ChildPath "love.exe") $folder $appName
    } else {
        Write-Warning "love.exe not found in $($binaries['windows']). Skipping."
    }

    if (Test-Path (Join-Path -Path $binaries["windows"] -ChildPath "lovec.exe")) {
        appendGameToFile (Join-Path -Path $binaries["windows"] -ChildPath "lovec.exe") $folder "$appName-debug"
    } else {
        Write-Warning "lovec.exe not found in $($binaries['windows']). Skipping."
    }

    Write-Host "Finished building $appName for Windows."

    # Create ZIP
    Write-Host "Creating Release ZIP for Windows..."
    $zipName = Join-Path -Path $releaseFolder -ChildPath "$appName-windows-x86-64.zip"
    if (Test-Path $zipName) {
        Remove-Item $zipName -Force
    }
    $releaseZip = [System.IO.Compression.ZipFile]::Open($zipName, "Create")

    Get-ChildItem -Path $folder -Recurse -File | ForEach-Object {
        $zipEntryName = $_.Name # Use only the file name for the zip entry
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($releaseZip, $_.FullName, $zipEntryName) | Out-Null
        $rel = [System.IO.Path]::GetRelativePath($buildFolder, $_.FullName) -replace '\\','/'
        Write-Host "Added build/$rel to the Release ZIP."
    }
    $releaseZip.Dispose()
    Write-Host "Created Release ZIP: $zipName"
}

if ($buildLinux) {

}