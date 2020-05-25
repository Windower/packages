$schemaSet = New-Object -TypeName 'System.Xml.Schema.XmlSchemaSet'
$schemaSet.CompilationSettings.EnableUpaCheck = $false
$stream = $null
try {
  $stream = (Get-Item './manifest.xsd').OpenRead()
  [void]$schemaSet.Add([Xml.Schema.XmlSchema]::Read($stream, $null))
} finally {
  if ($null -ne $stream) {
    $stream.Dispose()
  }
  $stream = $null
}

$exitCode = 0

function Test-ManifestValid {
  param($path, $directory)

  $name = $path.Name
  $manifestPath = if (Join-Path $path.FullName '.native' |
                      Test-Path -PathType Container) {
    Join-Path $path.FullName 'manifest.tpl.xml'
  } else  {
    Join-Path $path.FullName 'manifest.xml'
  }

  if (-not (Test-Path -PathType Leaf $manifestPath)) {
    $filename = Split-Path $manifestPath -Leaf
    Write-Host -ForegroundColor Red `
      "`n`"$filename`" file is missing in package `"$name`"."
    $script:exitCode = 1
  } else {
    try{
      $manifest = New-Object -TypeName 'Xml'
      $manifest.Load($manifestPath)
      $manifest.Schemas = $schemaSet
      $manifest.Validate($null)
      if ($manifest.package.name -ne $name) {
        Write-Host -ForegroundColor Red `
          ("`n`Manifest name `"$($manifest.package.name)`"" +
          " does not match directory name `"$name`".")
        $script:exitCode = 1
      } else {
        $ok = switch ($directory) {
          'addons' {
            $manifest.package.type -eq 'addon'
          }
          'libraries' {
            $manifest.package.type -eq 'library' -or `
            $manifest.package.type -eq 'service'
          }
        }
        if ($ok -eq $false) {
          Write-Host -ForegroundColor Red `
            ("`n`Package `"$($name)`" has type" +
            " `"$($manifest.package.type)`"" +
            " but is in the `"$directory`" directory.")
          $script:exitCode = 1
        } else {
          try {
            [void]([Version]$manifest.package.version)
          } catch {
            Write-Host -ForegroundColor Red `
              ("`n`Package `"$($name)`" has invalid version string" +
              " `"$($manifest.package.version)`".")
            $script:exitCode = 1
          }
        }
      }
    } catch [System.Management.Automation.MethodInvocationException] {
      Write-Host -ForegroundColor Red  "Error loading file `"$manifestPath`""
      Write-Host -ForegroundColor Red $_.Exception.InnerException.Message
      $script:exitCode = 1
    } catch {
      Write-Host -ForegroundColor Red  "Error loading file `"$manifestPath`""
      Write-Host -ForegroundColor Red $_.Exception.Message
      $script:exitCode = 1
    }
  }
}

$addons = Get-ChildItem 'addons' -Directory
$libraries = Get-ChildItem 'libraries' -Directory

$addonNames = $addons | ForEach-Object { $_.Name }
$libraryNames = $libraries | ForEach-Object { $_.Name }
$duplicates = $addonNames | Where-Object { $libraryNames -contains $_ }
if ($duplicates.Count -gt 0) {
  Write-Host -ForegroundColor Red "Duplicate package names found:"
  Write-Host -ForegroundColor Red "  * $($duplicates -join '`n  * ')"
  $script:exitCode = 1
}

$addons | ForEach-Object { Test-ManifestValid $_ 'addons' }
$libraries | ForEach-Object { Test-ManifestValid $_ 'libraries' }

exit $exitCode
