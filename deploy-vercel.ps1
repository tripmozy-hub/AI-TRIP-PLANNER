# Tripmozy India - Direct Vercel Deployment Script
param (
    [Parameter(Mandatory=$false)]
    [string]$VercelToken = ""
)

if (-not $VercelToken) {
    $VercelToken = Read-Host "Paste your Vercel Token"
}

if (-not $VercelToken) {
    Write-Host "No token entered. Exiting." -ForegroundColor Yellow
    exit
}

Write-Host "Deploying Tripmozy to Vercel..." -ForegroundColor Cyan

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$files = @("index.html", "app.js", "styles.css", "logo.png", "tripmozy_catalog.js", "tripmozy_hotels.json", "widget.js", "vercel.json")

$sha1 = [System.Security.Cryptography.SHA1]::Create()
function Get-FileSha1($bytes) {
    $hash = $sha1.ComputeHash($bytes)
    return [BitConverter]::ToString($hash).Replace("-", "").ToLower()
}

$deploymentFiles = @()

foreach ($file in $files) {
    $filePath = Join-Path $dir $file
    if (-not (Test-Path $filePath)) { continue }

    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $digest = Get-FileSha1 $bytes
    $size = $bytes.Length

    Write-Host "Uploading $file ($size bytes)..." -NoNewline

    $uploadHeaders = @{
        "Authorization" = "Bearer $VercelToken"
        "Content-Type" = "application/octet-stream"
        "x-vercel-digest" = $digest
    }

    try {
        $null = Invoke-RestMethod -Uri "https://api.vercel.com/v2/files" -Method Post -Headers $uploadHeaders -Body $bytes
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " (cached)" -ForegroundColor DarkGray
    }

    $deploymentFiles += @{
        file = $file
        sha = $digest
        size = $size
    }
}

$deployBody = @{
    name = "tripmozy-india-trip-planner"
    files = $deploymentFiles
    projectSettings = @{ framework = $null }
} | ConvertTo-Json -Depth 5

$deployHeaders = @{
    "Authorization" = "Bearer $VercelToken"
    "Content-Type" = "application/json"
}

try {
    $deployResponse = Invoke-RestMethod -Uri "https://api.vercel.com/v13/deployments" -Method Post -Headers $deployHeaders -Body $deployBody
    Write-Host "`n SUCCESS! Deployed to Vercel!" -ForegroundColor Green
    Write-Host "Live URL: https://$($deployResponse.url)" -ForegroundColor Yellow
    Write-Host "Alias URL: https://tripmozy-india-trip-planner.vercel.app" -ForegroundColor Cyan
} catch {
    Write-Host "`nDeploy Error: $($_.Exception.Message)" -ForegroundColor Red
}

