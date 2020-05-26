$ignore = @(
  'libraries/ltn12',
  'libraries/mime',
  'libraries/reflect',
  'libraries/socket'
)

$licensePattern =
  'Copyright © .*? ' +
  'All rights reserved\. ' +

  'Redistribution and use in source and binary forms, with or without ' +
  'modification, are permitted provided that the following conditions are ' +
  'met: ' +

    '\* Redistributions of source code must retain the above copyright' +
      ' notice, this list of conditions and the following disclaimer\. ' +
    '\* Redistributions in binary form must reproduce the above copyright' +
      ' notice, this list of conditions and the following disclaimer in the' +
      ' documentation and/or other materials provided with the' +
      ' distribution\. ' +
    '\* Neither the name of .*? nor the names of its contributors may be' +
      ' used to endorse or promote products derived from this software' +
      ' without specific prior written permission\. ' +
      
  'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ' +
  '"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT ' +
  'LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A ' +
  'PARTICULAR PURPOSE ARE DISCLAIMED\. IN NO EVENT SHALL .*? BE LIABLE FOR ' +
  'ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL ' +
  'DAMAGES \(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS ' +
  'OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION\) ' +
  'HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, ' +
  'STRICT LIABILITY, OR TORT \(INCLUDING NEGLIGENCE OR OTHERWISE\) ARISING ' +
  'IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE ' +
  'POSSIBILITY OF SUCH DAMAGE\.'

$exitCode = 0

Get-ChildItem -Recurse '*.lua' |
  ForEach-Object {
    $path = Resolve-Path -Relative $_.FullName
    $path = $path -replace '[\\/]', '/'
    $path = $path -replace '^./', ''

    $path -match '^(?:addons|libraries)/[^/]+' | Out-Null
    $name = $matches[0]

    if ($ignore -notcontains $name) {
      $comments = (Get-Content $_) -join "`0" |
        Select-String "--(?:\[\[(.*?)\]\]|([^`0]*))" -AllMatches |
        ForEach-Object { $_.Matches } |
        ForEach-Object {
          if ($_.Groups[1].Success) {
            $_.Groups[1].Value
          } else {
            $_.Groups[2].Value
          }
        }
      $comments = $comments -join ' '
      $comments = $comments.Replace("`0", ' ') -replace '\s+', ' '
      if ($comments -notmatch $licensePattern) {
        Write-Host -ForegroundColor Red `
          "License text missing or incorrect in file `"$path`"."
        $script:exitCode = 1
      }
    }
  }

exit $exitCode
