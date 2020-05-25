New-Item -ItemType Directory '.staging' | Out-Null
Copy-Item -Recurse 'addons/*' '.staging'
Copy-Item -Recurse 'libraries/*' '.staging'