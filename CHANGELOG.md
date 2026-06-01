# Changelog

All notable changes to Network Doctor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-06-01

### Added
- Proper PowerShell module structure (`NetworkDoctor.psd1` + `NetworkDoctor.psm1`)
- `Update-NetworkDoctor` function for self-updating from GitHub
- Improved interactive menu with better help and navigation
- `CHANGELOG.md`
- Root `NetworkDoctor.ps1` launcher for easy running from the repo
- `bin/` folder with portable `.cmd` / `.bat` shims
- Significantly improved `install.ps1` (simpler PATH handling + better execution policy support)

### Changed
- Major usability improvements to installation experience
- Better documentation and project structure

## [0.2.0] - 2026-05-31

### Added
- Advanced real-time network monitoring with latency/jitter/loss tracking
- Automatic home vs tether detection
- Deep diagnostics for Intel AX201 + Hitron CGM4331SHW
- Stability and Speed optimization profiles
- One-click Rogers Support Report generator
- Manual gateway light state logging
- `install.ps1` with alias support
- Structured logging (CSV + JSONL)

## [0.1.0] - 2026-05-31

Initial release.

## [0.4.0] - 2026-06-01

### Improved Monitoring Accuracy
- Packet loss is now measured with **~250 rapid pings per 30-second sample** (much higher statistical confidence)
- Replaced simple loss bars with proper vertical time-series graph
- Added detailed legend inside the tool (option 7)
- Live dashboard now shows exact ping count used per sample

