# Tripmozy India - Direct Vercel Deployment Script
param (
    [Parameter(Mandatory=$false)]
    [string]$VercelToken = ""
)

if (-not $VercelToken) {
    $VercelToken = Read-Host "Paste your Vercel Token (from https://vercel.com/account/tokens)"
}

if (-not $VercelToken) {
    Write-Host "No token entered. Exiting." -ForegroundColor Yellow
    exit
}

Write-Host "Deploying Tripmozy Smart Tour Booking Marketplace to Vercel..." -ForegroundColor Cyan

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Get all files excluding .git, node_modules, and zip archives
$allFiles = Get-ChildItem -Path $dir -Recurse -File | Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\node_modules\\' -and
    $_.FullName -notmatch '\\\.vercel\\' -and
    $_.FullName -notmatch '\.zip$' -and
    $_.FullName -notmatch '\.log$'
}

$sha1 = [System.Security.Cryptography.SHA1]::Create()
function Get-FileSha1($bytes) {
    $hash = $sha1.ComputeHash($bytes)
    return [BitConverter]::ToString($hash).Replace("-", "").ToLower()
}

$deploymentFiles = @()

foreach ($item in $allFiles) {
    $relativePath = $item.FullName.Substring($dir.Length + 1).Replace("\", "/")
    $bytes = [System.IO.File]::ReadAllBytes($item.FullName)
    $digest = Get-FileSha1 $bytes
    $size = $bytes.Length

    Write-Host "Uploading $relativePath ($size bytes)..." -NoNewline

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
        file = $relativePath
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
    Write-Host "Production URL: https://tripmozy-india-trip-planner.vercel.app" -ForegroundColor Cyan
} catch {
    Write-Host "`nDeploy Error: $($_.Exception.Message)" -ForegroundColor Red
}
