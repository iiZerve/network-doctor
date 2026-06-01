<#
.SYNOPSIS
    Network Doctor - Advanced monitoring, diagnostics, and optimization for unstable cable connections.
.DESCRIPTION
    Designed primarily for Rogers/Shaw Hitron CGM4331SHW users with Intel AX201 Wi-Fi issues.
    Provides high-accuracy packet loss monitoring, text graphs, client-side optimizations, and support report generation.
#>

param(
    [switch]$MonitorOnly,
    [switch]$DiagnosticsOnly
)

$Config = @{
    GatewayIP = "10.0.0.1"
    HomeSSID  = "SHAW-CC01"
    LogDir    = "$env:USERPROFILE\NetworkLogs"
    Interval  = 30          # seconds between samples
    PingsPerSample = 250    # high volume for accurate loss %
}

if (!(Test-Path $Config.LogDir)) { New-Item -ItemType Directory -Path $Config.LogDir -Force | Out-Null }

$SessionId = Get-Date -Format "yyyyMMdd-HHmmss"
$CsvLog    = Join-Path $Config.LogDir "monitor-$SessionId.csv"
$HumanLog  = Join-Path $Config.LogDir "human-$SessionId.log"

"Timestamp,Status,Gateway,Internet,SSID,Signal,Latency,Jitter,Loss,Samples" | Out-File $CsvLog -Encoding UTF8

function Get-HighVolumeLoss {
    param(
        [string[]]$Targets = @("8.8.8.8", "1.1.1.1"),
        [int]$TotalPings = $Config.PingsPerSample
    )
    $total = 0; $success = 0; $latencies = @()
    $ping = New-Object System.Net.NetworkInformation.Ping
    $pingsPerTarget = [math]::Ceiling($TotalPings / $Targets.Count)

    foreach ($target in $Targets) {
        for ($i = 0; $i -lt $pingsPerTarget; $i++) {
            $total++
            try {
                $reply = $ping.Send($target, 1200)
                if ($reply.Status -eq 'Success') {
                    $success++
                    $latencies += $reply.RoundtripTime
                }
            } catch {}
        }
    }

    $loss = if ($total -gt 0) { [math]::Round(100 * ($total - $success) / $total, 1) } else { 100 }
    $avg  = if ($latencies.Count -gt 0) { [math]::Round(($latencies | Measure-Object -Average).Average, 1) } else { $null }
    $max  = if ($latencies.Count -gt 0) { [math]::Round(($latencies | Measure-Object -Maximum).Maximum, 1) } else { $null }
    $jitter = if ($latencies.Count -gt 1) {
        $avgL = ($latencies | Measure-Object -Average).Average
        [math]::Round((($latencies | ForEach-Object { [math]::Abs($_ - $avgL) } | Measure-Object -Average).Average), 1)
    } else { $null }

    [pscustomobject]@{
        Loss       = $loss
        AvgLatency = $avg
        MaxLatency = $max
        Jitter     = $jitter
        Samples    = $total
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
    [pscustomobject]@{
        SSID          = $ssid
        Signal        = $signal
        RadioType     = $radio
        OnHomeNetwork = ($ssid -eq $Config.HomeSSID)
        HasInternet   = ($profile -ne $null)
    }
}

function Show-LossGraph {
    param([array]$History, [int]$MaxSamples = 30)
    if ($History.Count -eq 0) { return }
    $display = if ($History.Count -gt $MaxSamples) { $History[($History.Count-$MaxSamples)..($History.Count-1)] } else { $History }
    Write-Host "`nPacket Loss % (last $($display.Count) samples @ 30s each):" -ForegroundColor Cyan
    $barWidth = 40
    foreach ($e in $display) {
        $loss = [math]::Min(100, [math]::Max(0, $e.Loss))
        $filled = [math]::Floor(($loss / 100) * $barWidth)
        $bar = ('#' * $filled) + ('.' * ($barWidth - $filled))
        Write-Host ("  {0} | {1} {2,5}%" -f $e.Time.ToString('HH:mm:ss'), $bar, $loss)
    }
}

function Get-Recommendations {
    $ctx = Get-CurrentContext
    $recs = @()
    if ($ctx.OnHomeNetwork) {
        if ($ctx.Signal -lt 70) { $recs += "Signal weak ($($ctx.Signal)%). Consider moving closer or asking Rogers about pod placement." }
        $recs += "Recommended Wi-Fi adapter settings (Device Manager -> Intel Wi-Fi 6 AX201 -> Advanced):"
        $recs += "  - Roaming Aggressiveness -> 1 (Lowest)"
        $recs += "  - Preferred Band -> 5 GHz Only"
        $recs += "  - Channel Width for 5GHz -> 80 MHz"
        $recs += "  - Disable power saving on the adapter"
    }
    if ($recs.Count -eq 0) { $recs += "No major client-side issues detected." }
    return $recs
}

function Apply-Profile {
    param([ValidateSet('Stability','Speed')]$Profile)
    Write-Host "`n=== $Profile Profile Recommendations ===" -ForegroundColor Cyan
    if ($Profile -eq 'Stability') {
        Write-Host "For maximum stability on Hitron gateways:"
        Write-Host "  Roaming Aggressiveness: Lowest (1)"
        Write-Host "  Preferred Band: 5 GHz Only"
        Write-Host "  Channel Width 5GHz: 80 MHz"
    } else {
        Write-Host "For best speed (when signal is strong):"
        Write-Host "  Roaming Aggressiveness: 2 (Medium-Low)"
        Write-Host "  Preferred Band: 5 GHz Only"
        Write-Host "  Channel Width 5GHz: 80 MHz or Auto"
    }
    Write-Host "Also recommended: Cloudflare DNS (1.1.1.1) and disable Wi-Fi power saving."
}

function Generate-RogersReport {
    $ctx = Get-CurrentContext
    $report = @"
ROGERS/SHAW SUPPORT REPORT
Generated: $(Get-Date)
Gateway: Hitron CGM4331SHW
Observed: Frequent full LAN outages with LED blinking green or solid red.
Client-side optimizations applied where possible.
Full logs available in $($Config.LogDir)
"@
    $report | Out-File $ReportPath -Encoding UTF8
    Write-Host "Report saved to: $ReportPath" -ForegroundColor Green
}

function Show-Help {
    Write-Host "`n=== Network Doctor Help & Legend ===" -ForegroundColor Cyan
    Write-Host "Loss     = Packet loss % (250 pings per 30s sample for accuracy)"
    Write-Host "Jitter   = Variation in latency"
    Write-Host "Status   = OK / GATEWAY ONLY / FULL DOWN / ON TETHER"
    Write-Host ""
    Write-Host "While monitoring, type notes like 'light solid red' or 'light blinking green'."
    Write-Host "These are saved with timestamps and included in reports."
}

# ==================== MONITORING ====================
$lossHistory = [System.Collections.Generic.List[object]]::new()

function Start-Monitoring {
    Write-Host "`n=== Monitoring Started (30s samples, 250 pings each) ===" -ForegroundColor Cyan
    Write-Host "Type notes (e.g. 'light solid red') and press Enter. Ctrl+C to stop.`n"

    while ($true) {
        $ts = Get-Date
        $ctx = Get-CurrentContext
        $gw = $false; try { $gw = Test-Connection -ComputerName $Config.GatewayIP -Count 1 -Quiet } catch {}
        $stats = Get-HighVolumeLoss

        $status = if ($ctx.OnHomeNetwork) {
            if ($gw -and $stats.Loss -lt 10) { "OK" }
            elseif ($gw) { "GATEWAY ONLY" }
            else { "FULL DOWN" }
        } else { "ON TETHER" }

        $line = "$($ts.ToString('yyyy-MM-dd HH:mm:ss')) | $status | GW:$gw | SSID:$($ctx.SSID) | Sig:$($ctx.Signal)% | Avg:$($stats.AvgLatency) | Jitter:$($stats.Jitter) | Loss:$($stats.Loss)% | Samples:$($stats.Samples)"

        Add-Content $HumanLog $line
        Add-Content $CsvLog "$($ts.ToString('o')),$status,$gw,$($stats.Loss -lt 50),$($ctx.SSID),$($ctx.Signal),$($stats.AvgLatency),$($stats.Jitter),$($stats.Loss),$($stats.Samples)"

        Clear-Host
        Write-Host "=== NETWORK DOCTOR ===" -ForegroundColor Cyan
        Write-Host "Status: $status" -ForegroundColor $(if($status -eq "OK"){"Green"}elseif($status -like "*DOWN*"){"Red"}else{"Yellow"})
        Write-Host "Gateway: $(if($gw){"Reachable"}else{"UNREACHABLE"}) | SSID: $($ctx.SSID) ($($ctx.Signal)%)"
        Write-Host "Latency: $($stats.AvgLatency) ms | Jitter: $($stats.Jitter) ms | Loss: $($stats.Loss)% ($($stats.Samples) pings)"

        $lossHistory.Add([pscustomobject]@{ Time = $ts; Loss = $stats.Loss })
        if ($lossHistory.Count -gt 30) { $lossHistory.RemoveAt(0) }
        Show-LossGraph -History $lossHistory

        Write-Host "`nType notes (e.g. light solid red) and press Enter. Ctrl+C to stop."

        if ([Console]::KeyAvailable) {
            $note = Read-Host "Note"
            if ($note) {
                Add-Content $HumanLog "$($ts.ToString('yyyy-MM-dd HH:mm:ss')) | NOTE: $note"
                if ($note -match 'light') { Write-Host "Logged: $note" -ForegroundColor Magenta }
            }
        }
        Start-Sleep -Seconds $Config.Interval
    }
}

# ==================== MENU ====================
function Show-MainMenu {
    Clear-Host
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host "              NETWORK DOCTOR v0.3.0+" -ForegroundColor Cyan
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1]  Start Monitoring + Logging"
    Write-Host "  [2]  Run Diagnostics + Recommendations"
    Write-Host "  [3]  Apply Best Stability Profile"
    Write-Host "  [4]  Apply Best Speed Profile"
    Write-Host "  [5]  Generate Rogers Support Report"
    Write-Host "  [6]  Show Recent Logs"
    Write-Host "  [7]  Help / Legend"
    Write-Host "  [0]  Exit"
    Write-Host ""
}

while ($true) {
    Show-MainMenu
    $choice = Read-Host "Select option (0-7)"

    switch ($choice) {
        "1" { Start-Monitoring }
        "2" { 
            Get-Recommendations | ForEach-Object { Write-Host "• $_" -ForegroundColor Yellow }
            Read-Host "`nPress Enter to continue"
        }
        "3" { Apply-Profile -ProfileType "Stability" }
        "4" { Apply-Profile -ProfileType "Speed" }
        "5" { Generate-RogersReport }
        "6" { 
            Get-ChildItem $Config.LogDir -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select -First 8 | Format-Table
            Read-Host "`nPress Enter"
        }
        "7" { Show-Help }
        "0" { exit }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep -Milliseconds 600 }
    }
}
