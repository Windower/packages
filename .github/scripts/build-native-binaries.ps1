Get-ChildItem -Directory '.staging' |
  Where-Object { Test-Path -PathType Container (Join-Path $_ '.native') } |
  ForEach-Object {
    $nativeFiles = Join-Path $_.FullName '.native'
    $solution = Join-Path $nativeFiles "$($_.Name).sln"
    &msbuild $solution -p:configuration=release -m
    Remove-Item -Recurse -Force $nativeFiles
    Join-Path $_.FullName 'manifest.tpl.xml' |
      Rename-Item -NewName 'manifest.xml'
  }
