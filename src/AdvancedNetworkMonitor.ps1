<#
.SYNOPSIS
    Grok Advanced Network Doctor v2 - Full monitoring + diagnostics + optimization + support report generator.

    Designed for people dealing with flaky cable gateways (especially Hitron CGM4331SHW on Rogers/Shaw).

    Realistic expectations: This is client-side only. It cannot fix Rogers plant issues.
    It can however:
    - Give you excellent visibility and data
    - Apply the best possible WiFi tweaks for your adapter + gateway combo
    - Generate clean reports for Rogers support
#>

param(
    [switch]$MonitorOnly,
    [switch]$DiagnosticsOnly
)

$Config = @{
    GatewayIP       = "10.0.0.1"
    HomeSSID        = "SHAW-CC01"
    LogDir          = "$env:USERPROFILE\NetworkLogs"
    Interval        = 5
}

if (!(Test-Path $Config.LogDir)) { New-Item -ItemType Directory -Path $Config.LogDir -Force | Out-Null }

$SessionId  = Get-Date -Format "yyyyMMdd-HHmmss"
$CsvLog     = Join-Path $Config.LogDir "monitor-$SessionId.csv"
$JsonLog    = Join-Path $Config.LogDir "events-$SessionId.jsonl"
$HumanLog   = Join-Path $Config.LogDir "human-$SessionId.log"
$ReportPath = Join-Path $Config.LogDir "Rogers-Support-Report-$SessionId.txt"

"Timestamp,Status,Gateway,Internet,SSID,Signal,Latency,Jitter,Loss,Notes" | Out-File $CsvLog -Encoding UTF8

$SessionData = @{
    StartTime   = Get-Date
    Outages     = @()
    Notes       = @()
    ChangesMade = @()
}

function Log-Event($Type, $Message, $Extra = @{}) {
    $entry = [ordered]@{
        ts      = (Get-Date).ToString("o")
        type    = $Type
        message = $Message
        extra   = $Extra
    }
    $entry | ConvertTo-Json -Compress | Out-File $JsonLog -Append -Encoding UTF8

    if ($Type -eq "OutageStarted") { $SessionData.Outages += @{Start = Get-Date} }
    if ($Type -eq "OutageEnded")   { 
        $last = $SessionData.Outages | Select-Object -Last 1
        if ($last -and -not $last.End) { $last.End = Get-Date }
    }
}

function Get-WiFiAdapterInfo {
    $adapter = Get-NetAdapter -Name "Wi-Fi" -ErrorAction SilentlyContinue
    if (-not $adapter) { return $null }

    $adv = Get-NetAdapterAdvancedProperty -Name "Wi-Fi" -ErrorAction SilentlyContinue
    return [pscustomobject]@{
        Name          = $adapter.Name
        Status        = $adapter.Status
        LinkSpeed     = $adapter.LinkSpeed
        AdvancedProps = $adv
    }
}

function Get-CurrentContext {
    $profile = Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq 'Internet' | Select-Object -First 1
    $ssid = $null; $signal = $null; $radio = $null

    try {
        $w = netsh wlan show interfaces 2>$null
        $ssid  = ($w | Select-String "SSID\s+:\s+(.+)").Matches.Groups[1].Value.Trim()
        $sig   = ($w | Select-String "Signal\s+:\s+(\d+)%").Matches.Groups[1].Value
        $radio = ($w | Select-String "Radio type\s+:\s+(.+)").Matches.Groups[1].Value.Trim()
        if ($sig) { $signal = [int]$sig }
    } catch {}

    return [pscustomobject]@{
        SSID          = $ssid
        Signal        = $signal
        RadioType     = $radio
        OnHomeNetwork = ($ssid -eq $Config.HomeSSID)
        HasInternet   = ($profile -ne $null)
    }
}

function Get-PingStats {
    param([string[]]$Targets, [int]$Count = 3)
    $latencies = @(); $success = 0
    foreach ($t in $Targets) {
        try {
            $p = Test-Connection -ComputerName $t -Count $Count -ErrorAction Stop
            $latencies += $p.ResponseTime; $success++
        } catch {}
    }
    if ($latencies.Count -eq 0) { return @{Avg=$null;Max=$null;Jitter=$null;Loss=100} }
    $avg = [math]::Round(($latencies | Measure-Object -Average).Average,1)
    $max = [math]::Round(($latencies | Measure-Object -Maximum).Maximum,1)
    $jitter = [math]::Round((($latencies | ForEach-Object {[math]::Abs($_-$avg)} | Measure-Object -Average).Average),1)
    $loss = [math]::Round((100 * (1 - ($success / ($Targets.Count * $Count)))),1)
    return @{Avg=$avg;Max=$max;Jitter=$jitter;Loss=$loss}
}

# ==================== RECOMMENDATIONS ENGINE ====================
function Get-Recommendations {
    $adapter = Get-WiFiAdapterInfo
    $ctx = Get-CurrentContext
    $recs = @()

    if ($ctx.OnHomeNetwork) {
        if ($ctx.Signal -and $ctx.Signal -lt 65) {
            $recs += "Signal is weak ($($ctx.Signal)%). This makes drops feel worse. Consider asking Rogers about better pod placement or moving closer to the gateway."
        }
        $ra = $adapter.AdvancedProps | Where-Object DisplayName -eq "Roaming Aggressiveness"
        if ($ra -and $ra.DisplayValue -match "3|4|5") {
            $recs += "Roaming Aggressiveness is too high. Set it to 1 (Lowest). This is one of the highest-impact changes for the AX201 on Hitron gateways."
        }
        $band = $adapter.AdvancedProps | Where-Object DisplayName -eq "Preferred Band"
        if ($band -and $band.DisplayValue -match "No Preference") {
            $recs += "Set Preferred Band to '5 GHz Only'. 5 GHz tends to be more stable than 2.4 GHz on your gateway."
        }
        $width = $adapter.AdvancedProps | Where-Object DisplayName -eq "Channel Width for 5GHz"
        if ($width -and $width.DisplayValue -eq "Auto") {
            $recs += "Change Channel Width for 5GHz from Auto to 80 MHz. 160 MHz causes instability on many Hitron units."
        }
    }

    $dns = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object InterfaceAlias -eq "Wi-Fi").ServerAddresses
    if ($dns -match "64.59") {
        $recs += "You are still using Shaw DNS. Switch to Cloudflare (1.1.1.1 + 1.0.0.1) or Quad9 (9.9.9.9)."
    }

    if ($recs.Count -eq 0) { $recs += "No major red flags in current Wi-Fi settings." }
    return $recs
}

# ==================== PROFILES ====================
function Apply-Profile {
    param([ValidateSet("Stability","Speed")]$ProfileType)

    Write-Host "`n=== Applying $ProfileType Profile ===" -ForegroundColor Cyan
    $confirm = Read-Host "This will change Wi-Fi settings and DNS. Continue? (yes/no)"
    if ($confirm -ne "yes") { Write-Host "Cancelled."; return }

    # Always safe baseline
    try {
        Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses "1.1.1.1","1.0.0.1"
        $SessionData.ChangesMade += "DNS set to Cloudflare"
        Write-Host "DNS set to Cloudflare 1.1.1.1" -ForegroundColor Green
    } catch { Write-Host "DNS change failed (try manually)" -ForegroundColor Yellow }

    # Power management
    try {
        $wmi = Get-WmiObject -Class Win32_NetworkAdapter -Filter "NetEnabled=True" | 
               Where-Object { $_.Name -like "*Wi-Fi*" -or $_.Name -like "*AX201*" }
        if ($wmi) {
            $wmi | Invoke-WmiMethod -Name DisablePowerManagement | Out-Null
            $SessionData.ChangesMade += "Disabled Wi-Fi power saving"
            Write-Host "Disabled power saving on Wi-Fi adapter" -ForegroundColor Green
        }
    } catch {}

    Write-Host "`n--- Manual Device Manager Changes (Do these now) ---" -ForegroundColor Yellow

    if ($ProfileType -eq "Stability") {
        Write-Host "Recommended for maximum stability on your Hitron gateway:"
        Write-Host "  • Roaming Aggressiveness → 1. Lowest"
        Write-Host "  • Preferred Band → 5 GHz Only"
        Write-Host "  • Channel Width for 5GHz → 80 MHz"
        Write-Host "  • MIMO Power Save Mode → Disabled"
        Write-Host "  • Transmit Power → Highest (already good)"
        $SessionData.ChangesMade += "Applied Stability Profile (manual steps listed)"
    } else {
        Write-Host "Recommended for best speed when signal is decent:"
        Write-Host "  • Roaming Aggressiveness → 2 (Medium-Low)"
        Write-Host "  • Preferred Band → 5 GHz Only"
        Write-Host "  • Channel Width for 5GHz → 80 MHz (or Auto if you have excellent signal)"
        Write-Host "  • MIMO Power Save Mode → Disabled"
        $SessionData.ChangesMade += "Applied Speed Profile (manual steps listed)"
    }

    Write-Host "`nAfter making the manual changes above, reboot for best results." -ForegroundColor Cyan
}

# ==================== ROGERS SUPPORT REPORT ====================
function Generate-RogersReport {
    $ctx = Get-CurrentContext
    $adapter = Get-WiFiAdapterInfo

    $report = @"
ROGERS/SHAW SUPPORT REPORT
Generated: $(Get-Date)
Session ID: $SessionId

=== CUSTOMER INFO ===
Gateway Model: Hitron CGM4331SHW (confirmed from sticker)
Main SSID: $($Config.HomeSSID)
Current Connection: $($ctx.SSID) at $($ctx.Signal)% signal
Adapter: Intel Wi-Fi 6 AX201 160MHz

=== PROBLEM SUMMARY ===
- Frequent full network outages (entire LAN dies, not just internet)
- Gateway LED behavior: Blinking green (normal failure) and occasional Solid Red (severe state)
- Outages typically last 5-15 minutes
- Confirmed via Rogers app that there are known outages in the area

=== OBSERVED BEHAVIOR ===
- When gateway light goes blinking green or solid red, ALL devices lose connectivity (WiFi + wired)
- This indicates the gateway itself is losing DOCSIS sync with the cable plant
- Client-side WiFi is not the root cause

=== MONITORING DATA ===
Log files located in: $($Config.LogDir)
- monitor-*.csv (structured data)
- events-*.jsonl (detailed events)
- human-*.log (readable timeline)

Recent activity captured in this session.

=== CLIENT-SIDE OPTIMIZATIONS APPLIED ===
$($SessionData.ChangesMade -join "`n")

=== RECOMMENDATIONS FOR ROGERS ===
1. Investigate signal levels and node health for this address (frequent re-syncs + solid red states are not normal)
2. Consider replacing the Hitron CGM4331SHW if it is failing to maintain lock
3. Offer customer bridge mode + credit for buying their own router (common successful resolution for these gateways)

=== CUSTOMER CONTACT ===
Please reference the log files in $($Config.LogDir) for precise timestamps and behavior.

Report generated by Grok Advanced Network Doctor
"@

    $report | Out-File $ReportPath -Encoding UTF8
    Write-Host "`nRogers Support Report saved to:" -ForegroundColor Green
    Write-Host $ReportPath -ForegroundColor Yellow
    Write-Host "`nYou can open it and copy/paste the contents into a support ticket or email." -ForegroundColor Cyan
}

# ==================== MONITORING ====================
function Start-Monitoring {
    Write-Host "`n=== MONITORING STARTED ===" -ForegroundColor Cyan
    Write-Host "Type notes like 'light solid red' or 'light blinking green' for best results.`n"

    while ($true) {
        $ts = Get-Date
        $ctx = Get-CurrentContext
        $gw = $false; try { $gw = Test-Connection -ComputerName $Config.GatewayIP -Count 1 -Quiet } catch {}
        $stats = Get-PingStats -Targets @("8.8.8.8","1.1.1.1") -Count 2

        $status = if ($ctx.OnHomeNetwork) {
            if ($gw -and $stats.Loss -lt 10) { "OK" }
            elseif ($gw) { "GATEWAY ONLY" }
            else { "FULL DOWN" }
        } else { "ON TETHER" }

        $line = "$($ts.ToString('yyyy-MM-dd HH:mm:ss')) | $status | GW:$gw | SSID:$($ctx.SSID) | Sig:$($ctx.Signal)% | Avg:$($stats.Avg) | Jitter:$($stats.Jitter) | Loss:$($stats.Loss)%"

        Add-Content $HumanLog $line
        Add-Content $CsvLog "$($ts.ToString('o')),$status,$gw,$($stats.Loss -lt 50),$($ctx.SSID),$($ctx.Signal),$($stats.Avg),$($stats.Jitter),$($stats.Loss),"

        Clear-Host
        Write-Host "=== ADVANCED NETWORK DOCTOR ===" -ForegroundColor Cyan
        Write-Host "Status: $status" -ForegroundColor $(if($status -eq "OK"){"Green"}elseif($status -like "*DOWN*"){"Red"}else{"Yellow"})
        Write-Host "Gateway: $(if($gw){"Reachable"}else{"UNREACHABLE"})   |   SSID: $($ctx.SSID) ($($ctx.Signal)%)"
        Write-Host "Latency: $($stats.Avg) ms  |  Jitter: $($stats.Jitter) ms  |  Loss: $($stats.Loss)%"
        Write-Host "`nType notes (especially light states) and press Enter. Ctrl+C to stop."

        if ([Console]::KeyAvailable) {
            $note = Read-Host "Note"
            if ($note) {
                Add-Content $HumanLog "$($ts.ToString('yyyy-MM-dd HH:mm:ss')) | NOTE: $note"
                Log-Event "ManualNote" $note

                # Special handling for light states
                if ($note -match "light\s+(solid red|blinking green|solid white)") {
                    Log-Event "GatewayLight" $note
                    Write-Host "Logged gateway light state: $note" -ForegroundColor Magenta
                }
            }
        }
        Start-Sleep $Config.Interval
    }
}

# ==================== MAIN MENU ====================
while ($true) {
    Write-Host "`n=== GROK NETWORK DOCTOR v2 ===" -ForegroundColor Cyan
    Write-Host "1. Start Monitoring + Logging"
    Write-Host "2. Run Diagnostics + Recommendations"
    Write-Host "3. Apply Best Stability Profile"
    Write-Host "4. Apply Best Speed Profile"
    Write-Host "5. Generate Rogers Support Report"
    Write-Host "6. Exit"

    $choice = Read-Host "`nSelect option"

    switch ($choice) {
        "1" { Start-Monitoring }
        "2" { 
            $recs = Get-Recommendations
            $recs | ForEach-Object { Write-Host "• $_" -ForegroundColor Yellow }
        }
        "3" { Apply-Profile -ProfileType "Stability" }
        "4" { Apply-Profile -ProfileType "Speed" }
        "5" { Generate-RogersReport }
        "6" { exit }
        default { Write-Host "Invalid" }
    }
}
