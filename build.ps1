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

New-Item $stagingDir -ItemType Directory | Out-Null
if ($env:CI) {
    Remove-Item $deployedDir -Recurse -Force -ErrorAction SilentlyContinue
    try {
        & git clone -q --depth=1 --branch="gh-pages" https://github.com/${env:APPVEYOR_REPO_NAME}.git $deployedDir 2>&1 | Out-Null
    } catch { }
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

        Get-ChildItem $deployedDir -Directory |
            Where-Object { -not $changedPackages.Contains($_.Name) } |
            Copy-Item -Destination $stagingDir -Recurse -Force
    }
} else {
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
    Get-ChildItem $docsPath | Copy-Item -Destination $stagingDir -Recurse -Force
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

# Copyright © 2018, Windower Dev Team
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the Windower Dev Team nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE WINDOWER DEV TEAM BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
