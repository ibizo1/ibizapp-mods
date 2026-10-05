<# 
.SYNOPSIS
    Publica a Cloudflare Pages via Git push
#>

param(
    [string]$RepoDir      = "C:\Users\ibizo\Desktop\IBIZAPP_Publish",
    [string]$ManifestPath = "C:\Users\ibizo\Desktop\IBIZAPP_Publish\manifest.json"
)

$ErrorActionPreference = "Stop"

# 1. Leer manifest local
$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
$version = [System.UInt64]$manifest.version + 1
$manifest.version = $version
$manifest.updated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

# 2. Guardar manifest local
$manifest | ConvertTo-Json -Depth 5 | Set-Content $ManifestPath -Encoding UTF8
Write-Host "Manifest v$version guardado localmente"

# 2. Git add, commit, push
Set-Location $RepoDir
git add .
git commit -m "Release v$version"
git push origin main
Write-Host "Push a GitHub completado"

# 3. Esperar deploy en Cloudflare Pages (polling)
Write-Host "Esperando deploy en Cloudflare Pages..."
$maxAttempts = 30
for ($i = 1; $i -le $maxAttempts; $i++) {
    try {
        $remote = Invoke-RestMethod "https://ibizapp-mods.pages.dev/manifest.json" -ErrorAction Stop
        if ([System.UInt64]$remote.version -ge $version) {
            Write-Host "✅ Deploy confirmado: v$($remote.version) en Pages"
            break
        }
    } catch { }
    Write-Host "  Esperando deploy... ($i/$maxAttempts)"
    Start-Sleep 10
}

Write-Host "`n✅ Listo. Manifest v$version en https://ibizapp-mods.pages.dev"