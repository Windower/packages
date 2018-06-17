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
