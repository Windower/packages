$ErrorActionPreference = "Stop"

$luaUrl = "http://windower.github.io/windower/lua.zip"

$buildRoot = Join-Path $env:TEMP "windower-build"

$stagingDir = if ($env:BUILD_PATH) { $env:BUILD_PATH } else { Join-Path $buildRoot "staging" }
$luaDir = Join-Path $buildRoot "lua"
$symbolsDir = Join-Path $buildRoot "symbols"
$deployedDir = Join-Path $buildRoot "deployed"

Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $luaDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $symbolsDir -Recurse -Force -ErrorAction SilentlyContinue

if ($env:CI) {
    Remove-Item $deployedDir -Recurse -Force -ErrorAction SilentlyContinue
    & git clone -q --depth=1 --branch="gh-pages" https://github.com/${env:APPVEYOR_REPO_NAME}.git $deployedDir
    $buildAll = -not $?

    if($env:APPVEYOR_PULL_REQUEST_NUMBER) {
        $changedFiles = & git log --name-only --pretty=oneline --full-index master..
    } else {
        $changedFiles = & git log --name-only --pretty=oneline --full-index HEAD^..HEAD
    }
    $buildAll = $buildAll -or -not $?

    if (-not $buildAll) {
        $changedPackages = 
            @($changedFiles |
                Select-Object -Skip 1 |
                ForEach-Object { ($_ -split "/")[0] } |
                Select-Object -Unique |
                Where-Object { Test-Path $_ -PathType Container }) +
            @(Get-ChildItem -Directory -Name |
                Where-Object { -not (Test-Path (Join-Path $deployedDir $_) -PathType Container) }) |

                Select-Object -Unique

        if ($null -eq $changedPackages -or $changedPackages.count -eq 0) {
            "Nothing has changed"
            "Skipping build"
            ""
            Exit
        }

        New-Item $stagingDir -ItemType Directory | Out-Null
        Get-ChildItem $deployedDir -Directory |
            Where-Object { -not $changedPackages.Contains($_.Name) } |
            Copy-Item -Destination $stagingDir -Recurse -Force
    }
} else {
    New-Item $stagingDir -ItemType Directory | Out-Null
    $buildAll = $true
}

if ($buildAll) {
    $changedPackages = Get-ChildItem -Directory -Name
}

New-Item $luaDir -ItemType Directory | Out-Null
(New-Object System.Net.WebClient).DownloadFile($luaUrl, "${luaDir}.zip")
Expand-Archive "${luaDir}.zip" -DestinationPath $luaDir

$docsPath = Join-Path $stagingDir ".docs"
if (Test-Path $docsPath) {
    Copy-Item -Path $docsPath -Destination $stagingDir -Recurse -Force
}

Get-ChildItem -Directory |
    Where-Object { $changedPackages.Contains($_.Name) } |
    ForEach-Object {
        Get-ChildItem $_ -File |
            Where-Object { $_.Name -ceq "manifest.tpl.xml" } |
            Rename-Item -NewName "manifest.xml"
        Copy-Item $_ -Destination $stagingDir -Recurse -Force
    }

New-Item $symbolsDir -ItemType Directory | Out-Null
Get-ChildItem $stagingDir -Directory -Recurse |
    Where-Object { $_.Name -ceq ".native" } |
    Get-ChildItem -File -Filter "*.sln" |
        ForEach-Object {
            & msbuild $_.FullName /v:m /m /p:Configuration="Release" /p:VcpkgConfiguration="Release" `
                /p:LuaPath="$luaDir\" /p:SymbolPath="$symbolsDir\"
            ""
        }
