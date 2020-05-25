$exitCode = 0

Get-ChildItem -Recurse -Filter '*.lua' |
  ForEach-Object {
    &.tools/luajit -b $_ - >$null
    if ($LASTEXITCODE -ne 0) {
      $script:exitCode = 1
    }
  }

exit $exitCode
