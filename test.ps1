$ErrorActionPreference = "Silently Continue"

$buildRoot = Join-Path $env:TEMP "windower-build"

$stagingDir = if ($env:BUILD_PATH) { $env:BUILD_PATH } else { Join-Path $buildRoot "staging" }
$luaDir = Join-Path $buildRoot "lua"

if (-not (Test-Path $stagingDir -PathType Container)) {
    "Skipping tests"
    ""
    Exit
}

$luajit = Join-Path $luaDir "bin\luajit.exe"

$passed = $true

Get-ChildItem $stagingDir -Directory |
    ForEach-Object {
        $path = $_.FullName
        Get-ChildItem $path -Directory -Recurse |
        Where-Object { $_.Name -ceq ".test" } |
        ForEach-Object {
            Push-Location $path
            Get-ChildItem $_.FullName -File -Filter "*.lua" |
                ForEach-Object {
                    Push-Location $stagingDir
                    "Running tests $((Resolve-Path $_.FullName -Relative).Replace(".\", ''))..."
                    Pop-Location
    
                    try { $output = & $luajit $_.FullName 2>&1 } catch { }
                    $result = $?
                    $output | ForEach-Object {
                        $message = ([string]$_).Replace("${luajit}:", "").Trim()
                        if ($_ -is [System.Management.Automation.ErrorRecord]) {
                            Write-Host $message -ForegroundColor Red
                        } else {
                            Write-Host $message
                        }
                    }
    
                    if ($result) {
                        Write-Host "Tests Passed`n" -ForegroundColor Green
                    } else {
                        Write-Host "Tests Failed`n" -ForegroundColor Red
                        $script:passed = $false
                    }
                }
            Pop-Location
        }
    }

$error.clear()
if (-not $passed) {
    Exit 1
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
