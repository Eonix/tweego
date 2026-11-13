param(
    [ValidateSet('windows', 'linux', 'darwin')]
    [string]$TargetOS = 'windows',
    [ValidateSet('amd64', 'arm64')]
    [string]$TargetArch = 'amd64'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Install Docker Desktop and enable Linux containers first.'
}
$engineOS = & docker info --format '{{.OSType}}' 2>$null
if ($LASTEXITCODE -ne 0) { throw 'Start Docker Desktop, then rerun this command.' }
if ($engineOS -ne 'linux') { throw 'Switch Docker Desktop to Linux containers first.' }
$destination = "dist/$TargetOS-$TargetArch"
Push-Location $root
try {
    & docker buildx build --platform "$TargetOS/$TargetArch" --target artifact --output "type=local,dest=$destination" .
    if ($LASTEXITCODE -ne 0) { throw "Container build failed with exit code $LASTEXITCODE" }
    Write-Host "Build complete: $root/$destination"
} finally { Pop-Location }
