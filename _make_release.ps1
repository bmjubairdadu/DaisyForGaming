$ErrorActionPreference = 'Stop'

# 1) get the stored GitHub credential WITHOUT printing it
$proc = Start-Process -FilePath 'git' -ArgumentList 'credential','fill' -NoNewWindow `
    -RedirectStandardInput  "$env:TEMP\cred_in.txt" `
    -RedirectStandardOutput "$env:TEMP\cred_out.txt" `
    -PassThru -Wait
"protocol=https`nhost=github.com`n" | Set-Content "$env:TEMP\cred_in.txt" -NoNewline
$proc = Start-Process -FilePath 'git' -ArgumentList 'credential','fill' -NoNewWindow `
    -RedirectStandardInput  "$env:TEMP\cred_in.txt" `
    -RedirectStandardOutput "$env:TEMP\cred_out.txt" -PassThru -Wait
$cred = Get-Content "$env:TEMP\cred_out.txt"
$token = ($cred | Where-Object { $_ -like 'password=*' }) -replace '^password=',''
if (-not $token) { Write-Output 'NO_TOKEN'; exit 1 }
Write-Output "token retrieved (hidden), length=$($token.Length)"

$repo = 'bmjubairdadu/DFG-Controller'
$hdr = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json'; 'X-GitHub-Api-Version' = '2022-11-28' }

# 2) create release v1.2 (or reuse if exists)
$rel = $null
try {
    $rel = Invoke-RestMethod -Headers $hdr -Method Get -Uri "https://api.github.com/repos/$repo/releases/tags/v1.2"
    Write-Output "release v1.2 already exists (id=$($rel.id))"
} catch {
    $body = @{
        tag_name         = 'v1.2'
        target_commitish = 'main'
        name             = 'DFG-Controller v1.2 + Kernel v1.2'
        body             = 'Controller v1.2: battery-guarded App Bypass, AutoPilot kernel-cooperation, big-cluster control. Kernel v1.2: 68C thermal throttle, bypass battery/temp guards, thermal-aware boost. Modules rt/qx rebuilt CRC-exact.'
        draft            = $false
        prerelease       = $false
    } | ConvertTo-Json
    $rel = Invoke-RestMethod -Headers $hdr -Method Post -Uri "https://api.github.com/repos/$repo/releases" -Body $body -ContentType 'application/json'
    Write-Output "release v1.2 created (id=$($rel.id))"
}

# 3) upload assets
$assets = @(
    @{ path = 'D:\DaisyForGaming\DFG-Controller-v1.2.apk'; name = 'DFG-Controller-v1.2.apk' },
    @{ path = 'D:\DaisyForGaming\DaisyForGaming-v1.2-Gaming-10-13-2026.zip'; name = 'DaisyForGaming-v1.2-Gaming-10-13-2026.zip' }
)
$uploadHdr = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/octet-stream' }
$existing = @()
try { $existing = Invoke-RestMethod -Headers $hdr -Method Get -Uri "https://api.github.com/repos/$repo/releases/$($rel.id)/assets" } catch {}
foreach ($a in $assets) {
    if ($existing | Where-Object { $_.name -eq $a.name }) {
        Write-Output "asset exists, skipping: $($a.name)"
        continue
    }
    $up = "https://uploads.github.com/repos/$repo/releases/$($rel.id)/assets?name=$($a.name)"
    $r = Invoke-RestMethod -Headers $uploadHdr -Method Post -Uri $up -InFile $a.path
    Write-Output "uploaded: $($r.name) ($($r.size) bytes)"
}

# 4) cleanup temp cred files
Remove-Item "$env:TEMP\cred_in.txt","$env:TEMP\cred_out.txt" -Force -ErrorAction SilentlyContinue
Write-Output 'RELEASE_DONE'
