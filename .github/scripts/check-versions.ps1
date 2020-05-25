$folders = @(
  'addons',
  'libraries'
)

$exitCode = 0

$pattern = "^((?:$($folders -join '|'))[\\/][^\\/]+)"
&git diff --name-only HEAD^ |
  Where-Object { $_ -match $pattern } |
  ForEach-Object {
    $path = $matches[1]
    $manifestPath = if (Test-Path -PathType Container `
                        (Join-Path $path '.native')) {
      Join-Path $path 'manifest.tpl.xml'
    } else {
      Join-Path $path 'manifest.xml'
    }
    $manifestPath = $manifestPath -replace '[\\/]', '/'
    try {
      [Xml]$manifest = &git show "HEAD^:$manifestPath" 2>$null
      [Version]$currentVersion = $manifest.package.version
      $manifest = New-Object -TypeName 'Xml'
      $manifest.Load($manifestPath)
      [Version]$newVersion = $manifest.package.version
      if ($newVersion -le $currentVersion) {
        $name = ($path -split '[\\/]')[1]
        Write-Host -ForegroundColor Red `
          ("Package `"$($name)`" version string" +
          " `"$newVersion`" is not greater than" +
          " `"$currentVersion`".")
        $script:exitCode = 1
      }
    } catch {}
  }

exit $exitCode
