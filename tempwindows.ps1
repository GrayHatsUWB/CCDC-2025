<#
Competition script: Reset EVERY domain account password (including service accounts)
and export Username,Password to DomainUsersPasswords.csv for scoring engine.

RUN AS: Domain Admin
WARNING: This will break services running under domain accounts. Use only in competition environments.
#>

Import-Module ActiveDirectory -ErrorAction Stop

# Output CSV path
$outCsv = Join-Path (Get-Location) "DomainUsersPasswords.csv"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path (Get-Location) "PasswordReset_$timestamp.log"

# Cryptographically secure password generator
function New-RandomPassword {
    param([int]$Length = 24)  # Increased length for competition security
    
    $chars = @()
    $chars += 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
    $chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
    $chars += '0123456789'.ToCharArray()
    $chars += '!@#$%^&*()-_=+[]{}<>?'.ToCharArray()
    
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $byteBuffer = New-Object 'Byte[]' ($Length)
    $rng.GetBytes($byteBuffer)
    
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $Length; $i++) {
        $idx = $byteBuffer[$i] % $chars.Count
        [void]$sb.Append($chars[$idx])
    }
    
    # Ensure compliance with typical domain password complexity
    $pwd = $sb.ToString()
    if ($pwd -notmatch '[A-Z]') { $pwd = $pwd.Substring(0, $Length-1) + 'Z' }
    if ($pwd -notmatch '[a-z]') { $pwd = $pwd.Substring(0, $Length-1) + 'z' }
    if ($pwd -notmatch '\d')    { $pwd = $pwd.Substring(0, $Length-1) + '9' }
    if ($pwd -notmatch '[!@#\$%\^&\*\(\)\-_=+\[\]\{\}<>?]') { $pwd = $pwd.Substring(0, $Length-1) + '!' }
    
    return $pwd
}

$Results = @()
$Stats = @{
    Total = 0
    Success = 0
    Failed = 0
    FailedAccounts = @()
}

Write-Host "=== Starting Competition Password Reset ===" -ForegroundColor Cyan
Write-Host "Target: ALL domain accounts" -ForegroundColor Yellow
Write-Host "Output: $outCsv" -ForegroundColor Cyan
Write-Host "Logging: $logFile`n" -ForegroundColor Cyan

# Get ALL domain users (including service accounts, excluding nothing)
Get-ADUser -Filter * -Properties SamAccountName, Name, Enabled | ForEach-Object {
    $sam = $_.SamAccountName
    $displayName = $_.Name
    $Stats.Total++
    
    Write-Host "Processing: $displayName ($sam)" -NoNewline
    
    # Generate password
    $plain = New-RandomPassword -Length 24
    $secure = ConvertTo-SecureString $plain -AsPlainText -Force
    
    # Attempt password reset
    try {
        Set-ADAccountPassword -Identity $sam -NewPassword $secure -Reset -ErrorAction Stop
        
        # Verify the change worked by attempting to retrieve the account
        $verify = Get-ADUser -Identity $sam -ErrorAction Stop
        
        $Stats.Success++
        Write-Host " [SUCCESS]" -ForegroundColor Green
        
        $Results += [PSCustomObject]@{
            Username = $sam
            Password = $plain
            Status = "SUCCESS"
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        # Log success
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) | SUCCESS | $sam" | Out-File -FilePath $logFile -Append
    }
    catch {
        $Stats.Failed++
        $Stats.FailedAccounts += $sam
        $errorMsg = $_.Exception.Message
        
        Write-Host " [FAILED: $errorMsg]" -ForegroundColor Red
        
        $Results += [PSCustomObject]@{
            Username = $sam
            Password = "RESET_FAILED"
            Status = "FAILED: $errorMsg"
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        # Log failure
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) | FAILED | $sam | $errorMsg" | Out-File -FilePath $logFile -Append
    }
}

# Export results
$Results | Export-Csv -Path $outCsv -NoTypeInformation -Encoding UTF8

# Display summary
Write-Host "`n=== RESET COMPLETE ===" -ForegroundColor Cyan
Write-Host "Total Accounts: $($Stats.Total)" -ForegroundColor White
Write-Host "Successful: $($Stats.Success)" -ForegroundColor Green
Write-Host "Failed: $($Stats.Failed)" -ForegroundColor Red

if ($Stats.Failed -gt 0) {
    Write-Host "`nFailed Accounts:" -ForegroundColor Red
    $Stats.FailedAccounts | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

Write-Host "`nCSV exported to: $outCsv" -ForegroundColor Cyan
Write-Host "Log file: $logFile" -ForegroundColor Cyan

# Competition-specific: Display first few credentials for immediate use
Write-Host "`nFirst 5 credentials (for verification):" -ForegroundColor Yellow
$Results | Select-Object -First 5 | Format-Table Username, Password -AutoSize
