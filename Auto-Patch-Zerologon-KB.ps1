<# 
    Auto-Patch-Zerologon-KB.ps1
    - Detects OS
    - For that OS, looks up a list of KB packages (each with KB ID + MSU URL)
    - Downloads each .msu if missing
    - Installs each with wusa /quiet /norestart
    - Enables Netlogon enforcement mode

    You maintain the KB table below.
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

# === HARD-CODED KB TABLE (MULTIPLE PACKAGES PER OS) ===
# Each OS entry has an array of KB packages.
# Fill in real MSU URLs from the Microsoft Update Catalog.
$kbTable = @(
    @{
        OsMatch  = "Windows Server 2016"
        Packages = @(
            @{
                KbId = "KB5014026"   # example Zerologon-fix rollup; update as needed
                Url  = "https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/secu/2022/05/windows10.0-kb5014026-x64_df6de35fd472512e628c2acc6e8d58f3e6139ac9.msu"
            },
            @{
                KbId = "KB5013952"  # example Zerologon-fix LCU; pick your preferred LCU
                Url  = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/secu/2022/05/windows10.0-kb5013952-x64_c9c29b4a81897db5545e284f04490c0659dc8b06.msu"
            }
        )
    }
    # Add more OS entries as needed, each with its own Packages list
    # @{
    #   OsMatch = "Windows Server 2019"
    #   Packages = @(
    #       @{ KbId = "KBxxxxxxx"; Url = "https://download.windowsupdate.com/..." },
    #       @{ KbId = "KByyyyyyy"; Url = "https://download.windowsupdate.com/..." }
    #   )
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
    Write-Host "    Use: https://msrc.microsoft.com/update-guide/vulnerability/CVE-2020-1472 to pick KBs." -ForegroundColor Gray
    exit 1
}

$packages = $kbEntry.Packages
if (-not $packages -or $packages.Count -eq 0) {
    Write-Host "[!] OS entry found, but no packages defined. Add at least one KB to the Packages array." -ForegroundColor Red
    exit 1
}

Write-Host "[*] Will process the following Zerologon-related KB packages for this OS:" -ForegroundColor Cyan
foreach ($pkg in $packages) {
    Write-Host "    $($pkg.KbId) -> $($pkg.Url)"
}
Write-Host ""

$downloadDir = "C:\ZerologonPatches"
if (-not (Test-Path $downloadDir)) {
    New-Item -Path $downloadDir -ItemType Directory | Out-Null
}

foreach ($pkg in $packages) {
    $kbId = $pkg.KbId
    $kbUrl = $pkg.Url

    if (-not $kbUrl -or $kbUrl -like "*<REPLACE>*") {
        Write-Host "[!] Package $kbId has a placeholder URL. Replace it with the real MSU URL before running." -ForegroundColor Red
        continue
    }

    $msuPath = Join-Path $downloadDir "$kbId.msu"

    if (-not (Test-Path $msuPath)) {
        Write-Host "[*] Downloading $kbId..." -ForegroundColor Cyan
        Write-Host "    URL: $kbUrl" -ForegroundColor Gray
        try {
            Start-BitsTransfer -Source $kbUrl -Destination $msuPath -ErrorAction Stop
            Write-Host "[*] Downloaded to $msuPath" -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Download failed for $kbId $($_.Exception.Message)" -ForegroundColor Red
            continue
        }
    }
    else {
        Write-Host "[*] $kbId already present at $msuPath" -ForegroundColor Green
    }

    Write-Host "[*] Installing $kbId via wusa (quiet, no auto restart)..." -ForegroundColor Cyan
    Start-Process -FilePath "wusa.exe" -ArgumentList "`"$msuPath`" /quiet /norestart" -Wait
    Write-Host "[*] wusa completed for $kbId. A reboot may be required to finalize this update." -ForegroundColor Yellow
}

# Netlogon enforcement mode (needed for full mitigation)
Write-Host "`n[*] Enabling Netlogon secure channel enforcement mode..." -ForegroundColor Cyan

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
$regName = "FullSecureChannelProtection"
$regValue = 1

if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType DWord -Force | Out-Null

Write-Host "[*] Set $regName to $regValue under $regPath" -ForegroundColor Green
Write-Host "    This forces secure Netlogon connections and blocks Zerologon-style abuse." -ForegroundColor Green

Write-Host "`n[*] Reboot the DC at a convenient time to complete the KB installations and enforcement." -ForegroundColor Yellow

Write-Host "[*] Resetting Kerberos password (first pass)..." -ForegroundColor Cyan
# Reset KRBTGT once
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (ConvertTo-SecureString -String (path-to-random-string) -AsPlainText -Force)
Write-Host "[*] KRBTGT reset once." -ForegroundColor Yellow

# Wait for replication (in a single DC lab, you can proceed immediately, otherwise wait 15-20 mins)
Start-Sleep -Seconds 5

Write-Host "[*] Resetting Kerberos password (second pass)..." -ForegroundColor Cyan
# Reset KRBTGT a second time to clear history
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (ConvertTo-SecureString -String (path-to-random-string) -AsPlainText -Force)
Write-Host "[*] KRBTGT reset twice. All golden tickets are now invalid." -ForegroundColor Yellow

Write-Host "[*] Resetting machine password..." -ForegroundColor Cyan
Reset-ComputerMachinePassword
Write-Host "[*] Machine password reset." -ForegroundColor Yellow
