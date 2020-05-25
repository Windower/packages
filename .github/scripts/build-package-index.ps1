$xmlSettings = $null
try {
  $xmlSettings = New-Object System.Xml.XmlWriterSettings
  $xmlSettings.Indent = $true
  $xmlSettings.IndentChars = '  '
  $xmlSettings.NewLineChars = "`n"
  $writer = [System.XMl.XmlWriter]::Create(
    (Join-Path '.staging' 'packages.xml'),
    $xmlSettings)

  $writer.WriteStartDocument()
  $writer.WriteStartElement('packages')

  Get-ChildItem -Directory '.staging' |
    ForEach-Object {
      $manifestPath = Join-Path $_.FullName 'manifest.xml'
      $manifest = New-Object -TypeName 'Xml'
      $manifest.Load($manifestPath)

      $writer.WriteStartElement('package')
      try {
        $writer.WriteElementString('name', $manifest.package.name)
        $writer.WriteElementString('version', $manifest.package.version)
        $writer.WriteElementString('type', $manifest.package.type)

        $dependencies = $manifest.package.dependencies.dependency |
          Where-Object {
            if ($_.optional -is [string]) {
              $c = $_.optional[0]
              $c -ne "t" -and $c -ne "y" -and $c -ne "1"
            } else { $true }
          }
        if ($dependencies.Count -gt 0) {
          $writer.WriteStartElement("dependencies")
          try {
            $dependencies | ForEach-Object {
              $writer.WriteElementString("dependency", $_)
            }
          } finally {
            $writer.WriteEndElement()
          }
        }
        
        $writer.WriteStartElement("files")
        try {
          Push-Location '.staging'
          try {
            Get-ChildItem $_.FullName -Recurse -File | ForEach-Object {
              $relativePath = Resolve-Path $_.FullName -Relative
              $relativePath = $relativePath.Replace('.\', '')
              $relativePath = $relativePath.Replace('\', '/')
              $writer.WriteStartElement('file')
              try {
                $writer.WriteAttributeString('size', $_.Length)
                $writer.WriteString($relativePath)
              } finally {
                $writer.WriteEndElement()
              }
            }
          } finally {
            Pop-Location
          }
        } finally {
          $writer.WriteEndElement()
        }
      } finally {
        $writer.WriteEndElement()
      }
    }

  $writer.WriteEndElement()
  $writer.WriteEndDocument()
} finally {
  if ($writer -ne $null) {
    $writer.Close()
    $writer = $null
  }
}
