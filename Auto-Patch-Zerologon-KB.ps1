<# 
    Auto-Patch-Zerologon-KB.ps1
    - Detects OS
    - Looks up a hard-coded Zerologon KB entry for that OS
    - Downloads the .msu from Microsoft Update Catalog
    - Installs via wusa /quiet /norestart
    - Enables Netlogon enforcement mode

    You must fill in the correct KB IDs and MSU URLs for your lab.
#>

Write-Host "[*] Detecting OS..." -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
$caption = $os.Caption
$version = $os.Version
$build = [int]$os.BuildNumber
Write-Host "    Caption : $caption"
Write-Host "    Version : $version"
Write-Host "    Build   : $build"
Write-Host ""

# === HARD-CODED KB TABLE ===
# Fill in with the exact KB and direct MSU download URL from the Microsoft Update Catalog for each OS. [web:135][web:154][web:156]
$kbTable = @(
    @{
        OsMatch = "Windows Server 2016"
        KbId    = "KB5014026"   # example Zerologon-fix rollup; update as needed [web:154][web:156] #KB4571694
        Url     = "https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/secu/2022/05/windows10.0-kb5014026-x64_df6de35fd472512e628c2acc6e8d58f3e6139ac9.msu"
    }
    # Add more entries for 2012 R2, 2019, etc. as needed
    # @{
    #     OsMatch = "Windows Server 2019"
    #     KbId    = "KBxxxxxxx"
    #     Url     = "https://download.windowsupdate.com/..."
    # }
)

function Get-KBEntryForOS {
    param(
        [string]$Caption,
        [array]$Table
    )
    foreach ($entry in $Table) {
        if ($Caption -like "*$($entry.OsMatch)*") {
            return $entry
        }
    }
    return $null
}

$kbEntry = Get-KBEntryForOS -Caption $caption -Table $kbTable

if (-not $kbEntry) {
    Write-Host "[!] No KB mapping found for this OS in kbTable. Edit the script and add an entry for '$caption'." -ForegroundColor Red
    Write-Host "    Use: https://msrc.microsoft.com/update-guide/vulnerability/CVE-2020-1472 to find the right KB/MSU." -ForegroundColor Gray [web:135][web:154]
    exit 1
}

$kbId = $kbEntry.KbId
$kbUrl = $kbEntry.Url

if (-not $kbUrl -or $kbUrl -like "*<REPLACE>*") {
    Write-Host "[!] KB entry for $kbId has a placeholder URL. Replace it with the real MSU download URL from the Update Catalog." -ForegroundColor Red
    exit 1
}

Write-Host "[*] Using Zerologon KB mapping:" -ForegroundColor Cyan
Write-Host "    OS   : $caption"
Write-Host "    KB   : $kbId"
Write-Host "    URL  : $kbUrl"
Write-Host ""

# Download and install the KB
$downloadDir = "C:\ZerologonPatches"
if (-not (Test-Path $downloadDir)) {
    New-Item -Path $downloadDir -ItemType Directory | Out-Null
}

$msuPath = Join-Path $downloadDir "$kbId.msu"

if (-not (Test-Path $msuPath)) {
    Write-Host "[*] Downloading $kbId..." -ForegroundColor Cyan
    try {
        Start-BitsTransfer -Source $kbUrl -Destination $msuPath -ErrorAction Stop
        Write-Host "[*] Downloaded to $msuPath" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Download failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "[*] $kbId already present at $msuPath" -ForegroundColor Green
}

Write-Host "[*] Installing $kbId via wusa (quiet, no auto restart)..." -ForegroundColor Cyan
Start-Process -FilePath "wusa.exe" -ArgumentList "`"$msuPath`" /quiet /norestart" -Wait
Write-Host "[*] wusa completed. A reboot is required to finish applying $kbId." -ForegroundColor Yellow [web:146]

# Netlogon enforcement mode (essential for full Zerologon mitigation) [web:63][web:144][web:158]
Write-Host "`n[*] Enabling Netlogon secure channel enforcement mode..." -ForegroundColor Cyan

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
$regName = "FullSecureChannelProtection"
$regValue = 1

if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType DWord -Force | Out-Null

Write-Host "[*] Set $regName to $regValue under $regPath" -ForegroundColor Green
Write-Host "    This forces secure Netlogon connections and blocks Zerologon-style abuse." -ForegroundColor Green [web:63][web:144][web:158]

Write-Host "`n[*] Reboot the DC at a convenient time to complete the KB installation and enforcement." -ForegroundColor Yellow

Reset-ComputerMachinePassword
Reset-ComputerMachinePassword
