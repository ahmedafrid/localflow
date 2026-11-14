# LocalFlow one-line installer for Windows (PowerShell):
#   irm https://raw.githubusercontent.com/ahmedafrid/localflow/main/install.ps1 | iex
# Downloads only the app files (about 100 KB), installs uv if needed, and starts LocalFlow.
$ErrorActionPreference = "Stop"
$base = "https://raw.githubusercontent.com/ahmedafrid/localflow/main"

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Host "-> Installing uv (runs Python apps, about 30 MB)"
  Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
  $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}
$uv = (Get-Command uv).Source

$dir = Join-Path $env:APPDATA "LocalFlow\app"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
foreach ($f in "flow.py", "ui.html") {
  Invoke-WebRequest "$base/$f" -OutFile (Join-Path $dir $f) -UseBasicParsing
}
$flow = Join-Path $dir "flow.py"

# start at login (minimized, no window in the way)
$startup = [Environment]::GetFolderPath("Startup")
$link = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $startup "LocalFlow.lnk"))
$link.TargetPath = $uv
$link.Arguments = "run --quiet `"$flow`""
$link.WindowStyle = 7
$link.Save()

Write-Host "-> Starting LocalFlow (the first start downloads the speech model, this can take a few minutes)"
Start-Process -FilePath $uv -ArgumentList "run", "--quiet", "`"$flow`"", "--show" -WindowStyle Hidden
Write-Host "OK  LocalFlow installed. Hold Right Ctrl to talk. It starts automatically when you sign in."
