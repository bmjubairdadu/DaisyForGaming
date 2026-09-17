<#
  DaisyForGaming - AnyKernel3 pack script
  Developer : JUBAIR HOSEN
  Usage     : .\pack_anykernel.ps1 [-KernelImage <path>] [-Version <name>]
  Example   : .\pack_anykernel.ps1 -KernelImage "D:\DaisyForGaming\out\arch\arm64\boot\Image.gz-dtb"
#>
param(
  [string]$KernelImage = "D:\DaisyForGaming\out\arch\arm64\boot\Image.gz-dtb",
  [string]$Version = "v1.0"
)

$ErrorActionPreference = "Stop"
$AkDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Base   = "https://raw.githubusercontent.com/osm0sis/AnyKernel3/master"

function Get-AkFile($relPath, $destPath) {
  $url = "$Base/$relPath"
  Write-Host "Downloading $relPath ..."
  Invoke-WebRequest -Uri $url -OutFile $destPath
}

# 1. AnyKernel3 core files (official, always fresh)
$ub = Join-Path $AkDir "META-INF\com\google\android\update-binary"
if (-not (Test-Path $ub)) { Get-AkFile "META-INF/com/google/android/update-binary" $ub }
$ak3 = Join-Path $AkDir "tools\ak3-core.sh"
if (-not (Test-Path $ak3)) { Get-AkFile "tools/ak3-core.sh" $ak3 }
$bb = Join-Path $AkDir "tools\busybox"
if (-not (Test-Path $bb)) { Get-AkFile "tools/busybox" $bb }

# 2. Built kernel image
if (-not (Test-Path -LiteralPath $KernelImage)) {
  throw "Kernel image not found: $KernelImage (build the kernel first!)"
}
$dest_img = Join-Path $AkDir "Image.gz-dtb"
if ((Resolve-Path -LiteralPath $KernelImage).Path -ne (Resolve-Path -LiteralPath $dest_img -ErrorAction SilentlyContinue).Path) {
  Copy-Item -LiteralPath $KernelImage -Destination $dest_img -Force
}
Write-Host "Kernel image added: $KernelImage"

# 3. Pack the flashable zip
$zipName = "DaisyForGaming-$Version-JUBAIR-HOSEN.zip"
$zipPath = Join-Path $AkDir $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
$items = @("META-INF", "tools", "patch", "ramdisk", "anykernel.sh", "banner", "Image.gz-dtb") |
  ForEach-Object { Join-Path $AkDir $_ } | Where-Object { Test-Path $_ }
Compress-Archive -Path $items -DestinationPath $zipPath
Write-Host ""
Write-Host "Done! Flashable zip: $zipPath"
Write-Host "Flash it from TWRP / OrangeFox recovery."
