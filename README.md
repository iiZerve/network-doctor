# grok-network-doctor

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

## Getting Started

### Requirements
- Windows 10/11
- PowerShell 5.1 or PowerShell 7+
- Administrator rights (recommended for some optimizations)

### Quick Start

```powershell
# Clone the repo
git clone https://github.com/YOUR_USERNAME/grok-network-doctor.git
cd grok-network-doctor

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

This project started as a personal troubleshooting tool. Contributions, ideas, and improvements (especially around Rogers/Shaw gateway behavior) are very welcome.

## License

MIT License

## Disclaimer

This is a client-side diagnostic and optimization tool only. It does not modify your ISP equipment. All responsibility for changes made via the optimization features lies with the user.
