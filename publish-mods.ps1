<# 
.SYNOPSIS
    Publica "Magnus Rojo" a Cloudflare R2 y actualiza manifest.json
#>

param(
    [string]$ModsDir      = "C:\Users\ibizo\Desktop\IBIZAPP_Publish",
    [string]$ImagesDir    = "C:\Users\ibizo\Desktop\IBIZAPP_Publish",
    [string]$RemoteName   = "ibizapp-r2",
    [string]$BucketName   = "ibizapp-mods",
    [string]$PublicBaseUrl = "https://ibizapp-mods.pages.dev"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ManifestPath = Join-Path (Split-Path $PSScriptRoot -Parent) "manifest.json"

# --- Cargar manifest existente o crear nuevo ---
if (Test-Path $ManifestPath) {
    $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
    $version = [System.UInt64]$manifest.version + 1
} else {
    $manifest = @{
        version = [System.UInt64]1
        updated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        resources = @()
    }
    $version = [System.UInt64]1
}

$manifest.version = $version
$manifest.updated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

# --- Procesar EL VPK + IMAGEN DE TU MOD ---
$resources = @()

$vpkFile = Get-ChildItem "C:\Users\ibizo\Desktop\IBIZAPP_Publish\Magnus Shock of the Anvil Crimson.vpk" -File -ErrorAction SilentlyContinue
$imgFile = Get-ChildItem "C:\Users\ibizo\Desktop\IBIZAPP_Publish\magnus.jpg" -File -ErrorAction SilentlyContinue

if ($vpkFile) {
    $id = "magnus-rojo"
    $sha256 = Get-FileHash -Algorithm SHA256 -Path $vpkFile.FullName | Select-Object -ExpandProperty Hash
    $size = $vpkFile.Length
    
    $resources += @{
        id          = "magnus-rojo"
        type        = "vpk"
        file        = "mods/$($vpkFile.Name)"
        sha256      = (Get-FileHash -Algorithm SHA256 -Path $vpkFile.FullName).Hash.ToLower()
        size        = $vpkFile.Length
        name        = "Magnus Rojo"
        hero        = "npc_dota_hero_magnus"
        category    = "hero"
        image       = "images/magnus.jpg"
        description = "Set personalizado Magnus Rojo"
        version     = 1
    }

    Write-Host "  Procesado: $($vpkFile.Name) ($([math]::Round($vpkFile.Length/1MB,2)) MB) SHA256: $(Get-FileHash -Algorithm SHA256 -Path $vpkFile.FullName).Hash"
}

$manifest.resources = $resources

# --- Guardar manifest local ---
$manifest | ConvertTo-Json -Depth 5 | Set-Content "C:\Users\ibizo\Desktop\IBIZAPP_Publish\manifest.json" -Encoding UTF8
Write-Host "Manifest v$version guardado"

# --- Subir a R2 (rutas corregidas) ---
Write-Host "`n=== Subiendo a R2 ==="

# Subir VPK a mods/
rclone copy "C:\Users\ibizo\Desktop\IBIZAPP_Publish" "ibizapp-r2:ibizapp-mods/mods" --include "*.vpk" --progress --transfers 4

# Subir imagen a images/
rclone copy "C:\Users\ibizo\Desktop\IBIZAPP_Publish" "ibizapp-r2:ibizapp-mods/images" --include "magnus.jpg" --progress --transfers 4

# Subir manifest
rclone copy "C:\Users\ibizo\Desktop\IBIZAPP_Publish\manifest.json" "ibizapp-r2:ibizapp-mods/manifest.json" --progress

Write-Host "`n✅ Listo. Manifest v$version subido"
Write-Host "Recursos publicados: 1"