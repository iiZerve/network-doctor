# Network Doctor

Advanced local network diagnostics — available as both a **Windows PowerShell desktop tool** and an **Android mobile app** (Capacitor).

> **Note**: This tool cannot fix ISP-side problems (e.g. Rogers/Shaw plant issues). It excels at giving you visibility, generating high-quality support reports, and applying the best possible client-side optimizations.

## Android App (Google Play - v1.0.0)

**Network Doctor** is also available as a native Android app for on-the-go diagnostics and intelligent background monitoring.

### Key Features (Android)
- Real packet loss tracking via actual TCP probes (Light/Balanced/Aggressive modes + smart event-driven boost)
- Live metrics + high-resolution illustrative Performance Over Time charts (Download/Upload/Latency trends)
- Full diagnostic toolkit: Ping (real timing), Cloudflare DoH NSLookup, Local/Public IP, Port checks, detailed loss history
- 100% local processing — no accounts, no analytics, no PII sent to developer
- Foreground service for reliable background monitoring with user-visible notification

**Privacy First**: All diagnostics run locally. Probes only to public infrastructure (Google DNS, Cloudflare, etc.). UI libraries loaded from CDNs (documented in PRIVACY_POLICY.md).

See [BUILD_AND_RELEASE.md](BUILD_AND_RELEASE.md) for build instructions, Play Store assets, and submission checklist.

**Important for Charts**: The "Performance Over Time" section uses simulated illustrative data for dense visual trends. Real packet loss, latency samples, and tool results are 100% real and shown in the LOSS metric + Diagnostic Tools panel.

## Windows PowerShell Tool

The original advanced toolkit for deep Wi-Fi diagnostics, especially for **Hitron CGM4331SHW** (Rogers/Shaw Ignite) + Intel AX201.

See full details below and in ROADMAP.md / CHANGELOG.md.

## Quick Start - Android (from source)

```bash
git clone https://github.com/iiZerve/network-doctor.git
cd network-doctor
npm install
npm run build:android:debug   # or open:android for Studio
```

APK will be in `android/app/build/outputs/apk/debug/`.

For release .aab: See BUILD_AND_RELEASE.md (requires keystore setup).

## Installation (PowerShell Desktop Tool - Recommended)

```cmd
git clone https://github.com/iiZerve/network-doctor.git
cd network-doctor

install.cmd
```

Then type `network-doctor` in a new terminal.

Full PowerShell documentation, features, and usage in the sections below (original README content preserved for the desktop tool).

---

## Why This Exists (Desktop)

Many users on Rogers/Shaw (especially in Winnipeg) experience frequent full-network drops (5–15 minutes) where the gateway LED goes blinking green or solid red. The entire LAN dies — not just internet. Standard troubleshooting rarely helps because the root cause is usually on the Rogers side.

This tool was built to:
- Give you excellent visibility into what's actually happening
- Generate clean, professional reports you can send to Rogers support
- Apply the best realistic Wi-Fi adapter tweaks for this specific problematic hardware combo
- Track outage patterns over time

## Current Features (Desktop)

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
  - Easily log gateway light states during outages

## Usage (Desktop)

The tool has an interactive menu with these main options:

1. **Start Monitoring + Logging**
2. **Run Diagnostics + Recommendations**
3. **Apply Best Stability Profile**
4. **Apply Best Speed Profile**
5. **Generate Rogers Support Report**
6. Exit

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License

## Disclaimer

This is a client-side diagnostic and optimization tool only. It does not modify your ISP equipment. All responsibility for changes made via the optimization features lies with the user.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for current status and future plans (includes both desktop and Android tracks).

## Using as a PowerShell Module (Advanced)

```powershell
Import-Module NetworkDoctor
Start-NetworkDoctor
```

## Quick Start (Desktop)

**Most reliable way (recommended):**

```cmd
git clone https://github.com/iiZerve/network-doctor.git
cd network-doctor

NetworkDoctor.cmd
```

This works even in elevated PowerShell or environments with strict execution policies.

After installation, you can also just type `network-doctor` from anywhere.

### Important: Execution Policy Issues

If you see "running scripts is disabled on this system" when trying to run `.ps1` files, use the provided `.cmd` launcher instead:

```cmd
.\NetworkDoctor.cmd
```

This bypasses the PowerShell execution policy restriction.
