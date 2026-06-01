# network-doctor

An advanced, opinionated PowerShell toolkit for diagnosing and mitigating unstable cable internet connections — specifically built around the **Hitron CGM4331SHW** (common Rogers/Shaw Ignite Gateway) + Intel Wi-Fi 6 AX201 adapter combination.

> **Note**: This tool cannot fix ISP-side problems. It excels at giving you visibility, generating high-quality support reports, and applying the best possible client-side optimizations.

## Why This Exists

Many users on Rogers/Shaw (especially in Winnipeg) experience frequent full-network drops (5–15 minutes) where the gateway LED goes blinking green or solid red. The entire LAN dies — not just internet. Standard troubleshooting rarely helps because the root cause is usually on the Rogers side.

This tool was built to:
- Give you excellent visibility into what's actually happening
- Generate clean, professional reports you can send to Rogers support
- Apply the best realistic Wi-Fi adapter tweaks for this specific problematic hardware combo
- Track outage patterns over time

## Current Features

- **Advanced Monitoring**
  - High-resolution pinging with latency, jitter, and packet loss
  - Automatic detection of home network vs phone tether
  - Real-time console dashboard
  - Structured logging (CSV + JSONL + human-readable)

- **Deep Diagnostics**
  - Wi-Fi adapter analysis (especially Intel AX201 settings)
  - Smart recommendation engine

- **Optimization Profiles**
  - **Best Stability Profile** — Conservative settings for maximum uptime
  - **Best Speed Profile** — More aggressive settings when signal is good

- **Support Report Generator**
  - One-click generation of a professional report for Rogers/Shaw support, including your observed gateway LED behavior

- **Manual Observation Logging**
  - Easily log gateway light states (`light solid red`, `light blinking green`, etc.) during outages


## Installation (Recommended)

The easiest and most reliable way:

```cmd
git clone https://github.com/iiZerve/network-doctor.git
cd network-doctor

install.cmd
```

This uses a `.cmd` wrapper that bypasses PowerShell execution policy restrictions (very common when running elevated or in locked-down environments).

After the installer finishes:
- Restart your terminal
- Type `network-doctor` to launch

### Alternative (if .cmd doesn't work)

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### Recommended Method (Simplest)

```powershell
git clone https://github.com/iiZerve/network-doctor.git
cd network-doctor

powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The installer will:
- Copy the tool to `C:\Users\YourName\Tools`
- Create a `network-doctor` command
- Optionally add the folder to your PATH

After installation (and restarting your terminal), you can simply type:

```powershell
network-doctor
```

### Alternative: Run directly from the folder

```powershell
cd network-doctor
.\network-doctor.cmd
```

Or:

```powershell
powershell -ExecutionPolicy Bypass -File .\src\AdvancedNetworkMonitor.ps1
```

### Option 1: Using the installer (Recommended)

```powershell
git clone https://github.com/iiZerve/network-doctor.git
cd network-doctor

# Run the installer
powershell -ExecutionPolicy Bypass -File .\install.ps1 -CreateAlias
```

After installation you can simply type `network-doctor` in PowerShell.

### Option 2: Manual

```powershell
git clone https://github.com/iiZerve/network-doctor.git
cd network-doctor

powershell -ExecutionPolicy Bypass -File ".\src\AdvancedNetworkMonitor.ps1"
```
### Requirements
- Windows 10/11
- PowerShell 5.1 or PowerShell 7+
- Administrator rights (recommended for some optimizations)

### Quick Start

```powershell
# Clone the repo
git clone https://github.com/YOUR_USERNAME/network-doctor.git
cd network-doctor

# Run the tool
powershell -ExecutionPolicy Bypass -File ".\src\AdvancedNetworkMonitor.ps1"
```

## Usage

The tool has an interactive menu with these main options:

1. **Start Monitoring + Logging**
2. **Run Diagnostics + Recommendations**
3. **Apply Best Stability Profile**
4. **Apply Best Speed Profile**
5. **Generate Rogers Support Report**
6. Exit

## Planned / Future Features

- Better outage visualization and graphs
- Automatic detection of common Rogers gateway LED states
- Integration with router APIs (when bridge mode is used)
- Exportable "before vs after" performance reports
- Scheduled/background monitoring mode
- More adapter-specific tuning for Intel AX series cards

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

This project started as a personal troubleshooting tool. Contributions, ideas, and improvements (especially around Rogers/Shaw gateway behavior) are very welcome.

## License

MIT License

## Disclaimer

This is a client-side diagnostic and optimization tool only. It does not modify your ISP equipment. All responsibility for changes made via the optimization features lies with the user.



## Roadmap

See [ROADMAP.md](ROADMAP.md) for current status and future plans.









## Using as a PowerShell Module (Advanced)

If you install via the module option, you can do:

```powershell
Import-Module NetworkDoctor

# Launch the full tool
Start-NetworkDoctor

# Update the tool from GitHub
Update-NetworkDoctor

# Run diagnostics programmatically
Get-NetworkDiagnostics
```




## Quick Start (Simplest Way)

After cloning:

```powershell
cd network-doctor

# Recommended on most systems (works even with restricted execution policy)
.\NetworkDoctor.cmd
```

Or after installing via the installer, just type:

```powershell
network-doctor
```

The `.cmd` launcher is the most reliable way when PowerShell execution policies are restrictive (very common in corporate or elevated sessions).

### Important: Execution Policy Issues

If you see "running scripts is disabled on this system" when trying to run `.ps1` files, use the provided `.cmd` launcher instead:

```cmd
.\NetworkDoctor.cmd
```

This bypasses the PowerShell execution policy restriction.


